import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TIG333 TODO (fix)",
      theme: ThemeData(useMaterial3: true),
      home: const TodoOnePage(),
    );
  }
}

class TodoOnePage extends StatelessWidget {
  const TodoOnePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: const Text(
          "TIG333 TODO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [
          Icon(Icons.more_vert), // Tre prickar (ej klickbar)
        ],
      ),
      body: Column(
        children: [
          // Sökruta
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              enabled: false, // Ej klickbar
              decoration: InputDecoration(
                hintText: "Search...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // Filter-rutor
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Chip(label: Text("All")),
                Chip(label: Text("Done")),
                Chip(label: Text("Undone")),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.check_box_outline_blank),
                  title: Text("Write a book"),
                  trailing: Icon(Icons.close),
                ),
                ListTile(
                  leading: Icon(Icons.check_box_outline_blank),
                  title: Text("Do homework"),
                  trailing: Icon(Icons.close),
                ),
                ListTile(
                  leading: Icon(Icons.check_box),
                  title: Text(
                    "Tidy room",
                    style: TextStyle(decoration: TextDecoration.lineThrough),
                  ),
                  trailing: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Statiskt +ADD (ej klickbar)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: IgnorePointer(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.add),
                  label: const Text("ADD"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}// Detta är en teständring för att öppna ny PR

