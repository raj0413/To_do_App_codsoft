import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(),
      child: MaterialApp(
        title: 'To-Do List App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const TaskListScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        title: const Text('To-Do List'),
        backgroundColor: Colors.blue[400],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Stack(
          children: [
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return ListView.builder(
                  itemCount: taskProvider.tasks.length,
                  itemBuilder: (context, index) {
                    final task = taskProvider.tasks[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          task.name,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            taskProvider.toggleTaskCompletion(index);
                          },
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Edit Task',
                              child: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showTaskDialog(context, taskProvider, task, index);
                                },
                              ),
                            ),
                            Tooltip(
                              message: 'Delete Task',
                              child: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  taskProvider.deleteTask(index);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Positioned(
               bottom: 18,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                  onPressed: () {
                    _showGuide(context);
                  },
                  child: const Icon(Icons.help),
                ),
                SizedBox(height: 20,),
                  FloatingActionButton(onPressed:() {
              _showTaskDialog(context, context.read<TaskProvider>(), null, null);
                      },
                  child: const Icon(Icons.add),
                  ),
                  
                ],
              ),
            ),
            // Guide button
            
          ],
        ),
      ),
     
    );
  }

  void _showTaskDialog(BuildContext context, TaskProvider taskProvider, Task? task, int? index) {
    final TextEditingController controller = TextEditingController(
      text: task != null ? task.name : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(task == null ? 'Add Task' : 'Edit Task'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Task name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (task == null) {
                  taskProvider.addTask(controller.text);
                } else {
                  taskProvider.editTask(index!, controller.text);
                }
                Navigator.of(context).pop();
              },
              child: Text(task == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _showGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Guide'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• To add a new task, click the "Add" button at the bottom right.'),
              Text('• To edit a task, click the "Edit" icon next to the task.'),
              Text('• To delete a task, click the "Delete" icon next to the task.'),
              Text('• To mark a task as completed, check the checkbox next to the task.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class Task {
  String name;
  bool isCompleted;

  Task({required this.name, this.isCompleted = false});

  // Task object to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isCompleted': isCompleted,
    };
  }

  // Create a Task from a Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      name: map['name'],
      isCompleted: map['isCompleted'],
    );
  }
}

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  TaskProvider() {
    _loadTasks();
  }

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      List<dynamic> tasksJson = json.decode(tasksString);
      _tasks.clear();
      _tasks.addAll(tasksJson.map((taskMap) => Task.fromMap(taskMap)).toList());
      notifyListeners();
    }
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> tasksJson = _tasks.map((task) => task.toMap()).toList();
    String tasksString = json.encode(tasksJson);
    prefs.setString('tasks', tasksString);
  }

  void addTask(String name) {
    _tasks.add(Task(name: name));
    _saveTasks();
    notifyListeners();
  }

  void editTask(int index, String newName) {
    _tasks[index].name = newName;
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(int index) {
    _tasks[index].isCompleted = !_tasks[index].isCompleted;
    _saveTasks();
    notifyListeners();
  }
}
