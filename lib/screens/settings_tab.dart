import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../services/user_service.dart';
import '../widgets/local_image_widget.dart';
import '../services/supabase_storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/notification_service.dart';
// Theme switching UI removed

class SettingsTab extends StatefulWidget {
  final User user;

  const SettingsTab({
    super.key,
    required this.user,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final auth = FirebaseAuth.instance;
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.displayName ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      child: Column(
        children: [
        // Profile Card
        _sectionCard(
          child: ListTile(
          leading: _buildUserAvatar(),
          title: Text(widget.user.email ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(widget.user.displayName?.isEmpty ?? true
              ? 'No display name'
              : widget.user.displayName!),
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.brown),
            onPressed: () => UserService.editUserProfileDialog(context, widget.user),
          ),
        )),
        const SizedBox(height: 12),
        _sectionCard(
          padding: const EdgeInsets.all(16),
          child: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Display Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        )),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('บันทึกชื่อ'),
          style: _secondaryBtn(),
          onPressed: () async {
            if (nameController.text.trim().isEmpty) return;
            await widget.user.updateDisplayName(nameController.text.trim());
            await widget.user.reload();
            setState(() {});
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('อัปเดตแล้ว')));
          },
        ),
        const SizedBox(height: 28),
        // Language control removed (moved to AppBar)
        const SizedBox(height: 0),
        if (kIsWeb)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Notifications are not supported on Web.\nPlease test on Android/iOS device.',
              style: TextStyle(fontSize: 12),
            ),
          )
        else ...[
          // Appearance/theme controls removed
          _sectionHeader('Notifications'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('ทดสอบทันที'),
                  style: _secondaryBtn(),
                  onPressed: () async {
                    await NotificationService.showNow(
                      id: 1001,
                      title: 'PawPlan',
                      body: 'ทดสอบแจ้งเตือนทันที',
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('ใน 15 วินาที'),
                  style: _secondaryBtn(),
                  onPressed: () async {
                    final dt = DateTime.now().add(const Duration(seconds: 15));
                    await NotificationService.scheduleAt(
                      id: 1002, title: 'PawPlan', body: 'ทดสอบแจ้งเตือน (+15 วิ)', dateTime: dt,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ตั้งแจ้งเตือนใน 15 วิแล้ว')));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.alarm_on),
            label: const Text('อนุญาต Alarms & reminders'),
            style: _secondaryBtn(),
            onPressed: () async {
              await NotificationService.openExactAlarmSettings();
              final s = await NotificationService.debugStatus();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Exact allowed: ${s['areExactAlarmsAllowed']}, Notif: ${s['areNotificationsEnabled']}')),

              );
            },
          ),
          const SizedBox(height: 28),
        ],
        
        ElevatedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('ออกจากระบบ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () async {
            await auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
        Text(
          'Long press pet/task to delete.\nTap check to toggle task.',
          style: TextStyle(fontSize: 12, color: Colors.brown.shade500),
        ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final user = widget.user;
    if (user.photoURL != null && user.photoURL!.isNotEmpty) {
      if (SupabaseStorageService.isSupabaseStorageUrl(user.photoURL!)) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.brown.shade100,
          child: ClipOval(
            child: Image.network(
              user.photoURL!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, color: Colors.brown.shade700, size: 24);
              },
            ),
          ),
        );
      } else if (user.photoURL!.startsWith('pet_image_')) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.brown.shade100,
          child: ClipOval(
            child: LocalImageWidget(
              imageKey: user.photoURL!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }
    
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.brown.shade100,
      child: Icon(Icons.person, color: Colors.brown.shade700, size: 24),
    );
  }

  ButtonStyle _secondaryBtn() => ElevatedButton.styleFrom(
        backgroundColor: Colors.brown.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  // ---------- UI helpers ----------
  Widget _sectionCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown.shade700)),
    );
  }

  // Language segment removed; language is now changed from the AppBar

  // Theme chips removed
}
