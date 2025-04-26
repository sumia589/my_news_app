import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth state stream
  Stream<User?> get userStream => _auth.authStateChanges();

  // Email/Password sign in
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.code} - ${e.message}");
      return null;
    }
  }

  // Email/Password registration
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Registration error: ${e.code} - ${e.message}");
      return null;
    }
  }

  // Google sign in
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Google sign in error: ${e.code} - ${e.message}");
      return null;
    }
  }

  // Password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Password reset error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // Email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      print("Email verification error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Get the ID token result which contains the claims
    final idTokenResult = await user.getIdTokenResult(true);
    final claims = idTokenResult.claims;
    
    // Check if the admin claim exists and is true
    return claims != null && claims['admin']==true;
}
}
Future<void> setAdminRole(String userId) async {
  await FirebaseFirestore.instance
      .collection('admins')
      .doc(userId)
      .set({ 'isAdmin': true });
}

Future<bool> isAdmin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  
  // Refresh the ID token to get the latest claims
  await user.reload();
  final token = await user.getIdTokenResult();
  return token.claims?['isAdmin'] == true;
}
