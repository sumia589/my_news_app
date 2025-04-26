class NewsArticle {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? source;
  final String? publishedAt;
  final String? url;

  NewsArticle({
    required this.title,
    this.description,
    this.imageUrl,
    this.source,
    this.publishedAt,
    this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No title',
      description: json['description'],
      imageUrl: json['urlToImage'],
      source: json['source'] is Map ? json['source']['name'] : json['source'],
      publishedAt: json['publishedAt'],
      url: json['url'],
    );
  }
}