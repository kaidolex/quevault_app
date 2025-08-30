import 'package:flutter/material.dart';
import 'package:quevault_app/widgets/app_drawer.dart';

class BaseScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;

  const BaseScaffold({super.key, required this.title, required this.body, this.actions, this.floatingActionButton, this.centerTitle = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search feature coming soon!')));
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
