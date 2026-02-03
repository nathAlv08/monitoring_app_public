import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import 'add_task_page.dart';
import 'edit_task_page.dart';
import 'profile_page.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _quote = "Loading daily motivation...";
  String _filterPriority = 'All';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchQuote();
  }

  // --- LOGIKA REFRESH DATA USER ---
  Future<void> _refreshData() async {
    // 1. Paksa Firebase cek server untuk data user terbaru
    await FirebaseAuth.instance.currentUser?.reload();

    // 2. Simpan user terbaru ke variabel
    final updatedUser = FirebaseAuth.instance.currentUser;

    // 3. Update Quote juga
    String newQuote = await ApiService().getMotivationalQuote();

    if (mounted) {
      setState(() {
        _currentUser = updatedUser; // Ini akan memicu UI ganti nama
        _quote = newQuote;
      });
    }
  }

  void _fetchQuote() async {
    String q = await ApiService().getMotivationalQuote();
    if (mounted) setState(() => _quote = q);
  }

  void _showFullQuoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.format_quote, color: Colors.orange), SizedBox(width: 8), Text("Daily Inspiration")]),
        content: Text(_quote, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!"))],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String base64String) {
    try {
      Uint8List bytes = base64Decode(base64String);
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 400, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(onPressed: () => Navigator.pop(context), backgroundColor: Colors.white, child: const Icon(Icons.close, color: Colors.black))
            ],
          ),
        ),
      );
    } catch (e) { print("Error image: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    // Pakai variable state _currentUser, jangan FirebaseAuth.instance langsung biar reaktif
    final user = _currentUser;

    // Fallback kalau nama masih null
    final String displayName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user!.displayName!
        : (user?.email?.split('@')[0] ?? 'User');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String todayDate = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      body: StreamBuilder<List<TaskModel>>(
        stream: DatabaseService().getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allTasks = snapshot.data ?? [];

          List<TaskModel> filteredTasks = allTasks;
          if (_filterPriority != 'All') {
            filteredTasks = allTasks.where((t) => t.priority == _filterPriority).toList();
          }

          double totalProgressSum = 0;
          for (var task in allTasks) {
            if (task.subtasks.isEmpty) {
              totalProgressSum += task.isCompleted ? 1.0 : 0.0;
            } else {
              int doneSub = task.subtasks.where((s) => s['isDone'] == true).length;
              totalProgressSum += doneSub / task.subtasks.length;
            }
          }
          double overallProgress = allTasks.isEmpty ? 0 : totalProgressSum / allTasks.length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isDark ? [const Color(0xFF6C63FF), const Color(0xFF2A2D3E)] : [Colors.indigo, Colors.blueAccent]),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // NAMA USER (Updated)
                              Text("Hi, $displayName 👋", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(todayDate, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CalendarPage())),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.edit_calendar, size: 16, color: Colors.indigo),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _showFullQuoteDialog(context),
                                child: Text(_quote, style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        // PROFILE BUTTON (DENGAN REFRESH LOGIC)
                        GestureDetector(
                          onTap: () async {
                            // 1. Buka Profile Page
                            await Navigator.push(context, MaterialPageRoute(builder: (c) => const ProfilePage()));
                            // 2. Setelah kembali, Refresh Data!
                            await _refreshData();
                          },
                          child: CircleAvatar(
                            radius: 22, backgroundColor: Colors.white,
                            child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Overall Productivity", style: TextStyle(color: Colors.white)),
                        Text("${(overallProgress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: overallProgress, backgroundColor: Colors.white24, color: Colors.greenAccent, minHeight: 8, borderRadius: BorderRadius.circular(10)),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['All', 'High', 'Medium', 'Low'].map((filter) {
                    bool isSelected = _filterPriority == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _filterPriority = filter),
                        selectedColor: Colors.indigo,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // List Tugas
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshData,
                  child: filteredTasks.isEmpty
                      ? const Center(child: Text("No tasks found."))
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) => _buildProjectCard(context, filteredTasks[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddTaskPage())),
        label: const Text("New Project"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // WIDGET CARD (Tetap sama)
  Widget _buildProjectCard(BuildContext context, TaskModel task) {
    int totalSub = task.subtasks.length;
    int doneSub = task.subtasks.where((s) => s['isDone'] == true).length;
    double progress = totalSub == 0 ? (task.isCompleted ? 1.0 : 0.0) : (doneSub / totalSub);
    Color priorityColor = task.priority == 'High' ? Colors.red : (task.priority == 'Medium' ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: task.subtasks.isEmpty
            ? Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: task.isCompleted,
            activeColor: priorityColor,
            shape: const CircleBorder(),
            onChanged: (val) {
              DatabaseService().toggleTaskComplete(task.id, val ?? false);
            },
          ),
        )
            : CircularProgressIndicator(value: progress, color: priorityColor, backgroundColor: Colors.grey[200]),
        title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: Text("Deadline: ${DateFormat('d MMM').format(task.deadline)}"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), border: Border.all(color: priorityColor), borderRadius: BorderRadius.circular(6)),
          child: Text(task.priority, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        children: [
          ...task.subtasks.asMap().entries.map((entry) {
            int idx = entry.key;
            Map<String, dynamic> sub = entry.value;
            return ListTile(
              dense: true,
              leading: Checkbox(value: sub['isDone'], activeColor: priorityColor, onChanged: (val) => DatabaseService().toggleSubtask(task.id, List.from(task.subtasks), idx)),
              title: Text(sub['title'], style: TextStyle(decoration: sub['isDone'] ? TextDecoration.lineThrough : null)),
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(icon: const Icon(Icons.edit, size: 18), label: const Text("Edit"), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditTaskPage(task: task)))),
                if (task.imageUrl != null && task.imageUrl!.isNotEmpty)
                  IconButton(icon: const Icon(Icons.image, color: Colors.blue), onPressed: () => _showImageDialog(context, task.imageUrl!)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => DatabaseService().deleteTask(task.id)),
              ],
            ),
          )
        ],
      ),
    );
  }
}