class MarketingBanner {
  const MarketingBanner({
    required this.id,
    required this.imageUrl,
    required this.active,
    required this.sortOrder,
    this.title,
    this.startsAt,
    this.endsAt,
  });

  final int id;
  final String imageUrl;
  final String? title;
  final bool active;
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory MarketingBanner.fromJson(Map<String, dynamic> json) {
    return MarketingBanner(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      imageUrl: (json['image_url'] ?? json['imageUrl'] ?? '').toString(),
      title: json['title']?.toString(),
      startsAt: DateTime.tryParse(
        (json['starts_at'] ?? json['startsAt'])?.toString() ?? '',
      ),
      endsAt: DateTime.tryParse(
        (json['ends_at'] ?? json['endsAt'])?.toString() ?? '',
      ),
      active: json['active'] == true ||
          json['is_active'] == true ||
          json['active']?.toString() == '1',
      sortOrder: int.tryParse(
            (json['sort_order'] ?? json['sortOrder'] ?? 0).toString(),
          ) ??
          0,
    );
  }

  MarketingBanner copyWith({bool? active, int? sortOrder}) {
    return MarketingBanner(
      id: id,
      imageUrl: imageUrl,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
