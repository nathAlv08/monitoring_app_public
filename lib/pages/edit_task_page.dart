import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class EditTaskPage extends StatefulWidget {
  final TaskModel task;
  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late String _selectedPriority;

  // Subtasks
  List<TextEditingController> _subtaskControllers = [];

  // Files
  File? _newImageFile;
  File? _newDocFile;
  String? _newDocName;

  bool _isLoading = false;
  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.deadline;
    _selectedPriority = widget.task.priority;
    if (!_priorities.contains(_selectedPriority)) _selectedPriority = 'Medium';

    // Load Existing Subtasks
    for (var sub in widget.task.subtasks) {
      _subtaskControllers.add(TextEditingController(text: sub['title']));
    }
  }

  void _addSubtaskField() {
    setState(() => _subtaskControllers.add(TextEditingController()));
  }

  void _removeSubtaskField(int index) {
    setState(() => _subtaskControllers.removeAt(index));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 25);
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      int size = await file.length();
      if (size > 500 * 1024) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File max 500KB!")));
        return;
      }
      setState(() {
        _newDocFile = file;
        _newDocName = result.files.single.name;
      });
    }
  }

  Future<void> _submitUpdates() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Rebuild Subtasks
      List<Map<String, dynamic>> updatedSubtasks = [];
      for (int i = 0; i < _subtaskControllers.length; i++) {
        String text = _subtaskControllers[i].text.trim();
        if (text.isNotEmpty) {
          // Pertahankan status isDone lama jika index sama, atau reset false kalau baru
          bool isDone = (i < widget.task.subtasks.length) ? widget.task.subtasks[i]['isDone'] : false;
          updatedSubtasks.add({'title': text, 'isDone': isDone});
        }
      }

      await DatabaseService().updateTask(
        taskId: widget.task.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        deadline: _selectedDate,
        priority: _selectedPriority,
        subtasks: updatedSubtasks,

        imagePath: _newImageFile?.path,
        oldImageUrl: widget.task.imageUrl,

        filePath: _newDocFile?.path,
        fileName: _newDocName ?? widget.task.fileName,
        oldFileData: widget.task.fileData,
        oldFileName: widget.task.fileName,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task Updated!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic untuk display file name
    String displayFileName = _newDocName ?? widget.task.fileName ?? "No Document";

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Project")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // Attachment Section
              const Text("Attachments", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_newImageFile != null ? "New Photo" : "Change Photo"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.attach_file),
                      label: const Text("Change Doc"),
                    ),
                  ),
                ],
              ),
              Text("Current Doc: $displayFileName", style: const TextStyle(color: Colors.grey, fontSize: 12)),

              const SizedBox(height: 20),
              const Divider(),

              // Subtasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Edit Subtasks", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _addSubtaskField, icon: const Icon(Icons.add_circle, color: Colors.indigo)),
                ],
              ),
              ..._subtaskControllers.asMap().entries.map((entry) {
                int idx = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: entry.value, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 10)))),
                      IconButton(onPressed: () => _removeSubtaskField(idx), icon: const Icon(Icons.delete, color: Colors.red)),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitUpdates,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE CHANGES"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}