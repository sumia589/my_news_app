import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firestore_service.dart';

class NewsDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;

  const NewsDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = FirebaseAuth.instance.currentUser;
    bool isBookmarked = false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getUserBookmarks(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  isBookmarked = snapshot.data!.docs
                      .any((doc) => doc.id == article['url']);
                }
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? Colors.amber : null,
                  ),
                  onPressed: () async {
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please login to bookmark')),
                      );
                      return;
                    }

                    if (isBookmarked) {
                      await firestoreService.removeBookmark(user.uid, article['url']);
                    } else {
                      await firestoreService.bookmarkArticle(user.uid, article);
                      await firestoreService.addToReadingHistory(user.uid, article);
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (article['imageUrl'] != null)
              Image.network(article['imageUrl']),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No title',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${article['source'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(),
                  Text(
                    article['content'] ?? 'No content available',
                    style: Theme.of(context).textTheme.bodyMedium,
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

extension on FirestoreService {
  removeBookmark(uid, article) {}
}