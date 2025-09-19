import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TIG333 TODO",
      theme: ThemeData(useMaterial3: true),
      home: const TodoPage(),
    );
  }
}

class Todo {
  String title;
  bool done;
  Todo(this.title, this.done);
}

enum Filter { all, done, undone }

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();

  // Startdata
  final List<Todo> _todos = [
    Todo('Write a book', false),
    Todo('Do homework', false),
    Todo('Tidy room', true),
    Todo('Watch TV', false),
    Todo('Nap', false),
    Todo('Shop groceries', false),
    Todo('Have fun', false),
    Todo('Meditate', false),
  ];

  Filter _filter = Filter.all;

  List<Todo> get _visibleTodos {
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

  void _addTodo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _todos.add(Todo(text, false));
      _controller.clear();
    });
  }

  void _toggleDone(Todo t) {
    setState(() => t.done = !t.done);
  }

  void _remove(Todo t) {
    setState(() => _todos.remove(t));
  }

  void _setFilter(Filter f) {
    setState(() => _filter = f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        centerTitle: true,
        title: const Text(
          "TIG333 TODO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              // Inputfält (för att lägga till ny todo)
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

              // Filter (All / Done / Undone)
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

              // Lista
              Expanded(
                child: ListView.separated(
                  itemCount: _visibleTodos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = _visibleTodos[i];
                    return ListTile(
                      leading: Checkbox(
                        value: t.done,
                        onChanged: (_) => _toggleDone(t),
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

              const SizedBox(height: 80), // luft bakom knappen
            ],
          ),

          // + ADD nere till höger (lägger till från textfältet)
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
      ),
    );
  }
}
