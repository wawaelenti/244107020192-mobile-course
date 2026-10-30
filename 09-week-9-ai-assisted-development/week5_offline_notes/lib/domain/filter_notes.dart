List<T> filterNotes<T>(
  List<T> notes,
  String query,
  String Function(T) titleOf,
) {
  final normalizedQuery = query.trim().toLowerCase();

  if (normalizedQuery.isEmpty) {
    return notes;
  }

  return notes
      .where((note) => titleOf(note).toLowerCase().contains(normalizedQuery))
      .toList();
}
