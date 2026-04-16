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
import '../../widgets/custom_header.dart';

class AddEditScreen extends StatefulWidget {
  final int? itemId;
  const AddEditScreen({super.key, this.itemId});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  int? _tmdbId;
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl    = TextEditingController();
  final _yearCtrl     = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _seasonsCtrl  = TextEditingController();
  final _episodesCtrl = TextEditingController();
  final _linkCtrl     = TextEditingController();

  String _category = Category.movie;
  String _status   = WatchStatus.planned;
  double _rating   = 5.0;
  String? _posterPath;
  final Set<String> _selectedGenres = {};

  String _hindiAvailable = 'No';
  String _watchSource = 'None';

  bool _isLoading = false;
  bool _isSearchingApi = false;
  WatchItem? _editingItem;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) _loadItem();
  }

  List<String> get _watchOptions {
    if (_category == Category.animeSeries || _category == Category.animeMovie) {
      return ['None', 'MLWBD', 'MovieBox', 'HiAnime', 'Watch Here'];
    }
    return ['None', 'MLWBD', 'MovieBox', 'Watch Here'];
  }

  bool get _showSeasonEp => _category == Category.webSeries || _category == Category.animeSeries;

  // ── PRESERVED FUNCTIONS ──────────────────────────────────────

  Future<void> _loadItem() async {
    setState(() => _isLoading = true);
    final item = await context.read<WatchProvider>().getItemById(widget.itemId!);
    if (item != null && mounted) {
      _editingItem = item;
      _tmdbId = item.tmdbId;
      _titleCtrl.text    = item.title;
      _yearCtrl.text     = item.releaseYear;
      _descCtrl.text     = item.description;
      _category          = item.category;
      _status            = item.status;
      _rating            = item.rating;
      _posterPath        = item.posterPath;
      _watchSource       = (item.watchSource == null || item.watchSource!.isEmpty) ? 'None' : item.watchSource!;
      _linkCtrl.text     = item.showLink ?? '';
      _hindiAvailable    = item.hindiAvailable ?? 'No';

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

  Future<void> _searchApi() async {
    final query = _titleCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a title to search.')));
      return;
    }
    setState(() => _isSearchingApi = true);
    List<Map<String, dynamic>> results = [];
    if (_category == Category.animeSeries || _category == Category.animeMovie) {
      results = await JikanService().searchAnime(query);
    } else {
      results = await TmdbService().searchContent(query);
    }
    setState(() => _isSearchingApi = false);
    if (results.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No results found.')));
      return;
    }
    if (!mounted) return;
    _showSearchResults(results);
  }

  void _showSearchResults(List<Map<String, dynamic>> results) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: results.length,
          itemBuilder: (ctx, i) {
            final item = results[i];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['posterPath'] != null
                    ? CachedNetworkImage(imageUrl: item['posterPath'], width: 50, height: 75, fit: BoxFit.cover)
                    : Container(color: Colors.grey, width: 50, height: 75),
              ),
              title: Text(item['title'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['releaseYear']} • ${item['category']}'),
              onTap: () async {
                Navigator.pop(ctx);
                final tmdbId = item['tmdbId'];
                final category = item['category'] ?? 'Movie';
                int? fetchedSeasons; int? fetchedEpisodes;
                if (tmdbId != null && (category == 'Web Series' || category == 'Anime Series')) {
                  final tvDetails = await TmdbService().getTvSeasonEpisode(tmdbId);
                  fetchedSeasons = tvDetails['seasons']; fetchedEpisodes = tvDetails['episodes'];
                }
                setState(() {
                  _tmdbId = tmdbId;
                  _titleCtrl.text = item['title'] ?? '';
                  _category = category;
                  _seasonsCtrl.text = fetchedSeasons?.toString() ?? '';
                  _episodesCtrl.text = fetchedEpisodes?.toString() ?? '';
                  _yearCtrl.text = item['releaseYear'] ?? '';
                  _descCtrl.text = item['description'] ?? '';
                  _rating = item['rating'] ?? 5.0;
                  _posterPath = item['posterPath'];
                  if (item['genres'] != null) {
                    _selectedGenres.clear();
                    _selectedGenres.addAll(List<String>.from(item['genres']));
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = WatchItem(
      id: _editingItem?.id,
      tmdbId: _tmdbId,
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
      watchSource: _watchSource == 'None' ? '' : _watchSource,
      showLink: _linkCtrl.text.trim(),
    );
    final provider = context.read<WatchProvider>();
    if (_editingItem == null) provider.addItem(item); else provider.updateItem(item);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    _seasonsCtrl.dispose();
    _episodesCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  // ── UI RENDERING ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(widget.itemId == null ? 'Add Media' : 'Edit Details',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernPoster(isDark),
              const SizedBox(height: 32),

              _buildSectionHeader('SHOW TITLE'),
              const SizedBox(height: 16),
              _buildTitleField(isDark),
              const SizedBox(height: 16),

              _buildLabel('Category'),
              _buildChoiceChips(Category.all, _category, (val) => setState(() => _category = val), isDark),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernField(_yearCtrl, 'Release Year', Icons.calendar_today_rounded, isDark, keyboard: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildHindiToggle(isDark)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('WATCH DETAILS'),
              const SizedBox(height: 16),
              _buildLabel('Watch Status'),
              _buildChoiceChips(WatchStatus.all, _status, (val) => setState(() => _status = val), isDark),

              const SizedBox(height: 16),
              _buildLabel('Watch Platform'), // 🆕 Added Heading
              _buildModernDropdown('Stream From', _watchOptions, _watchSource, (val) => setState(() => _watchSource = val!), isDark),

              if (_watchSource != 'None') ...[
                const SizedBox(height: 16),
                _buildLabel('Stream URL'), // 🆕 Added Heading
                _buildModernField(_linkCtrl, 'https://...', Icons.link_rounded, isDark),
              ],

              const SizedBox(height: 32),
              _buildSectionHeader('RATINGS & GENRES'),
              const SizedBox(height: 16),
              _buildLabel('Genres'), // 🆕 Added Heading
              _buildGenreSelector(isDark),
              const SizedBox(height: 24),
              _buildModernRating(isDark),

              if (_showSeasonEp) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildModernField(_seasonsCtrl, 'Seasons', Icons.layers_rounded, isDark, keyboard: TextInputType.number)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernField(_episodesCtrl, 'Episodes', Icons.vibration_rounded, isDark, keyboard: TextInputType.number)),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              _buildLabel('Description'), // 🆕 Added Heading
              _buildModernField(_descCtrl, 'Storyline / Overview', Icons.description_rounded, isDark, maxLines: 4),

              const SizedBox(height: 40),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── PREMIUM UI HELPERS ──────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey));
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildModernPoster(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 150, height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          clipBehavior: Clip.antiAlias,
          child: _posterPath != null
              ? Stack(fit: StackFit.expand, children: [
            _posterPath!.startsWith('http')
                ? CachedNetworkImage(imageUrl: _posterPath!, fit: BoxFit.cover)
                : Image.file(File(_posterPath!), fit: BoxFit.cover),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])))),
            const Align(alignment: Alignment.bottomCenter, child: Padding(padding: EdgeInsets.all(12), child: Text('CHANGE IMAGE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)))),
          ])
              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.grey), SizedBox(height: 8), Text('Add Poster', style: TextStyle(color: Colors.grey, fontSize: 12))]),
        ),
      ),
    );
  }

  Widget _buildTitleField(bool isDark) {
    return TextFormField(
      controller: _titleCtrl,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Movie or Show Title',
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        suffixIcon: _isSearchingApi
            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))))
            : IconButton(icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700)), onPressed: _searchApi),
      ),
      validator: (v) => v!.isEmpty ? 'Title required' : null,
    );
  }

  Widget _buildChoiceChips(List<String> options, String current, Function(String) onSelect, bool isDark) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = current == opt;
        return ChoiceChip(
          label: Text(opt, style: TextStyle(color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          onSelected: (val) { if (val) onSelect(opt); },
          selectedColor: const Color(0xFFFFD700),
          backgroundColor: isDark ? Colors.white10 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.2))),
        );
      }).toList(),
    );
  }

  Widget _buildModernField(TextEditingController ctrl, String hint, IconData icon, bool isDark, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildHindiToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('Hindi?', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Spacer(),
          Switch(
            value: _hindiAvailable == 'Yes',
            onChanged: (val) => setState(() => _hindiAvailable = val ? 'Yes' : 'No'),
            activeColor: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String value, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGenreSelector(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Set<String>>(context: context, builder: (context) {
          final temp = Set<String>.from(_selectedGenres);
          return StatefulBuilder(builder: (ctx, setState) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            title: const Text('Genres'),
            content: SingleChildScrollView(child: Wrap(spacing: 8, children: Genre.all.map((g) => FilterChip(label: Text(g), selected: temp.contains(g), onSelected: (v) => setState(() => v ? temp.add(g) : temp.remove(g)), selectedColor: const Color(0xFFFFD700))).toList())),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, temp), child: const Text('Save'))],
          ));
        });
        if (result != null) setState(() => _selectedGenres..clear()..addAll(result));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
        child: Text(_selectedGenres.isEmpty ? 'Tap to select genres...' : _selectedGenres.join(', '), style: TextStyle(color: _selectedGenres.isEmpty ? Colors.grey : (isDark ? Colors.white : Colors.black))),
      ),
    );
  }

  Widget _buildModernRating(bool isDark) {
    return Column(
      children: [
        Row(children: [const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 20), const SizedBox(width: 8), const Text('Personal Rating', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Text('${_rating.toStringAsFixed(1)}/10', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFFD700)))]),
        Slider(value: _rating, min: 1, max: 10, divisions: 18, activeColor: const Color(0xFFFFD700), inactiveColor: isDark ? Colors.white10 : Colors.black12, onChanged: (v) => setState(() => _rating = v)),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: _save,
        child: const Text('SAVE TO WATCHLIST', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    );
  }
}