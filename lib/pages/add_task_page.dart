import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; // Foto
import 'package:file_picker/file_picker.dart';   // Dokumen
import '../services/database_service.dart';
import '../services/notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers Utama
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedPriority = 'Medium';

  // Controllers Subtasks (Dynamic List)
  final List<TextEditingController> _subtaskControllers = [];

  // File & Image
  File? _imageFile;
  File? _docFile;
  String? _docName;

  bool _isLoading = false;
  final List<String> _priorities = ['High', 'Medium', 'Low'];

  // --- LOGIC TAMBAH / HAPUS SUBTASK UI ---
  void _addSubtaskField() {
    setState(() {
      _subtaskControllers.add(TextEditingController());
    });
  }

  void _removeSubtaskField(int index) {
    setState(() {
      _subtaskControllers.removeAt(index);
    });
  }

  // --- LOGIC PICKER ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 25);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      int size = await file.length();
      if (size > 500 * 1024) { // Max 500KB
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File max 500KB!")));
        return;
      }
      setState(() {
        _docFile = file;
        _docName = result.files.single.name;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Konversi Controller Subtask jadi List Map
      List<Map<String, dynamic>> subtasksList = [];
      for (var controller in _subtaskControllers) {
        if (controller.text.trim().isNotEmpty) {
          subtasksList.add({'title': controller.text.trim(), 'isDone': false});
        }
      }

      // 2. Kirim ke Database
      await DatabaseService().addTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        deadline: _selectedDate,
        priority: _selectedPriority,
        subtasks: subtasksList,
        imagePath: _imageFile?.path,
        filePath: _docFile?.path,
        fileName: _docName,
      );

      await NotificationService.showNotification(
        title: "New Project Added! 🚀",
        body: "Don't forget '${_titleController.text}'",
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project Created!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Project")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- JUDUL ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Project Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),

              // --- DESKRIPSI ---
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // --- DEADLINE & PRIORITY ---
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedPriority,
                      items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) => setState(() => _selectedPriority = val!),
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Deadline', border: OutlineInputBorder()),
                        child: Text(DateFormat('d MMM').format(_selectedDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- ATTACHMENTS (FOTO & DOKUMEN) ---
              const Text("Attachments", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Tombol Foto
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(_imageFile == null ? Icons.camera_alt : Icons.check, color: Colors.white),
                      label: Text(_imageFile == null ? "Add Photo" : "Photo Added"),
                      style: ElevatedButton.styleFrom(backgroundColor: _imageFile == null ? Colors.grey : Colors.green),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tombol Dokumen
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: Icon(_docFile == null ? Icons.attach_file : Icons.description, color: Colors.white),
                      label: Text(_docFile == null ? "Add PDF/Doc" : "Doc Added"),
                      style: ElevatedButton.styleFrom(backgroundColor: _docFile == null ? Colors.blueGrey : Colors.blue),
                    ),
                  ),
                ],
              ),
              if (_docName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text("File: $_docName", style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ),

              const SizedBox(height: 20),
              const Divider(),

              // --- SUBTASKS DYNAMIC ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtasks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(onPressed: _addSubtaskField, icon: const Icon(Icons.add_circle, color: Colors.indigo)),
                ],
              ),
              // List Subtask Input
              ..._subtaskControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          decoration: InputDecoration(
                            hintText: "Subtask ${idx + 1}",
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeSubtaskField(idx),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 30),

              // --- SUBMIT BUTTON ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("CREATE PROJECT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}