import 'package:flutter/material.dart';
import 'package:quevault_app/widgets/app_drawer.dart';

class BaseScaffold extends StatefulWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool centerTitle;

  const BaseScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.centerTitle = true,
  });

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), centerTitle: widget.centerTitle, actions: widget.actions),
      drawer: const AppDrawer(),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}
