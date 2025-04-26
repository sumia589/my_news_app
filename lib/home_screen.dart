import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:intl/intl.dart';
//import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List articles = [];
  List filteredArticles = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  Future<void> fetchNews() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          'https://newsapi.org/v2/top-headlines?country=us&apiKey=2338f11b1d5041108a03d3dd045e174b'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          articles = data['articles'];
          filteredArticles = data['articles'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load news: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _filterArticles(String query) {
    setState(() {
      filteredArticles = articles.where((article) {
        final title = article['title']?.toString().toLowerCase() ?? '';
        final description = article['description']?.toString().toLowerCase() ?? '';
        return title.contains(query.toLowerCase()) || 
               description.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch URL'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y • h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(179, 245, 245, 245),
      appBar: AppBar(
        title: Text('News Pulse', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: const Color.fromARGB(44, 0, 0, 0)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NewsSearchDelegate(articles),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchNews,
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filteredArticles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No articles found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: fetchNews,
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchNews,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    separatorBuilder: (context, index) => SizedBox(height: 16),
                    itemCount: filteredArticles.length,
                    itemBuilder: (context, index) {
                      final article = filteredArticles[index];
                      return NewsCard(
                        article: article,
                        onTap: () => _launchURL(article['url'] ?? ''),
                        formattedDate: _formatDate(article['publishedAt'] ?? ''),
                      );
                    },
                  ),
                ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final dynamic article;
  final VoidCallback onTap;
  final String formattedDate;

  const NewsCard({
    required this.article,
    required this.onTap,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article['urlToImage'] != null)
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: article['urlToImage'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (article['source']['name'] != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article['source']['name'],
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Spacer(),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    article['title'] ?? 'No title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['description'] ?? 'No description',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(color: const Color.fromARGB(255, 128, 33, 243)),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16, color: const Color.fromARGB(255, 219, 33, 243)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewsSearchDelegate extends SearchDelegate {
  final List articles;

  NewsSearchDelegate(this.articles);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = articles.where((article) {
      final title = article['title']?.toString().toLowerCase() ?? '';
      final description = article['description']?.toString().toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) || 
             description.contains(query.toLowerCase());
    }).toList();

    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? []
        : articles.where((article) {
            final title = article['title']?.toString().toLowerCase() ?? '';
            final description = article['description']?.toString().toLowerCase() ?? '';
            return title.contains(query.toLowerCase()) || 
                   description.contains(query.toLowerCase());
          }).toList();

    return _buildSearchResults(suggestions);
  }

  Widget _buildSearchResults(List results) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final article = results[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 1,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: article['urlToImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: article['urlToImage'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(Icons.article),
                  ),
            title: Text(
              article['title'] ?? 'No title',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              article['source']['name'] ?? 'Unknown source',
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () {
              close(context, article);
            },
          ),
    );
},
);
}
}
