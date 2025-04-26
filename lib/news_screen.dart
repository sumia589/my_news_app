import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cook_with_engineer/news_service.dart';
import 'package:cook_with_engineer/news_model.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<NewsArticle>> futureHeadlines;

  @override
  void initState() {
    super.initState();
    futureHeadlines = Provider.of<NewsService>(context, listen: false).fetchTopHeadlines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: futureHeadlines,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No news available'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final article = snapshot.data![index];
              return Card(
                child: ListTile(
                  leading: article.urlToImage != null
                      ? Image.network(article.urlToImage!)
                      : null,
                  title: Text(article.title),
                  subtitle: Text(article.description ?? 'No description'),
                  onTap: () {
                    // You could add navigation to a detail screen here
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

extension on NewsArticle {
  get urlToImage => null;
}