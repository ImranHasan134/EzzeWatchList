// lib/utils/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/database/db_helper.dart';
import '../data/models/watch_item.dart';

class BackupService {
  final DbHelper _db = DbHelper();

  // ── Export — saves PDF + JSON (with embedded images) ─────────────────────

  Future<void> exportData(BuildContext context) async {
    try {
      final items = await _db.getAllItems();
      if (items.isEmpty) {
        _showSnack(context, '⚠️ No data to export.', isError: true);
        return;
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);

      // ── Build JSON with embedded Base64 images ────────────────────────────
      final itemsJson = await Future.wait(items.map((item) async {
        final map = item.toMap();
        if (item.posterPath != null && item.posterPath!.isNotEmpty) {
          final file = File(item.posterPath!);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            map['posterBase64'] = base64Encode(bytes);
            map['posterExtension'] = p.extension(item.posterPath!);
          }
        }
        return map;
      }));

      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'count': items.length,
        'items': itemsJson,
      });

      final jsonFile = File(
          '/storage/emulated/0/Download/EzzeWatchList_$timestamp.json');
      await jsonFile.writeAsString(jsonString);

      // ── Build PDF ─────────────────────────────────────────────────────────
      final pdf = pw.Document();
      final watched  = items.where((i) => i.status == WatchStatus.watched).toList();
      final watching = items.where((i) => i.status == WatchStatus.watching).toList();
      final planned  = items.where((i) => i.status == WatchStatus.planned).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'EzzeWatchList : My Watchlist',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Exported on: ${_formatDate(DateTime.now())}   |   Total: ${items.length} items',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          ),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfStatBox('Watched',  '${watched.length}',  PdfColors.green700),
                  _pdfStatBox('Watching', '${watching.length}', PdfColors.blue700),
                  _pdfStatBox('Planned',  '${planned.length}',  PdfColors.orange700),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            if (watched.isNotEmpty) ...[
              _pdfSectionHeader('Watched', PdfColors.green700),
              pw.SizedBox(height: 8),
              _pdfItemsTable(watched),
              pw.SizedBox(height: 20),
            ],
            if (watching.isNotEmpty) ...[
              _pdfSectionHeader('Watching', PdfColors.blue700),
              pw.SizedBox(height: 8),
              _pdfItemsTable(watching),
              pw.SizedBox(height: 20),
            ],
            if (planned.isNotEmpty) ...[
              _pdfSectionHeader('Planned', PdfColors.orange700),
              pw.SizedBox(height: 8),
              _pdfItemsTable(planned),
            ],
          ],
        ),
      );

      final pdfFile = File(
          '/storage/emulated/0/Download/EzzeWatchList_$timestamp.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      _showSnack(
        context,
        '✅ Exported ${items.length} items!\n'
            '📄 PDF + 💾 JSON saved to Downloads.\n'
            'Images are embedded in the JSON backup.',
      );
    } catch (e) {
      _showSnack(context, '❌ Export failed: $e', isError: true);
    }
  }

  // ── Import — manual file picker ───────────────────────────────────────────

  Future<void> importData(BuildContext context) async {
    try {
      // Open native file browser — user selects JSON manually
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select EzzeWatchList Backup',
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      if (!await file.exists()) {
        _showSnack(context, '❌ File not found.', isError: true);
        return;
      }

      // Parse JSON
      final jsonData =
      jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      if (!jsonData.containsKey('items')) {
        _showSnack(context, '❌ Invalid backup file.', isError: true);
        return;
      }

      // Prepare posters directory
      final appDir = await getApplicationDocumentsDirectory();
      final postersDir = Directory(p.join(appDir.path, 'posters'));
      if (!await postersDir.exists()) {
        await postersDir.create(recursive: true);
      }

      // Restore items + images
      final rawItems = jsonData['items'] as List<dynamic>;
      final items = <WatchItem>[];

      for (final raw in rawItems) {
        final map = Map<String, dynamic>.from(raw as Map);
        String? restoredPosterPath;

        if (map.containsKey('posterBase64') &&
            map['posterBase64'] != null &&
            (map['posterBase64'] as String).isNotEmpty) {
          try {
            final bytes = base64Decode(map['posterBase64'] as String);
            final ext = map['posterExtension'] as String? ?? '.jpg';
            final fileName =
                '${DateTime.now().millisecondsSinceEpoch}_${items.length}$ext';
            final imageFile = File(p.join(postersDir.path, fileName));
            await imageFile.writeAsBytes(bytes);
            restoredPosterPath = imageFile.path;
          } catch (_) {
            restoredPosterPath = null;
          }
        }

        map.remove('posterBase64');
        map.remove('posterExtension');
        if (restoredPosterPath != null) {
          map['posterPath'] = restoredPosterPath;
        }

        items.add(WatchItem.fromMap(map));
      }

      if (items.isEmpty) {
        _showSnack(context, '⚠️ Backup file has no items.', isError: true);
        return;
      }

      if (!context.mounted) return;

      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Options'),
          content: Text(
            'Found ${items.length} items.\n\n'
                '• Merge — keeps existing data, adds new items\n'
                '• Replace All — wipes current data, loads backup',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'merge'),
              child: const Text('Merge'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: const Text('Replace All'),
            ),
          ],
        ),
      );

      if (choice == null) return;
      if (choice == 'replace') await _db.clearAllItems();
      await _db.insertAllItems(items);

      if (!context.mounted) return;
      _showSnack(context, '✅ Imported ${items.length} items with images!');
    } catch (e) {
      _showSnack(context, '❌ Import failed: $e', isError: true);
    }
  }

  // ── PDF helpers ───────────────────────────────────────────────────────────

  pw.Widget _pdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _pdfItemsTable(List<WatchItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(4), // Title
        1: const pw.FlexColumnWidth(2), // Category
        2: const pw.FlexColumnWidth(1.5), // Hindi
        3: const pw.FlexColumnWidth(2), // Watch On
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['Title', 'Category', 'Hindi', 'Watch On']
              .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                  fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ))
              .toList(),
        ),
        // Data rows
        ...items.map((item) => pw.TableRow(
          children: [
            _pdfCell(item.title),
            _pdfCell(item.category),
            _pdfCell(item.hindiAvailable ?? 'No'),
            _pdfCell(item.watchSource ?? '-'),
          ],
        )),
      ],
    );
  }

  pw.Widget _pdfCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
  );


  pw.Widget _pdfStatBox(String label, String value, PdfColor color) =>
      pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey600)),
        ],
      );

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}  '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';

  void _showSnack(BuildContext context, String message,
      {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade700 : null,
      duration: const Duration(seconds: 5),
    ));
  }
}