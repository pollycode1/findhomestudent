import 'package:flutter/foundation.dart';
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
    try {
      // Initialize share handler
      final handler = ShareHandler.instance;
      
      // Listen for incoming sharing intents while the app is already opened
      _intentDataStreamSubscription = handler.sharedMediaStream.listen((SharedMedia media) {
        if (media.content != null) {
          if (kDebugMode) {
            print('Received shared content: ${media.content}');
          } // Debug log
          _handleSharedText(media.content!);
        }
      });      // Get the initial shared content when app is launched via sharing intent
      SharedMedia? initialSharedMedia = await handler.getInitialSharedMedia();
      if (initialSharedMedia?.content != null) {
        if (kDebugMode) {
          print('Initial shared content: ${initialSharedMedia!.content}');
        } // Debug log
        _handleSharedText(initialSharedMedia!.content!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing share handler: $e');
      }
    }
  }

  void _handleSharedText(String sharedText) {
    if (kDebugMode) {
      print('Handling shared text: $sharedText');
    } // Debug log
    
    // Check if the shared text contains a Google Maps URL or coordinates
    if (sharedText.contains('maps.google.com') || 
        sharedText.contains('goo.gl/maps') ||
        sharedText.contains('maps.app.goo.gl') ||
        sharedText.contains('maps.app') ||
        sharedText.contains('@') ||
        RegExp(r'\d+\.\d+,\s*\d+\.\d+').hasMatch(sharedText)) {
      
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
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('ลิงก์ที่แชร์ไม่ใช่ Google Maps URL: $sharedText'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ดูรายละเอียด',
                onPressed: () {
                  _showDebugDialog(sharedText);
                },
              ),
            ),
          );
        }
      });
    }
  }

  void _showDebugDialog(String sharedText) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('ข้อมูลที่ได้รับ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ข้อความที่แชร์:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(sharedText),
            const SizedBox(height: 16),
            const Text('รูปแบบที่รองรับ:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• https://maps.google.com/?q=lat,lng\n'
                      '• https://goo.gl/maps/xxxxx\n'
                      '• https://maps.app.goo.gl/xxxxx\n'
                      '• URL ที่มี @lat,lng\n'
                      '• พิกัด lat,lng'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
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
