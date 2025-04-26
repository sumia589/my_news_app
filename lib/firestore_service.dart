import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> saveUserProfile(String userId, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(userId).set(userData, SetOptions(merge: true));
  }

  
  Future<void> bookmarkArticle(String userId, Map<String, dynamic> article) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(article['url']) 
        .set({
          ...article,
          'savedAt': FieldValue.serverTimestamp(),
        });
  }

  
  Stream<QuerySnapshot> getUserBookmarks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }

  
  Future<void> addToReadingHistory(String userId, Map<String, dynamic> article) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('history')
        .doc(article['url'])
        .set({
          ...article,
          'readAt': FieldValue.serverTimestamp(),
        });
  }
}