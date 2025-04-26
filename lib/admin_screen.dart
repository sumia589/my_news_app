import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'add_edit_article.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // স্টোরেজ পারমিশন চেক করার মেথড
  Future<bool> _checkStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    
    final status = await Permission.storage.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Admin Panel", 
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.home_sharp, color: Colors.black),
            iconSize: 30,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF9A826),
        onPressed: () async {
          bool hasPermission = await _checkStoragePermission();
          if (!context.mounted) return;
          
          if (hasPermission) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditArticle(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Need storage permission'),
                duration: Duration(seconds: 2),
              )
            );
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('news_articles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF9A826)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Articles Found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final article = snapshot.data!.docs[index];
              final data = article.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  leading: data['imageUrl'] != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => 
                              const Icon(Icons.broken_image),
                          ),
                        )
                      : const Icon(Icons.image),
                  title: Text(
                    data['title'] ?? 'No Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    data['author'] ?? 'Unknown Author',
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditArticle(
                                article: {
                                  'id': article.id,
                                  'title': data['title'],
                                  'content': data['content'],
                                  'author': data['author'],
                                  'imageUrl': data['imageUrl'],
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                            .collection('news_articles')
                            .doc(article.id)
                            .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
     ),
);
}
}
