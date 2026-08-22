import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ToDoList(),
    );
  }
}

// タスク1件のデータモデル
class TodoItem {
  String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // タスクのリストを保持する状態変数
  final List<TodoItem> _todoList = [
    TodoItem(title: 'Flutterの勉強をする'),
    TodoItem(title: 'スーパーで買い物', isDone: true),
  ];

  // テキスト入力用のコントローラー
  final TextEditingController _textFieldController = TextEditingController();

  // --- 処理: タスクの追加 ---
  void _addTodoItem(String title) {
    if (title.trim().isEmpty) return; // 空文字なら何もしない

    setState(() {
      _todoList.add(TodoItem(title: title));
    });
    _textFieldController.clear();
  }

  // --- 処理: タスク削除 ---
  void _deleteTodoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
  }

  // --- 処理: チェック状態の切り替え ---
  void _toggleTodoItem(int index) {
    setState(() {
      _todoList[index].isDone = !_todoList[index].isDone;
    });
  }

  // --- UI: タスク追加ダイアログを表示 ---
  Future<void> _displayDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しいタスクを追加'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'タスク名を入力...'),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
                _textFieldController.clear();
              },
            ),
            ElevatedButton(
              child: const Text('追加'),
              onPressed: () {
                _addTodoItem(_textFieldController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDoリスト'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // リストが空の場合はメッセージを表示
      body: _todoList.isEmpty
          ? const Center(
              child: Text(
                'タスクはありません！\n右下の＋ボタンから追加してください。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                final item = _todoList[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.isDone,
                    onChanged: (bool? value) {
                      _toggleTodoItem(index);
                    },
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      // 完了時は打ち消し線を表示
                      decoration: item.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteTodoItem(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayDialog(),
        tooltip: 'タスク追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}