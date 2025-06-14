import 'package:flutter/material.dart';
import 'dart:async';
import 'package:share_handler/share_handler.dart';
import 'screens/home_screen.dart';
import 'screens/select_student_for_location_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initShareHandler();
  }

  void _initShareHandler() async {
    // Initialize share handler
    final handler = ShareHandler.instance;
    
    // Listen for incoming sharing intents while the app is already opened
    _intentDataStreamSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
      if (media.content != null) {
        _handleSharedText(media.content!);
      }
    });

    // Get the initial shared content when app is launched via sharing intent
    SharedMedia? initialSharedMedia = await handler.getInitialSharedMedia();
    if (initialSharedMedia?.content != null) {
      _handleSharedText(initialSharedMedia!.content!);
    }
  }

  void _handleSharedText(String sharedText) {
    // Check if the shared text contains a Google Maps URL
    if (sharedText.contains('maps.google.com') || 
        sharedText.contains('goo.gl/maps') ||
        sharedText.contains('maps.app.goo.gl')) {
      
      // Navigate to student selection screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SelectStudentForLocationScreen(
              sharedUrl: sharedText,
            ),
          ),
        );
      });
    } else {
      // Show a message for non-map URLs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('ลิงก์ที่แชร์ไม่ใช่ Google Maps URL'),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'โปรแกรมเยี่ยมบ้านนักเรียน',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
