enum BookSortField { title, pagesLeft, dateAdded, author }

enum BookSortDirection { ascending, descending }

class BookFilter {
  final String? searchQuery;
  final List<int> selectedTagIds;
  final bool? showCompleted;
  final BookSortField sortField;
  final BookSortDirection sortDirection;

  const BookFilter({
    this.searchQuery,
    this.selectedTagIds = const [],
    this.showCompleted,
    this.sortField = BookSortField.dateAdded,
    this.sortDirection = BookSortDirection.descending,
  });

  BookFilter copyWith({
    String? Function()? searchQuery,
    List<int>? selectedTagIds,
    bool? Function()? showCompleted,
    BookSortField? sortField,
    BookSortDirection? sortDirection,
  }) {
    return BookFilter(
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      showCompleted: showCompleted != null ? showCompleted() : this.showCompleted,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}
