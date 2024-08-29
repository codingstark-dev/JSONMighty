
import 'dart:convert';
import 'dart:io';

import 'package:JSONMighty/models/ProcessResult.dart';
import 'package:JSONMighty/models/TreeNodeModel.dart';
import 'package:flutter/foundation.dart';

Future<String> readJsonFile(String filePath) async {
  final file = File(filePath);
  return await file.readAsString();
}


Future<ProcessResult> processJson(String jsonString) {
  return compute(_isolateProcessJson, jsonString);
}

ProcessResult _isolateProcessJson(String jsonString) {
  int totalNodes = 0;

  TreeNode convertJsonToNode(dynamic data, {String key = 'root', int depth = 0, TreeNode? parent}) {
    if (data is Map<String, dynamic>) {
      List<TreeNode> children = data.entries.map((entry) => convertJsonToNode(entry.value, key: entry.key, depth: depth + 1, parent: parent)).toList();
      totalNodes += children.length;
      return TreeNode(key: key, value: '{...}', children: children, depth: depth, parent: parent);
    } else if (data is List) {
      List<TreeNode> children = data.asMap().entries.map((entry) => convertJsonToNode(entry.value, key: '[${entry.key}]', depth: depth + 1, parent: parent)).toList();
      totalNodes += children.length;
      return TreeNode(key: key, value: '[...]', children: children, depth: depth, parent: parent);
    } else {
      totalNodes += 1;
      return TreeNode(key: key, value: data.toString(), depth: depth, parent: parent);
    }
  }

  final dynamic jsonData = json.decode(jsonString);
  final rootNode = convertJsonToNode(jsonData);
  return ProcessResult(rootNode, totalNodes);
}
