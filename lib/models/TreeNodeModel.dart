class TreeNode {
  final String key;
  final String value;
  final List<TreeNode> children;
  bool isExpanded;
  final int depth;
  final TreeNode? parent;

  TreeNode({
    required this.key,
    required this.value,
    this.children = const [],
    this.isExpanded = false,
    this.depth = 0,
    this.parent,
  });
}
