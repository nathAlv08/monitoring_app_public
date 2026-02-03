import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/database_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TaskModel> _getTasksForDay(DateTime day, List<TaskModel> allTasks) {
    return allTasks.where((task) {
      return isSameDay(task.deadline, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Timeline"), centerTitle: true),
      body: StreamBuilder<List<TaskModel>>(
        stream: DatabaseService().getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allTasks = snapshot.data ?? [];
          final selectedTasks = _getTasksForDay(_selectedDay!, allTasks);

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) => _getTasksForDay(day, allTasks),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                    markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(child: Text("No tasks on ${DateFormat('d MMM').format(_selectedDay!)}"))
                    : ListView.builder(
                  itemCount: selectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = selectedTasks[index];
                    return ListTile(
                      leading: Icon(Icons.circle, size: 12, color: task.isCompleted ? Colors.green : Colors.orange),
                      title: Text(task.title),
                      subtitle: Text(task.priority),
                      trailing: task.isCompleted ? const Icon(Icons.check, color: Colors.green) : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}