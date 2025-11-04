// models/data_model.dart
class DatabaseTable {
  final String nodeName;
  final Map<String, dynamic> data;
  final int itemCount;

  DatabaseTable({
    required this.nodeName,
    required this.data,
    required this.itemCount,
  });
}