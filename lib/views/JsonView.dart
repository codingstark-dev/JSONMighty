import 'dart:developer';
import 'dart:io';
import 'package:JSONMighty/models/TreeNodeModel.dart';
import 'package:JSONMighty/utils/JsonUtils.dart';
import 'package:JSONMighty/widgets/TreeNodeWidget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class JsonViewerPage extends StatefulWidget {
  const JsonViewerPage({super.key});

  @override
  JsonViewerPageState createState() => JsonViewerPageState();
}

class JsonViewerPageState extends State<JsonViewerPage> {
  TreeNode? _rootNode;
  bool _isLoading = false;
  int _totalNodes = 0;

  Future<void> _loadJsonFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        File file = File(result.files.single.path!);
        final jsonString = await compute(readJsonFile, file.path);
        final processResult = await compute(processJson, jsonString);
        setState(() {
          _rootNode = processResult.rootNode;
          _totalNodes = processResult.totalNodes;
        });
      }
    } catch (e) {
      log('Error loading JSON: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading JSON file')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSONMighty'),
        actions: [
          if (_totalNodes > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text('Total nodes: $_totalNodes')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rootNode == null
              ? const Center(child: Text('No JSON loaded'))
              : CustomJsonTreeView(rootNode: _rootNode!),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadJsonFile,
        tooltip: 'Load JSON',
        child: const Icon(Icons.file_upload),
      ),
    );
  }
}

class CustomJsonTreeView extends StatefulWidget {
  final TreeNode rootNode;

  const CustomJsonTreeView({super.key, required this.rootNode});

  @override
  CustomJsonTreeViewState createState() => CustomJsonTreeViewState();
}

class CustomJsonTreeViewState extends State<CustomJsonTreeView> {
  final ScrollController _scrollController = ScrollController();
  final List<TreeNode> _flattenedNodes = [];
  final int _visibleItemCount = 100; // Adjust based on performance
  int _firstVisibleItemIndex = 0;

  @override
  void initState() {
    super.initState();
    _flattenNodes(widget.rootNode);
    _scrollController.addListener(_onScroll);
  }

  void _flattenNodes(TreeNode node) {
    _flattenedNodes.add(node);
    if (node.isExpanded) {
      for (var child in node.children) {
        _flattenNodes(child);
      }
    }
  }

  void _onScroll() {
    final newFirstIndex = (_scrollController.offset / 30).floor(); 
    if (newFirstIndex != _firstVisibleItemIndex) {
      setState(() {
        _firstVisibleItemIndex = newFirstIndex;
      });
    }
  }

  void _toggleNode(TreeNode node) {
    setState(() {
      node.isExpanded = !node.isExpanded;
      _flattenedNodes.clear();
      _flattenNodes(widget.rootNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _flattenedNodes.length,
      itemExtent: 30, 
      cacheExtent: 30 * _visibleItemCount.toDouble(), 
      itemBuilder: (context, index) {
        if (index < _firstVisibleItemIndex || index >= _firstVisibleItemIndex + _visibleItemCount) {
          return const SizedBox.shrink();
        }
        return _buildTreeNode(_flattenedNodes[index]);
      },
    );
  }

  Widget _buildTreeNode(TreeNode node) {
    return TreeNodeWidget(
      node: node,
      onToggle: _toggleNode,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
