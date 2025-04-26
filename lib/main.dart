import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cook_with_engineer/admin_screen.dart';
import 'package:cook_with_engineer/auth_service.dart';
import 'package:cook_with_engineer/firestore_service.dart';
import 'package:cook_with_engineer/home_screen.dart';
import 'package:cook_with_engineer/login_screen.dart';
import 'package:cook_with_engineer/news_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Configure Firestore settings
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Auth state stream
        StreamProvider<User?>(
          create: (_) => AuthService().userStream,
          initialData: null,
          catchError: (_, err) {
            print('Error in auth stream: $err');
            return null;
          },
        ),
        
        // Auth service instance
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        // News service instance
        Provider<NewsService>(
          create: (_) => NewsService(),
        ),
        
        // Firestore service instance
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        
        // Firebase Storage instance
        Provider<FirebaseStorage>(
          create: (_) => FirebaseStorage.instance,
        ),
        
        // Firebase Firestore instance
        Provider<FirebaseFirestore>(
          create: (_) => FirebaseFirestore.instance,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => HomePage(),
          '/admin': (context) => const AdminScreen(),
          '/login': (context) => const LoginScreen(),
        },
        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Step 1: Check if user is null or email not verified
    if (user == null || !user.emailVerified) {
      return const LoginScreen();
    }

    // Step 2: Check admin status
    return FutureBuilder<bool>(
      future: authService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error checking admin status',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    onPressed: () {
                      authService.signOut();
                    },
                    child: const Text(
                      'Go back to login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final isAdmin = snapshot.data ?? false;
        return isAdmin ? const AdminScreen() : HomePage();
      },
    );
  }
}