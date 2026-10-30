import 'package:go_router/go_router.dart';

import 'pages/home_page.dart';
import 'pages/note_detail_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const HomePage();
      },
    ),
    GoRoute(
      path: '/note/:id',
      builder: (context, state) {
        final id = int.tryParse(
          state.pathParameters['id'] ?? '',
        );

        if (id == null) {
          return const HomePage();
        }

        return NoteDetailPage(noteId: id);
      },
    ),
  ],
);