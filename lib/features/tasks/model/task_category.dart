import 'package:flutter/material.dart';

class TaskCategory {
  final int id;
  final String name;
  final Color color;

  TaskCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  TaskCategory copyWith({
    int? id,
    String? name,
    Color? color,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      color: _parseColor(json['color']?.toString()),
    );
  }

  String get colorHex {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static Color _parseColor(String? rawColor) {
    if (rawColor == null || rawColor.isEmpty) {
      return const Color(0xFF5B8CCB);
    }

    final normalized = rawColor.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) {
      return const Color(0xFF5B8CCB);
    }

    return Color(0xFF000000 | value);
  }
}
