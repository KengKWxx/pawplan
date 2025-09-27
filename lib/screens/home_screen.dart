import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final List<Map<String, dynamic>> _pets = [];
  final List<Map<String, dynamic>> _tasks = [];

  User? get _user => FirebaseAuth.instance.currentUser;

  void _addPetDialog() async {
    final nameController = TextEditingController();
    final breedController = TextEditingController();
    final ageController = TextEditingController();
    final sexController = TextEditingController();
    final colorController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.brown.shade400),
            const SizedBox(width: 8),
            const Text("Add Pet"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: breedController,
                decoration: const InputDecoration(labelText: "Breed"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
              ),
              TextField(
                controller: sexController,
                decoration: const InputDecoration(labelText: "Sex"),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(labelText: "Color"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Add"),
            onPressed: () {
              setState(() {
                _pets.add({
                  'name': nameController.text,
                  'breed': breedController.text,
                  'age': ageController.text,
                  'sex': sexController.text,
                  'color': colorController.text,
                  'owner': _user?.displayName ?? _user?.email ?? "User",
                });
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _addTaskDialog() async {
    if (_pets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a pet first.")),
      );
      return;
    }
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String? selectedPet = _pets.first['name'];
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.brown.shade400),
            const SizedBox(width: 8),
            const Text("Add Task"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: selectedPet,
                items: _pets
                    .map((pet) => DropdownMenuItem<String>(
                          value: pet['name'],
                          child: Text("${pet['name']} (${pet['owner']})"),
                        ))
                    .toList(),
                onChanged: (v) => selectedPet = v,
                decoration: const InputDecoration(labelText: "Pet"),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Task Title"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(selectedDate == null
                          ? "Pick Date"
                          : "${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}"),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Add"),
            onPressed: () {
              setState(() {
                _tasks.add({
                  'pet': selectedPet,
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': selectedDate,
                });
              });
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final name = _user?.displayName ?? _user?.email ?? "User";
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.brown.shade100,
              child: Icon(Icons.pets, color: Colors.brown.shade700, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi. $name",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade700,
                  ),
                ),
                Text(
                  "Welcome to PawPlan!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.brown.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Add Pet"),
                onPressed: _addPetDialog,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.task_alt),
                label: const Text("Add Task"),
                onPressed: _addTaskDialog,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          "My Pets",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.brown.shade700,
          ),
        ),
        if (_pets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "No pets added yet.",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
        ..._pets.map((pet) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: Icon(Icons.pets, color: Colors.brown.shade700),
                ),
                title: Text(pet['name']),
                subtitle: Text(
                    "${pet['breed']}, ${pet['age']}, ${pet['sex']}, ${pet['color']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF8B4513)),
                  onPressed: () {
                    // TODO: Edit pet info
                  },
                ),
              ),
            )),
        const SizedBox(height: 24),
        Text(
          "Tasks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.brown.shade700,
          ),
        ),
        if (_tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "No tasks added yet.",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
        ..._tasks.map((task) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: Icon(Icons.task_alt, color: Colors.brown.shade700),
                ),
                title: Text(task['title']),
                subtitle: Text(
                    "Pet: ${task['pet']}\n${task['desc']}${task['date'] != null ? "\nDate: ${task['date'].day}/${task['date'].month}/${task['date'].year}" : ""}"),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF8B4513)),
                  onPressed: () {
                    // TODO: Mark as done
                  },
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPets() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "My Pets",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.brown.shade700,
          ),
        ),
        if (_pets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "No pets added yet.",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
        ..._pets.map((pet) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: Icon(Icons.pets, color: Colors.brown.shade700),
                ),
                title: Text(pet['name']),
                subtitle: Text(
                    "${pet['breed']}, ${pet['age']}, ${pet['sex']}, ${pet['color']}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF8B4513)),
                  onPressed: () {
                    // TODO: Edit pet info
                  },
                ),
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Pet"),
          onPressed: _addPetDialog,
        ),
      ],
    );
  }

  Widget _buildTasks() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          "Tasks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.brown.shade700,
          ),
        ),
        if (_tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              "No tasks added yet.",
              style: TextStyle(color: Colors.brown.shade400),
            ),
          ),
        ..._tasks.map((task) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  child: Icon(Icons.task_alt, color: Colors.brown.shade700),
                ),
                title: Text(task['title']),
                subtitle: Text(
                    "Pet: ${task['pet']}\n${task['desc']}${task['date'] != null ? "\nDate: ${task['date'].day}/${task['date'].month}/${task['date'].year}" : ""}"),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF8B4513)),
                  onPressed: () {
                    // TODO: Mark as done
                  },
                ),
              ),
            )),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Task"),
          onPressed: _addTaskDialog,
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 48, color: Colors.brown.shade400),
          const SizedBox(height: 12),
          Text(
            "Settings Coming Soon",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown.shade500,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_navIndex) {
      case 1:
        body = _buildPets();
        break;
      case 2:
        body = _buildTasks();
        break;
      case 3:
        body = _buildSettings();
        break;
      default:
        body = _buildHome();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5DC),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Icon(Icons.pets, color: Colors.brown.shade600),
            ),
            const SizedBox(width: 12),
            Text(
              "PawPlan",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF8B4513),
        unselectedItemColor: Colors.brown.shade300,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Pets"),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}