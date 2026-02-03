import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime deadline;
  final bool isCompleted;
  final String priority;

  // Data Gambar & File
  final String? imageUrl;       // Base64 Foto
  final String? fileData;       // Base64 Dokumen (PDF/Word) - BARU
  final String? fileName;       // Nama Dokumen (misal: tugas.pdf) - BARU

  final List<Map<String, dynamic>> subtasks;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.isCompleted,
    required this.priority,
    this.imageUrl,
    this.fileData,
    this.fileName,
    required this.subtasks,
    required this.createdAt,
  });

  factory TaskModel.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Medium',
      imageUrl: data['imageUrl'],
      fileData: data['fileData'], // Ambil data file
      fileName: data['fileName'], // Ambil nama file
      subtasks: List<Map<String, dynamic>>.from(data['subtasks'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}