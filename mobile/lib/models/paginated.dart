class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;

  static Paginated<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final Map<String, dynamic> meta =
        Map<String, dynamic>.from(json['meta'] as Map<dynamic, dynamic>);
    final List<dynamic> data = json['data'] as List<dynamic>? ?? <dynamic>[];
    return Paginated<T>(
      items: data
          .map((dynamic e) =>
              parse(Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
          .toList(),
      page: (meta['page'] ?? 1) as int,
      limit: (meta['limit'] ?? 20) as int,
      total: (meta['total'] ?? 0) as int,
      totalPages: (meta['totalPages'] ?? 0) as int,
      hasNextPage: (meta['hasNextPage'] ?? false) as bool,
    );
  }
}
