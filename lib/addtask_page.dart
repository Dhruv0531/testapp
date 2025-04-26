import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<String> _categories = ['College', 'Home', 'Work', 'Other'];
  String _selectedCategory = 'Other';

  // Function to pick date
  Future<void> _pickDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  // Function to pick time
  Future<TimeOfDay?> _pickTime(TimeOfDay? initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
  }

  void _saveTask() async {
    if (_titleController.text.isEmpty || _startTime == null || _endTime == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User is not authenticated');
      return;
    }

    final taskData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'duedate': Timestamp.fromDate(_dueDate),
      'starttime': _startTime!.format(context),
      'endtime': _endTime!.format(context),
      'category': _selectedCategory,
      'isCompleted': false,
      'progress': 0.0,
      'userId': user.uid,
    };

    try {
      final docRef = await FirebaseFirestore.instance.collection('tasks').add(taskData);
      await docRef.update({'id': docRef.id});

      print('Task added successfully with ID: ${docRef.id}');

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            ListTile(
              title: Text('Due Date: ${_dueDate.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDueDate,
            ),
            ListTile(
              title: Text('Start Time: ${_startTime?.format(context) ?? 'Select'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final pickedTime = await _pickTime(_startTime);
                if (pickedTime != null) setState(() => _startTime = pickedTime);
              },
            ),
            ListTile(
              title: Text('End Time: ${_endTime?.format(context) ?? 'Select'}'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final pickedTime = await _pickTime(_endTime);
                if (pickedTime != null) setState(() => _endTime = pickedTime);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTask,
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
