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
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(id: json['id'], title: json['title'], done: json['done']);
  }
}

enum Filter { all, done, undone }

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Todo> _todos = [];
  Filter _filter = Filter.all;
  bool _loading = true;
  String? _error;

  Uri _u(String path) => Uri.parse('$baseUrl$path?key=$apiKey');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .get(_u('/todos'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception(res.body);
      final list = (jsonDecode(res.body) as List)
          .map((e) => Todo.fromJson(e))
          .toList();
      setState(() => _todos = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Todo t) async {
    final v = !t.done;
    setState(() => t.done = v);
    try {
      final res = await http.put(
        _u('/todos/${t.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': t.title, 'done': v}),
      );
      if (res.statusCode != 200) throw Exception(res.body);
    } catch (_) {
      setState(() => t.done = !v);
    }
  }

  Future<void> _remove(Todo t) async {
    final b = t;
    setState(() => _todos.remove(t));
    try {
      final res = await http.delete(_u('/todos/${b.id}'));
      if (res.statusCode != 200) throw Exception(res.body);
    } catch (_) {
      setState(() => _todos.add(b));
    }
  }

  List<Todo> get _visible {
    if (_filter == Filter.done) return _todos.where((t) => t.done).toList();
    if (_filter == Filter.undone) return _todos.where((t) => !t.done).toList();
    return _todos;
  }

  Future<void> _goToAdd() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTodoPage()),
    );
    if (ok == true) await _load();
  }

  void _setFilter(Filter f) => setState(() => _filter = f);

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 8),
                      Text('Fel: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _load,
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
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('ADD'),
        onPressed: _goToAdd,
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
  final TextEditingController _c = TextEditingController();
  bool _saving = false;
  String? _error;

  Uri _u(String path) => Uri.parse('$baseUrl$path?key=$apiKey');

  Future<void> _save() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await http
          .post(
            _u('/todos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'title': text, 'done': false}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 201)
        throw Exception(res.body);
      if (mounted) Navigator.pop(context, true);
    } on TimeoutException {
      setState(() {
        _saving = false;
        _error = 'Timeout';
      });
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _c.text.trim().isNotEmpty && !_saving;
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
              controller: _c,
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
