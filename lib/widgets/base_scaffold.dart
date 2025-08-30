import 'package:flutter/material.dart';
import 'package:quevault_app/widgets/app_drawer.dart';

class BaseScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final Function(String)? onSearch;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = true,
    this.onSearch,
  });

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    // Focus the search field after the widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  void _onSearchChanged(String query) {
    widget.onSearch?.call(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search passwords...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              )
            : Text(widget.title),
        centerTitle: _isSearching ? false : widget.centerTitle,
        actions: [
          if (!_isSearching) ...?widget.actions,
          if (!_isSearching)
            IconButton(icon: const Icon(Icons.search), onPressed: _startSearch)
          else
            IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch),
        ],
      ),
      drawer: const AppDrawer(),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
