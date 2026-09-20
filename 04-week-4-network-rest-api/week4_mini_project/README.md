# week4_mini_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Mini Project

The app loads posts from `https://jsonplaceholder.typicode.com/posts` through
a centralized Dio client, repository, and Riverpod provider.

- Loading, error with retry, empty, and success states are displayed in the UI.
- Infinite scroll requests 10 posts per page and guards against duplicate requests.
- `Post.fromJson` uses safe defaults when API fields are missing or null.
- `test/model_and_error_test.dart` covers model parsing and error mapping.
- `test/provider_test.dart` uses a fake repository to test provider loading and pagination guards.

Run verification from this directory:

```text
flutter analyze
flutter test
```
