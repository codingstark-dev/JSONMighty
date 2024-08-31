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
  String _searchQuery = '';
  List<TreeNode> _searchResults = [];
  int _currentSearchIndex = -1;
  final TextEditingController _searchController = TextEditingController();

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

  void _performSearch() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      _searchResults = _searchNodes(_rootNode, query);
      _currentSearchIndex = _searchResults.isNotEmpty ? 0 : -1;
    });
  }

  List<TreeNode> _searchNodes(TreeNode? node, String query) {
    List<TreeNode> results = [];
    if (node == null) return results;

    if (node.key.toLowerCase().contains(query.toLowerCase()) ||
        node.value.toLowerCase().contains(query.toLowerCase())) {
      results.add(node);
    }

    for (var child in node.children) {
      results.addAll(_searchNodes(child, query));
    }

    return results;
  }

  void _scrollToNextResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex + 1) % _searchResults.length;
    });
    _scrollToCurrentResult();
  }

  void _scrollToPreviousResult() {
    if (_searchResults.isEmpty) return;
    setState(() {
      _currentSearchIndex = (_currentSearchIndex - 1 + _searchResults.length) %
          _searchResults.length;
    });
    _scrollToCurrentResult();
  }

  void _scrollToCurrentResult() {
    if (_currentSearchIndex >= 0 &&
        _currentSearchIndex < _searchResults.length) {
      final currentNode = _searchResults[_currentSearchIndex];
      setState(() {
        _expandParents(currentNode);
      });
    }
  }

  void _expandParents(TreeNode node) {
    TreeNode? current = node;
    while (current != null) {
      current.isExpanded = true;
      current = current.parent;
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
                if (_searchResults.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _scrollToPreviousResult,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: _scrollToNextResult,
                  ),
                  Text('${_currentSearchIndex + 1}/${_searchResults.length}'),
                ],
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rootNode == null
                    ? const Center(child: Text('No JSON loaded'))
                    : CustomJsonTreeView(
                        rootNode: _rootNode!,
                        searchQuery: _searchQuery,
                        currentSearchNode: _currentSearchIndex >= 0
                            ? _searchResults[_currentSearchIndex]
                            : null,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadJsonFile,
        tooltip: 'Load JSON',
        child: const Icon(Icons.file_upload),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CustomJsonTreeView extends StatefulWidget {
  final TreeNode rootNode;
  final String searchQuery;
  final TreeNode? currentSearchNode;

  const CustomJsonTreeView({
    super.key,
    required this.rootNode,
    required this.searchQuery,
    this.currentSearchNode,
  });

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

  void _expandToNode(TreeNode node) {
    TreeNode? current = node;
    while (current != null) {
      current.isExpanded = true;
      current = current.parent;
    }
    _flattenedNodes.clear();
    _flattenNodes(widget.rootNode);
  }

  void _scrollToSearchResult() {
    if (widget.currentSearchNode != null) {
      _expandToNode(widget.currentSearchNode!);
      final index = _flattenedNodes.indexOf(widget.currentSearchNode!);
      if (index != -1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            index * 30.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _flattenedNodes.length,
      itemExtent: 30,
      cacheExtent: 30 * _visibleItemCount.toDouble(),
      itemBuilder: (context, index) {
        if (index < _firstVisibleItemIndex ||
            index >= _firstVisibleItemIndex + _visibleItemCount) {
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
      searchQuery: widget.searchQuery,
      isCurrentSearchResult: node == widget.currentSearchNode,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
