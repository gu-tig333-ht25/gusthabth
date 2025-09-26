import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiKey = '387b5adc-2bc0-4b6b-a1a9-b52a7a5ed129';
const String baseUrl = 'https://todoapp-api.apps.k8s.gu.se';

void main() => runApp(const MyApp());

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
  bool done;
  Todo({required this.id, required this.title, required this.done});

  factory Todo.fromJson(Map<String, dynamic> json) =>
      Todo(id: json['id'], title: json['title'], done: json['done']);
}

enum Filter { all, done, undone }

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();

  List<Todo> _todos = [];
  Filter _filter = Filter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFromServer();
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path?key=$apiKey');

  Future<void> _loadFromServer() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(_u('/todos'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception(res.body);
      final data = jsonDecode(res.body) as List;
      setState(() {
        _todos = data.map((e) => Todo.fromJson(e)).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addTodo() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      final res = await http.post(
        _u('/todos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': text, 'done': false}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception(res.body);
      }
      _controller.clear();
      await _loadFromServer();
    } catch (_) {}
  }

  Future<void> _toggle(Todo t) async {
    final newVal = !t.done;
    setState(() => t.done = newVal);
    try {
      final res = await http.put(
        _u('/todos/${t.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': t.title, 'done': newVal}),
      );
      if (res.statusCode != 200) throw Exception(res.body);
    } catch (_) {
      setState(() => t.done = !newVal);
    }
  }

  Future<void> _remove(Todo t) async {
    setState(() => _todos.remove(t));
    try {
      final res = await http.delete(_u('/todos/${t.id}'));
      if (res.statusCode != 200) throw Exception(res.body);
    } catch (_) {
      setState(() => _todos.add(t));
    }
  }

  List<Todo> get _visible {
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

  void _setFilter(Filter f) => setState(() => _filter = f);

  @override
  Widget build(BuildContext context) {
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
            onPressed: _loadFromServer,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
                ? Center(child: Text('Error: $_error'))
                : Stack(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                hintText: 'What are you going to do?',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSubmitted: (_) => _addTodo(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _filter == Filter.all,
                                  onSelected: (_) => _setFilter(Filter.all),
                                ),
                                ChoiceChip(
                                  label: const Text('Done'),
                                  selected: _filter == Filter.done,
                                  onSelected: (_) => _setFilter(Filter.done),
                                ),
                                ChoiceChip(
                                  label: const Text('Undone'),
                                  selected: _filter == Filter.undone,
                                  onSelected: (_) => _setFilter(Filter.undone),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _visible.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final t = _visible[i];
                                return ListTile(
                                  leading: Checkbox(
                                    value: t.done,
                                    onChanged: (_) => _toggle(t),
                                  ),
                                  title: Text(
                                    t.title,
                                    style: TextStyle(
                                      decoration: t.done
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _remove(t),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: FloatingActionButton.extended(
                            icon: const Icon(Icons.add),
                            label: const Text('ADD'),
                            onPressed: _addTodo,
                          ),
                        ),
                      ),
                    ],
                  )),
    );
  }
}
