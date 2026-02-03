import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class DatabaseService {
  final CollectionReference taskCollection = FirebaseFirestore.instance.collection('tasks');
  final User? user = FirebaseAuth.instance.currentUser;

  // --- CREATE (Dengan Dokumen & Subtask) ---
  Future<void> addTask({
    required String title,
    required String description,
    required DateTime deadline,
    required String priority,
    required List<Map<String, dynamic>> subtasks,
    String? imagePath,
    String? filePath,   // Path Dokumen Lokal
    String? fileName,   // Nama File Dokumen
  }) async {
    if (user == null) throw Exception("No user logged in");

    // Proses Gambar ke Base64
    String? imageBase64;
    if (imagePath != null) {
      File imageFile = File(imagePath);
      List<int> bytes = await imageFile.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    // Proses Dokumen (PDF/Word) ke Base64
    String? fileBase64;
    if (filePath != null) {
      File docFile = File(filePath);
      // Cek ukuran file (Max 500KB biar database gak meledak)
      int sizeInBytes = await docFile.length();
      if (sizeInBytes > 500 * 1024) throw Exception("File terlalu besar! Max 500KB.");

      List<int> bytes = await docFile.readAsBytes();
      fileBase64 = base64Encode(bytes);
    }

    await taskCollection.add({
      'userId': user!.uid,
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'isCompleted': false,
      'priority': priority,
      'subtasks': subtasks,
      'imageUrl': imageBase64,
      'fileData': fileBase64, // Simpan Dokumen
      'fileName': fileName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- READ ---
  Stream<List<TaskModel>> getTasks() {
    if (user == null) return const Stream.empty();
    return taskCollection
        .where('userId', isEqualTo: user!.uid)
        .orderBy('deadline')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TaskModel.fromSnapshot(doc)).toList());
  }

  // --- UPDATE (Lengkap) ---
  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required DateTime deadline,
    required String priority,
    required List<Map<String, dynamic>> subtasks,
    String? imagePath,
    String? oldImageUrl,
    String? filePath,     // Path Dokumen Baru
    String? fileName,     // Nama Dokumen Baru
    String? oldFileData,  // Data Dokumen Lama
    String? oldFileName,  // Nama Dokumen Lama
  }) async {
    // Logic Gambar
    String? finalImage = oldImageUrl;
    if (imagePath != null) {
      File img = File(imagePath);
      finalImage = base64Encode(await img.readAsBytes());
    }

    // Logic Dokumen
    String? finalFileData = oldFileData;
    String? finalFileName = oldFileName;

    if (filePath != null) {
      File doc = File(filePath);
      int size = await doc.length();
      if (size > 500 * 1024) throw Exception("File terlalu besar! Max 500KB.");

      finalFileData = base64Encode(await doc.readAsBytes());
      finalFileName = fileName;
    }

    await taskCollection.doc(taskId).update({
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'priority': priority,
      'subtasks': subtasks,
      'imageUrl': finalImage,
      'fileData': finalFileData,
      'fileName': finalFileName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- DELETE & TOGGLES (Biarkan Saja) ---
  Future<void> toggleSubtask(String taskId, List<Map<String, dynamic>> subtasks, int index) async {
    subtasks[index]['isDone'] = !subtasks[index]['isDone'];
    bool allDone = subtasks.isNotEmpty && subtasks.every((s) => s['isDone'] == true);
    await taskCollection.doc(taskId).update({'subtasks': subtasks, 'isCompleted': allDone});
  }

  Future<void> toggleTaskComplete(String taskId, bool isCompleted) async {
    await taskCollection.doc(taskId).update({'isCompleted': isCompleted});
  }

  Future<void> deleteTask(String taskId) async {
    await taskCollection.doc(taskId).delete();
  }
}