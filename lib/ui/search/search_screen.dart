// lib/ui/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/database/watch_provider.dart';
import '../../data/models/watch_item.dart';
import '../../widgets/poster_card.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _showAdvanced = false; // 🆕 Toggle for advanced filters

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WatchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search movie/anime/series...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
          onChanged: (query) => provider.setSearchQuery(query),
        ),
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        elevation: 0,
        actions: [ // 🆕 Add filter icon
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: isDark ? Colors.white70 : Colors.black54),
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          )
        ],
      ),
      body: Column(
        children: [
          // 🆕 ADVANCED FILTERS SECTION (Expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showAdvanced ? 200 : 0,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: _showAdvanced ? 8 : 0),
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SORTING
                  const Text('SORT BY', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: provider.sortingOption,
                    isExpanded: true,
                    items: ['Recently Added', 'Highest Rated', 'Newest Release'].map((String option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (option) => provider.setSortingOption(option!),
                  ),
                  const SizedBox(height: 12),

                  // GENRES
                  const Text('GENRES', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: Genre.all.take(10).map((genre) { // limit to top 10 for cleaner UI
                      final isSelected = provider.filterGenre == genre;
                      return FilterChip(
                        label: Text(genre, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) => provider.setFilterGenre(selected ? genre : ''),
                        selectedColor: const Color(0xFFFFD700).withOpacity(0.3),
                        checkmarkColor: const Color(0xFFFFD700),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // SEARCH RESULTS
          Expanded(
            child: provider.searchResults.isEmpty
                ? Center(child: Text('No results found.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)))
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.55,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final item = provider.searchResults[index];
                return PosterCard(
                  item: item,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(itemId: item.id!))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}