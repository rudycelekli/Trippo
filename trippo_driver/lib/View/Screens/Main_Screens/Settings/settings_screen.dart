import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../Routes/routes.dart';

/// Settings Screen
/// Manage provider preferences, availability, and account settings

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isAvailable = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  double _workRadius = 15.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAvailabilitySection(),
          const SizedBox(height: 24),
          _buildNotificationsSection(),
          const SizedBox(height: 24),
          _buildWorkPreferencesSection(),
          const SizedBox(height: 24),
          _buildAccountSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _isAvailable,
            onChanged: (value) {
              setState(() => _isAvailable = value);
              _updateAvailability(value);
            },
            title: const Text(
              'Available for Jobs',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _isAvailable
                  ? 'You are currently accepting jobs'
                  : 'You are offline and not receiving job requests',
              style: TextStyle(
                color: _isAvailable ? Colors.green : Colors.grey[400],
                fontSize: 12,
              ),
            ),
            activeColor: Colors.green,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.schedule, color: Colors.blue),
            title: const Text(
              'Manage Availability Schedule',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Set your working hours',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              context.pushNamed(Routes().availability);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
            },
            title: const Text(
              'Push Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Receive notifications for new jobs',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
            },
            title: const Text(
              'Email Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Receive email updates',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Work Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Work Radius',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '${_workRadius.toInt()} miles',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _workRadius,
            min: 5,
            max: 50,
            divisions: 9,
            activeColor: Colors.blue,
            inactiveColor: const Color(0xFF2C2C2C),
            onChanged: (value) {
              setState(() => _workRadius = value);
            },
          ),
          Text(
            'Jobs within this radius will be shown to you',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              context.pushNamed(Routes().profile);
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.orange),
            title: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              _showChangePasswordDialog();
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.green),
            title: const Text(
              'Payment Methods',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment settings coming soon')),
              );
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text(
              'App Version',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              '1.0.0',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.purple),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening privacy policy...')),
              );
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.green),
            title: const Text(
              'Terms of Service',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening terms of service...')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateAvailability(bool available) async {
    // TODO: Update provider availability in Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          available
              ? '✅ You are now available for jobs'
              : '⏸️ You are now offline',
        ),
        backgroundColor: available ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password change feature coming soon'),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.goNamed(Routes().login);
      }
    }
  }
}
