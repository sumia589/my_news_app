import 'dart:convert';
import 'package:cook_with_engineer/news_model.dart';
import 'package:http/http.dart' as http;


class NewsService {
  static const String _apiKey = '2338f11b1d5041108a03d3dd045e174b';
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<NewsArticle>> fetchTopHeadlines() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/top-headlines?country=us&apiKey=$_apiKey'),
        headers: {'User-Agent': 'YourAppName/1.0'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .map((json) => NewsArticle.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to news API: $e');
    }
  }

  Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/everything?q=$query&apiKey=$_apiKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .map((json) => NewsArticle.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to news API: $e');
}
}
}
