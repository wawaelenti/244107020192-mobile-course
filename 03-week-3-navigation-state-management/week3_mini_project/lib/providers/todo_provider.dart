import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  const Todo({
    required this.title,
    this.isCompleted = false,
  });

  final String title;
  final bool isCompleted;

  Todo copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return Todo(
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TodoNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    return [];
  }

  void addTodo(String title) {
    if (title.trim().isEmpty) return;

    state = [
      ...state,
      Todo(title: title.trim()),
    ];
  }

  void toggleTodo(int index) {
    final todos = [...state];

    todos[index] = todos[index].copyWith(
      isCompleted: !todos[index].isCompleted,
    );

    state = todos;
  }

  void removeTodo(int index) {
    final todos = [...state];
    todos.removeAt(index);
    state = todos;
  }
}

final todoListProvider =
    NotifierProvider<TodoNotifier, List<Todo>>(
  TodoNotifier.new,
);

final incompleteTodoProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);

  return todos
      .where((todo) => !todo.isCompleted)
      .toList();
});