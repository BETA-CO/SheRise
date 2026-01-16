class Video {
  final String id;
  final String title;
  final String category;
  final String downloadUrl;
  final String originalUrl;
  final String thumbUrl;
  final String date;

  Video({
    required this.id,
    required this.title,
    required this.category,
    required this.downloadUrl,
    required this.originalUrl,
    required this.thumbUrl,
    required this.date,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'General',
      downloadUrl: json['downloadUrl'] ?? '',
      originalUrl: json['originalUrl'] ?? '',
      thumbUrl: json['thumbUrl'] ?? '',
      date: json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'downloadUrl': downloadUrl,
      'originalUrl': originalUrl,
      'thumbUrl': thumbUrl,
      'date': date,
    };
  }
}
