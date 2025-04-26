import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firestore_service.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login to view bookmarks'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Articles'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getUserBookmarks(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookmarks yet'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final article = doc.data() as Map<String, dynamic>;
              return ListTile(
                leading: article['imageUrl'] != null
                    ? Image.network(article['imageUrl'], width: 50, height: 50)
                    : const Icon(Icons.article),
                title: Text(article['title'] ?? 'No title'),
                subtitle: Text(article['source'] ?? 'Unknown source'),
                onTap: () {
                  
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await firestoreService.removeBookmark(user.uid, article['url']);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

extension on FirestoreService {
  removeBookmark(String uid, article) {}
}