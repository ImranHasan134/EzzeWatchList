// lib/ui/add_edit/add_edit_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/network/jikan_service.dart';

import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../data/network/tmdb_service.dart';

class AddEditScreen extends StatefulWidget {
  final int? itemId;
  const AddEditScreen({super.key, this.itemId});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl    = TextEditingController();
  final _yearCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _seasonsCtrl  = TextEditingController();
  final _episodesCtrl = TextEditingController();

  String _category = Category.movie;
  String _status   = WatchStatus.planned;
  double _rating   = 5.0;
  String? _posterPath;
  final Set<String> _selectedGenres = {};

  // 🆕 New UI fields
  String _hindiAvailable = 'No';
  String? _watchSource;

  bool _isLoading = false;
  bool _isSearchingApi = false;
  WatchItem? _editingItem;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) _loadItem();
  }

  // 🆕 Dynamic options
  List<String> get _watchOptions {
    if (_category == Category.animeSeries || _category == Category.animeMovie) {
      return ['MLWBD', 'MovieBox', 'HiAnime'];
    }
    return ['MLWBD', 'MovieBox'];
  }
  bool get _showSeasonEp => _category == Category.webSeries || _category == Category.animeSeries;

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    final item = await context.read<WatchProvider>().getItemById(widget.itemId!);
    if (item != null && mounted) {
      _editingItem = item;
      _titleCtrl.text    = item.title;
      _yearCtrl.text     = item.releaseYear;
      _descCtrl.text     = item.description;
      _category          = item.category;
      _status            = item.status;
      _rating            = item.rating;
      _posterPath        = item.posterPath;
      _selectedGenres.addAll(item.genres.split(',').where((g) => g.isNotEmpty));
      if (item.seasons != null)  _seasonsCtrl.text  = item.seasons.toString();
      if (item.episodes != null) _episodesCtrl.text = item.episodes.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final postersDir = Directory(p.join(appDir.path, 'posters'));
    if (!await postersDir.exists()) await postersDir.create(recursive: true);

    final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
    final savedFile = await File(picked.path).copy(p.join(postersDir.path, fileName));

    setState(() => _posterPath = savedFile.path);
  }

  // ── TMDB SEARCH METHODS ────────────────────────────────────

  Future<void> _searchApi() async {
    final query = _titleCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a title to search first.')));
      return;
    }

    setState(() => _isSearchingApi = true);

    // 🆕 SMART ROUTING: Use Jikan for Anime, TMDB for everything else
    List<Map<String, dynamic>> results = [];
    if (_category == Category.animeSeries || _category == Category.animeMovie) {
      results = await JikanService().searchAnime(query);
    } else {
      results = await TmdbService().searchContent(query);
    }

    setState(() => _isSearchingApi = false);

    if (results.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results found on ${(_category == Category.animeSeries || _category == Category.animeMovie) ? 'Jikan' : 'TMDB'}.')));
      return;
    }

    if (!mounted) return;
    _showSearchResults(results); // We will rename the bottom sheet method too
  }

  void _showSearchResults(List<Map<String, dynamic>> results) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.grey),
          itemBuilder: (ctx, i) {
            final item = results[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: item['posterPath'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: item['posterPath'],
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.movie),
                ),
              )
                  : const Icon(Icons.movie, size: 50),
              title: Text(item['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['releaseYear']} • ${item['category']}'),
              trailing: Text('⭐ ${item['rating']}', style: const TextStyle(color: Color(0xFFFFD700))),
                onTap: () async {
                  // 🆕 Pop the sheet instantly for a snappy UI feel
                  Navigator.pop(ctx);

                  int? seasons;
                  int? episodes = item['episodes']; // Pre-filled from Jikan if Anime

                  // 🆕 If it's a Web Series, fetch the exact counts from TMDB in the background
                  if (item['category'] == 'Web Series' && item['id'] != null) {
                    final details = await TmdbService().getTvSeasonEpisode(item['id']);
                    seasons = details['seasons'];
                    episodes = details['episodes'];
                  }

                  setState(() {
                    _titleCtrl.text = item['title'] ?? '';
                    _yearCtrl.text = item['releaseYear'] ?? '';
                    _descCtrl.text = item['description'] ?? '';
                    _posterPath = item['posterPath'];

                    double newRating = (item['rating'] as num).toDouble();
                    _rating = newRating.clamp(1.0, 10.0);

                    if (Category.all.contains(item['category'])) {
                      _category = item['category'];
                    }

                    // 🆕 Auto-fill the Season and Episode boxes!
                    if (seasons != null && seasons > 0) _seasonsCtrl.text = seasons.toString();
                    if (episodes != null && episodes > 0) _episodesCtrl.text = episodes.toString();

                    if (item['genres'] != null) {
                      final fetchedGenres = List<String>.from(item['genres']);
                      _selectedGenres.clear();
                      _selectedGenres.addAll(fetchedGenres.take(4));

                      for (final g in _selectedGenres) {
                        if (!Genre.all.contains(g)) Genre.all.add(g);
                      }
                      Genre.all.sort();
                    }
                  });
                },
            );
          },
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = WatchItem(
      id: _editingItem?.id,
      title: _titleCtrl.text.trim(),
      category: _category,
      genres: _selectedGenres.join(','),
      releaseYear: _yearCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      rating: _rating,
      status: _status,
      posterPath: _posterPath,
      seasons: _seasonsCtrl.text.isNotEmpty ? int.tryParse(_seasonsCtrl.text) : null,
      episodes: _episodesCtrl.text.isNotEmpty ? int.tryParse(_episodesCtrl.text) : null,
      createdAt: _editingItem?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      hindiAvailable: _hindiAvailable,
      watchSource: _watchSource ?? _watchOptions.first,
    );

    final provider = context.read<WatchProvider>();
    if (_editingItem == null) {
      provider.addItem(item);
    } else {
      provider.updateItem(item);
    }

    Navigator.pop(context);
  }
  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    _seasonsCtrl.dispose();
    _episodesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.itemId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5);
    final surfaceColor = isDark ? const Color(0xFF141414) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surfaceColor,
        title: Row(
          children: [
            Container(
              width: 3,
              height: 22,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Item' : 'Add Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ).createShader(bounds),
                  child: const Text(
                    'Manage your watchlist item',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPosterSection(isDark),
              const SizedBox(height: 16),

              // 🆕 UPDATED TITLE FIELD WITH SEARCH BUTTON
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(_titleCtrl, 'Title *', isDark,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 55,
                    child: IconButton.filled(
                      onPressed: _isSearchingApi ? null : _searchApi,
                      icon: _isSearchingApi
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.search),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildDropdown(
                'Category',
                Category.all,
                _category,
                    (v) => setState(() {
                  _category = v!;
                  _watchSource = null;
                }),
                isDark,
              ),

              const SizedBox(height: 12),

              _buildDropdown('Status', WatchStatus.all, _status,
                      (v) => setState(() => _status = v!), isDark),

              const SizedBox(height: 12),

              _buildTextField(_yearCtrl, 'Release Year', isDark,
                  keyboardType: TextInputType.number, maxLength: 4),

              const SizedBox(height: 12),

              _buildDropdown(
                'Hindi Available?',
                ['Yes', 'No'],
                _hindiAvailable,
                    (v) => setState(() => _hindiAvailable = v!),
                isDark,
              ),

              const SizedBox(height: 12),

              _buildDropdown(
                'Where to Watch',
                _watchOptions,
                _watchSource ?? _watchOptions.first,
                    (v) => setState(() => _watchSource = v),
                isDark,
              ),

              const SizedBox(height: 12),

              _buildMultiSelectDropdown('Genres', Genre.all, _selectedGenres, isDark),

              const SizedBox(height: 12),

              _buildTextField(_descCtrl, 'Description', isDark, maxLines: 3),

              const SizedBox(height: 12),

              _buildRatingSlider(isDark),

              if (_showSeasonEp) ...[
                const SizedBox(height: 12),
                _buildSeasonEpisodeRow(isDark),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _save,
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ──────────────────────────────────────────

  Widget _buildPosterSection(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 140,
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
          ),
          clipBehavior: Clip.antiAlias,
          child: _posterPath != null
              ? Stack(fit: StackFit.expand, children: [
            // 🆕 UPDATED TO HANDLE BOTH WEB URLS AND LOCAL FILES
            _posterPath!.startsWith('http')
                ? CachedNetworkImage(
              imageUrl: _posterPath!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _posterPlaceholder(),
            )
                : Image.file(File(_posterPath!), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _posterPlaceholder()),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text(
                  '📷 Change',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ])
              : _posterPlaceholder(),
        ),
      ),
    );
  }

  Widget _posterPlaceholder() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
      SizedBox(height: 8),
      Text('Add Poster Image', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );

  Widget _buildTextField(
      TextEditingController ctrl,
      String label,
      bool isDark, {
        String? Function(String?)? validator,
        TextInputType? keyboardType,
        int maxLines = 1,
        int? maxLength,
      }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        counterText: maxLength != null ? null : '',
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String value,
      ValueChanged<String?> onChanged,
      bool isDark,
      ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildMultiSelectDropdown(String label, List<String> items, Set<String> selected, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final result = await showDialog<Set<String>>(
              context: context,
              builder: (context) {
                final tempSelected = Set<String>.from(selected);
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                      title: const Text('Select Genres'),
                      content: SingleChildScrollView(
                        child: Column(
                          children: items.map((e) {
                            return CheckboxListTile(
                              value: tempSelected.contains(e),
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) tempSelected.add(e);
                                  else tempSelected.remove(e);
                                });
                              },
                              title: Text(e, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                            );
                          }).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, tempSelected),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            );

            if (result != null) {
              setState(() => selected
                ..clear()
                ..addAll(result));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
            ),
            child: Text(
              selected.isEmpty ? 'Select genres' : selected.join(', '),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rating', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${_rating.toStringAsFixed(1)} / 10',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700)),
            ),
          ],
        ),
        Slider(
          value: _rating,
          min: 1,
          max: 10,
          divisions: 18,
          label: _rating.toStringAsFixed(1),
          activeColor: const Color(0xFFFFD700),
          onChanged: (v) => setState(() => _rating = v),
        ),
      ],
    );
  }

  Widget _buildSeasonEpisodeRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _seasonsCtrl,
            decoration: InputDecoration(
              labelText: 'Seasons',
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _episodesCtrl,
            decoration: InputDecoration(
              labelText: 'Episodes',
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}