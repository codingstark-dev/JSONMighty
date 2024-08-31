import 'package:JSONMighty/models/TreeNodeModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final Function(TreeNode) onToggle;
  final String searchQuery;
  final bool isCurrentSearchResult;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.onToggle,
    required this.searchQuery,
    required this.isCurrentSearchResult,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearchResult = searchQuery.isNotEmpty &&
        (node.key.toLowerCase().contains(searchQuery.toLowerCase()) ||
            node.value.toLowerCase().contains(searchQuery.toLowerCase()));

    return Container(
      color: isCurrentSearchResult ? Colors.yellow.withOpacity(0.3) : null,
      child: Padding(
        padding: EdgeInsets.only(left: 20.0 * node.depth),
        child: Row(
          children: [
            _buildToggleButton(),
            Expanded(child: _buildNodeContent(context, isSearchResult)),
            _buildCopyButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return IconButton(
      icon: Icon(
        node.children.isNotEmpty
            ? (node.isExpanded ? Icons.expand_more : Icons.chevron_right)
            : Icons.circle,
        size: node.children.isNotEmpty ? 24 : 12,
      ),
      onPressed: node.children.isNotEmpty ? () => onToggle(node) : null,
    );
  }

  Widget _buildNodeContent(BuildContext context, bool isSearchResult) {
    final text =
        '${node.key}: ${node.value} ${node.children.isNotEmpty ? "(${node.children.length} items)" : ""}';

    return SelectableText.rich(
      TextSpan(
        children: isSearchResult
            ? _highlightSearchQuery(text, searchQuery)
            : [TextSpan(text: text, style: DefaultTextStyle.of(context).style)],
      ),
      maxLines: 1,
      minLines: 1,
      onTap: () => onToggle(node),
    );
  }

  Widget _buildCopyButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy, size: 16),
      onPressed: () {
        final text = '${node.key}: ${node.value}';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard')),
        );
      },
    );
  }

  List<TextSpan> _highlightSearchQuery(String text, String query) {
    final List<TextSpan> spans = [];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
            backgroundColor: Colors.yellow,
            color: Colors.black,
            fontWeight: FontWeight.bold),
      ));

      start = index + query.length;
    }

    return spans;
  }
}
