// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

const String apiKey = '387b5adc-2bc0-4b6b-a1a9-b52a7a5ed129';
const String baseUrl = 'https://todoapp-api.apps.k8s.gu.se';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoModel()..loadTodos(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TIG333 TODO',
      theme: ThemeData(useMaterial3: true),
      home: const TodoPage(),
    );
  }
}

class Todo {
  final String id;
  final String title;
  final bool done;
  const Todo({required this.id, required this.title, required this.done});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool,
  );
}

enum Filter { all, done, undone }

class TodoModel extends ChangeNotifier {
  final List<Todo> _todos = [];
  Filter _filter = Filter.all;
  bool _loading = false;
  String? _errorMessage;

  // Getters
  List<Todo> get todos => List.unmodifiable(_todos);
  Filter get filter => _filter;
  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;

  List<Todo> get visibleTodos {
    switch (_filter) {
      case Filter.done:
        return _todos.where((t) => t.done).toList();
      case Filter.undone:
        return _todos.where((t) => !t.done).toList();
      case Filter.all:
      default:
        return _todos;
    }
  }

  Uri _url(String path) => Uri.parse('$baseUrl$path?key=$apiKey');

  Future<void> loadTodos() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await http
          .get(_url('/todos'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      final List data = jsonDecode(response.body) as List;
      _todos
        ..clear()
        ..addAll(data.map((e) => Todo.fromJson(e)));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(Filter newFilter) async {
    _filter = newFilter;
    notifyListeners();
  }

  /// SERVER-FIRST: uppdatera servern först, uppdatera UI efter OK-svar
  Future<void> toggleDone(Todo todo) async {
    final bool newDone = !todo.done;
    try {
      final response = await http
          .put(
            _url('/todos/${todo.id}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': todo.title, 'done': newDone}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      await loadTodos(); // håll UI i synk med servern
    } catch (e) {
      _errorMessage = 'Kunde inte uppdatera: $e';
      notifyListeners();
    }
  }

  Future<void> removeById(String id) async {
    try {
      final response = await http
          .delete(_url('/todos/$id'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception(response.body);
      }
      await loadTodos(); // hämta färsk lista
    } catch (e) {
      _errorMessage = 'Kunde inte ta bort: $e';
      notifyListeners();
    }
  }

  Future<bool> addTodo(String title) async {
    try {
      final response = await http
          .post(
            _url('/todos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': title, 'done': false}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.body);
      }
      await loadTodos();
      return true;
    } on TimeoutException {
      _errorMessage = 'Timeout';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final bool? didAdd = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTodoPage()),
    );
    if (didAdd == true) {
      await context.read<TodoModel>().loadTodos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TodoModel>();

    final Widget content = model.isLoading
        ? const Center(child: CircularProgressIndicator())
        : (model.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Fel: ${model.errorMessage}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: model.loadTodos,
                        child: const Text('Försök igen'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: model.filter == Filter.all,
                            onSelected: (_) => model.setFilter(Filter.all),
                          ),
                          ChoiceChip(
                            label: const Text('Done'),
                            selected: model.filter == Filter.done,
                            onSelected: (_) => model.setFilter(Filter.done),
                          ),
                          ChoiceChip(
                            label: const Text('Undone'),
                            selected: model.filter == Filter.undone,
                            onSelected: (_) => model.setFilter(Filter.undone),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: model.loadTodos,
                        child: model.visibleTodos.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 48),
                                  Center(child: Text('No todos yet')),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: model.visibleTodos.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final todo = model.visibleTodos[index];
                                  return ListTile(
                                    leading: Checkbox(
                                      value: todo.done,
                                      onChanged: (_) => model.toggleDone(todo),
                                    ),
                                    title: Text(
                                      todo.title,
                                      style: TextStyle(
                                        decoration: todo.done
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          model.removeById(todo.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        centerTitle: true,
        title: const Text(
          'TIG333 TODO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TodoModel>().loadTodos();
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('ADD'),
        onPressed: () => _openAdd(context),
      ),
    );
  }
}

class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});
  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final TextEditingController _textController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    final String title = _textController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final ok = await context.read<TodoModel>().addTodo(title);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
      setState(() => _error = context.read<TodoModel>().errorMessage);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSave = _textController.text.trim().isNotEmpty && !_saving;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        centerTitle: true,
        title: const Text('Add Todo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              enabled: !_saving,
              decoration: InputDecoration(
                hintText: 'What are you going to do?',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSave ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text('Fel: $_error', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
