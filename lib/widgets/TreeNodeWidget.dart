import 'package:JSONMighty/models/TreeNodeModel.dart';
import 'package:flutter/material.dart';

class TreeNodeWidget extends StatelessWidget {
  final TreeNode node;
  final Function(TreeNode) onToggle;

  const TreeNodeWidget({
    super.key,
    required this.node,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20.0 * node.depth),
      child: Row(
        children: [
          _buildToggleButton(),
          Expanded(child: _buildNodeContent()),
        ],
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

  Widget _buildNodeContent() {
    return Text(
      '${node.key}: ${node.value} ${node.children.isNotEmpty ? "(${node.children.length} items)" : ""}',
      overflow: TextOverflow.ellipsis,
    );
  }
}

