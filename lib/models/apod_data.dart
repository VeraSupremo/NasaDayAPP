class ApodData {
  final String title;
  final String explanation;
  final String url;

  ApodData({required this.title, required this.explanation, required this.url});

  factory ApodData.fromJson(Map<String, dynamic> json) {
    return ApodData(
      title: json['title'],
      explanation: json['explanation'],
      url: json['url'],
    );
  }
}