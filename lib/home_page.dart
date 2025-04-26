import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addtask_page.dart';
import 'calendar_page.dart';
import 'task_model.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required String userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateTime _selectedDate = DateTime.now();
  int _currentNavIndex = 0;
  String _selectedCategory = "All";
  List<String> categories = ["All", "College", "Home", "Work", "Other"];
  String userName = "Loading...";

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  Stream<List<Task>> _fetchTasks(String category) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    Query query = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: userId);

    if (category != "All") {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final taskList =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Task(
              id: doc.id,
              title: data['title'] ?? 'Untitled',
              description: data['description'] ?? '',
              date: (data['duedate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              category: data['category'] ?? 'Others',
              isCompleted: data['completed'] ?? false,
              progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

      taskList.sort(
        (a, b) => a.date.compareTo(b.date),
      ); // Sort tasks by due date
      return taskList;
    });
  }

  Future<void> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('user_info')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['username'] ?? "User";
          });
        }
      } catch (e) {
        print("Error fetching username: $e");
      }
    }
  }

  void _navigateToAddTaskPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskPage()),
    );
  }

  void _navigateToCalendarPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CalendarPage()),
    );
  }

  double _calculateProgress(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildDateDisplay(),
              const SizedBox(height: 20),
              _buildCategorySubfolders(),
              const SizedBox(height: 20),
              StreamBuilder<List<Task>>(
                stream: _fetchTasks(_selectedCategory),
                builder: (context, snapshot) {
                  final tasks = snapshot.data ?? [];
                  final progress = _calculateProgress(tasks);

                  return _buildTaskOverview(progress);
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<Task>>(
                  stream: _fetchTasks(_selectedCategory),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading tasks'));
                    }

                    final tasks = snapshot.data ?? [];

                    if (tasks.isEmpty) {
                      return const Center(
                        child: Text(
                          "No tasks yet 🎯",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(task);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });

            if (index == 1) _navigateToCalendarPage();
            if (index == 2) _navigateToAddTaskPage();
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(userName: userName),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: "Calendar",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Add"),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
          selectedItemColor: Colors.purple,
          unselectedItemColor: Colors.grey,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskPage,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $userName!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Welcome back!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        Row(
          children: [
            _circleIcon(Icons.notifications_none_rounded),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(userName: userName),
                  ),
                );
              },
              child: _circleIcon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateDisplay() {
    return Row(
      children: [
        Text(
          _getWeekDayName(_selectedDate.weekday),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          "${_selectedDate.day} ${_getMonthName(_selectedDate.month)}",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCategorySubfolders() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _selectedCategory == category
                        ? Colors.purple
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color:
                        _selectedCategory == category
                            ? Colors.white
                            : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskOverview(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                "${(progress * 100).toStringAsFixed(0)}% completed",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                progress >= 1.0 ? "All tasks done! 🎉" : "Keep going!",
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(
            height: 70,
            width: 70,
            child: TweenAnimationBuilder(
              tween: Tween(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder:
                  (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.grey : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _getPriority(task.date),
                  style: TextStyle(
                    color:
                        task.date.isBefore(DateTime.now())
                            ? Colors.red
                            : task.date.isBefore(
                              DateTime.now().add(const Duration(days: 7)),
                            )
                            ? Colors.orange
                            : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Due: ${_formatDueDate(task.date)}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(task.description),
        trailing: Checkbox(
          value: task.isCompleted,
          onChanged: (bool? value) async {
            if (value != null) {
              await FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(task.id)
                  .update({'completed': value});
              if (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Task Completed!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _getPriority(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) return "High";
    if (dueDate.isBefore(now.add(const Duration(days: 7)))) return "Medium";
    return "Low";
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.purple),
    );
  }

  String _getWeekDayName(int dayIndex) {
    const weekdays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];
    return weekdays[dayIndex - 1];
  }

  String _getMonthName(int monthIndex) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[monthIndex - 1];
  }
}
