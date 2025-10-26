import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'home_tab.dart';
import 'pets_tab.dart';
import 'tasks_tab.dart';
import 'settings_tab.dart';
import '../services/pet_service.dart';
import '../services/task_service.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = FirebaseAuth.instance;
  User? get user => auth.currentUser;
  int _nav = 0;

  // ---------------- Helper Methods ----------------
  // removed unused _confirm

  Widget _body() {
    if (user == null) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first')));
    }

    switch (_nav) {
      case 1:
        return PetsTab(user: user!, onAddPet: () => PetService.showAddPetDialog(context));
      case 2:
        return TasksTab(user: user!, onAddTask: () => TaskService.showAddTaskDialog(context));
      case 3:
        return SettingsTab(user: user!);
      default:
        return HomeTab(
          user: user!,
          onAddPet: () => PetService.showAddPetDialog(context),
          onAddTask: () => TaskService.showAddTaskDialog(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        title: Text('PawPlan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A3A16))),
        actions: [
          // Language toggle button (placed first)
          Builder(builder: (context) {
            return IconButton(
              tooltip: 'Language',
              onPressed: () async {
                // Toggle language via LocaleService using Inherited Provider
                // Import kept indirectly through LanguageCornerButton file; avoid direct import here
                // Use a simple dialog to switch quickly
                final localeService = Provider.of<LocaleService>(context, listen: false);
                final isThai = localeService.locale.languageCode == 'th';
                await localeService.setLanguageCode(isThai ? 'en' : 'th');
              },
              icon: Text(
                Provider.of<LocaleService>(context).locale.languageCode == 'th' ? '🇹🇭' : '🇺🇸',
                style: const TextStyle(fontSize: 18),
              ),
              color: const Color(0xFF5A3A16),
            );
          }),
          IconButton(
            tooltip: AppLocalizations.of(context)?.calendar ?? 'Calendar',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
            icon: const Icon(Icons.calendar_month),
            color: const Color(0xFF5A3A16),
          ),
          if (_nav != 3)
            IconButton(
              tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
              onPressed: () => setState(() => _nav = 3),
              icon: const Icon(Icons.settings),
              color: const Color(0xFF5A3A16),
            ),
        ],
      ),
      body: _body(),
      floatingActionButton: _nav == 1
          ? FloatingActionButton(
              onPressed: () => PetService.showAddPetDialog(context),
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : _nav == 2
              ? FloatingActionButton(
                  onPressed: () => TaskService.showAddTaskDialog(context),
                  backgroundColor: Colors.brown.shade400,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.task),
                )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _nav,
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.brown.shade300,
        onTap: (i) => setState(() => _nav = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: AppLocalizations.of(context)?.home ?? 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.pets), label: AppLocalizations.of(context)?.pets ?? 'Pets'),
          BottomNavigationBarItem(icon: const Icon(Icons.task_alt), label: AppLocalizations.of(context)?.tasks ?? 'Tasks'),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: AppLocalizations.of(context)?.settings ?? 'Settings'),
        ],
      ),
    );
  }
}