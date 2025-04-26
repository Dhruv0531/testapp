import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String userName;
  const SettingsPage({super.key, required this.userName});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  DateTime _dob = DateTime(2000, 1, 1);
  bool _isDarkMode = false;
  bool _enableNotifications = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: "user@example.com");
    _phoneController = TextEditingController(text: "+1 234 567 8900");
    _loadPreferences();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Load preferences (dark mode and notification settings)
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    });
  }

  // Save preferences to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('enableNotifications', _enableNotifications);
  }

  // Fetch user details from Firestore
  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('user_info')
            .doc('users')
            .collection(userId)
            .doc('details')
            .get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            _emailController.text = data['email'] ?? user.email!;
            _phoneController.text = data['phone'] ?? '+1 234 567 8900';
            _dob = (data['dob'] as Timestamp).toDate();
          });
        }
      } catch (e) {
        print('Error fetching user details: $e');
      }
    }
  }

  // Save user details to Firestore
  Future<void> _saveUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      try {
        await FirebaseFirestore.instance
            .collection('user_info')
            .doc('users')
            .collection(userId)
            .doc('details')
            .set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'dob': _dob,
        });
      } catch (e) {
        print('Error saving user details: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light Theme'),
              leading: const Icon(Icons.light_mode),
              onTap: () async {
                await _setTheme(false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Dark Theme'),
              leading: const Icon(Icons.dark_mode),
              onTap: () async {
                await _setTheme(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setTheme(bool isDark) async {
    setState(() => _isDarkMode = isDark);
    await _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildProfileSection(),
              const SizedBox(height: 30),
              _buildPersonalInfoSection(),
              const SizedBox(height: 30),
              _buildAppPreferencesSection(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple.withOpacity(0.2),
            child: const Icon(Icons.person, size: 50, color: Colors.deepPurple),
          ),
          const SizedBox(height: 12),
          Text(
            widget.userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Active User',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_nameController, 'Full Name', Icons.person),
        _buildTextField(_emailController, 'Email Address', Icons.email),
        _buildTextField(_phoneController, 'Phone Number', Icons.phone),
        const SizedBox(height: 15),
        _buildDatePicker(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.deepPurple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text("${_dob.day}/${_dob.month}/${_dob.year}"),
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Dark Mode'),
          value: _isDarkMode,
          onChanged: (value) async {
            setState(() => _isDarkMode = value);
            await _savePreferences();
          },
        ),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          value: _enableNotifications,
          onChanged: (value) async {
            setState(() => _enableNotifications = value);
            await _savePreferences();
          },
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('App Theme'),
          onTap: _showThemeDialog,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings saved successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              await _saveUserDetails(); // Save updated details to Firestore
              await _savePreferences(); // Save updated preferences
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: _logout,
          child: const Text('Logout', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
