enum NoteSortOrder { newest, titleAscending, titleDescending }

List<T> sortNotes<T>(
  List<T> notes, {
  required NoteSortOrder order,
  required String Function(T) titleOf,
  required DateTime Function(T) updatedAtOf,
}) {
  final sortedNotes = List<T>.of(notes);

  switch (order) {
    case NoteSortOrder.newest:
      sortedNotes.sort((a, b) => updatedAtOf(b).compareTo(updatedAtOf(a)));
    case NoteSortOrder.titleAscending:
      sortedNotes.sort(
        (a, b) => titleOf(a).toLowerCase().compareTo(titleOf(b).toLowerCase()),
      );
    case NoteSortOrder.titleDescending:
      sortedNotes.sort(
        (a, b) => titleOf(b).toLowerCase().compareTo(titleOf(a).toLowerCase()),
      );
  }

  return sortedNotes;
}
