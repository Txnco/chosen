class MotivationalQuote {
  final int id;
  final String quote;
  final String? author;
  final int timesShown;

  MotivationalQuote({
    required this.id,
    required this.quote,
    this.author,
    required this.timesShown,
  });

  factory MotivationalQuote.fromJson(Map<String, dynamic> json) {
    return MotivationalQuote(
      id: json['id'] ?? 0,
      quote: json['quote'] ?? '',
      author: json['author'],
      timesShown: json['times_shown'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'quote': quote,
    'author': author,
    'times_shown': timesShown,
  };
}