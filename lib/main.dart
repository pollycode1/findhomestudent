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
            debugPrint('Received shared content: ${media.content}');
          }
          _handleSharedText(media.content!);
        }
      });      // Get the initial shared content when app is launched via sharing intent
      SharedMedia? initialSharedMedia = await handler.getInitialSharedMedia();
      if (initialSharedMedia != null && initialSharedMedia.content != null) {
        if (kDebugMode) {
          debugPrint('Initial shared content: ${initialSharedMedia.content}');
        }
        _handleSharedText(initialSharedMedia.content!);
      }    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing share handler: $e');
      }
    }
  }  void _handleSharedText(String sharedText) {
    if (kDebugMode) {
      debugPrint('Handling shared text: $sharedText');
    }
    
    // Clean the text
    String cleanedText = sharedText.trim().replaceAll('\n', '').replaceAll('\r', '');
    if (kDebugMode) {
      debugPrint('Cleaned shared text: $cleanedText');
    }
    
    // Check if the shared text contains a Google Maps URL or coordinates
    if (cleanedText.contains('maps.google.com') || 
        cleanedText.contains('goo.gl/maps') ||
        cleanedText.contains('maps.app.goo.gl') ||
        cleanedText.contains('maps.app') ||
        cleanedText.contains('@') ||
        cleanedText.contains('place_id') ||
        cleanedText.contains('plus.codes') ||
        RegExp(r'\d+\.\d+,\s*\d+\.\d+').hasMatch(cleanedText) ||
        RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)').hasMatch(cleanedText) ||        RegExp(r'll=(-?\d+\.?\d*),(-?\d+\.?\d*)').hasMatch(cleanedText) ||
        RegExp(r'q=(-?\d+\.?\d*),(-?\d+\.?\d*)').hasMatch(cleanedText)) {
      
      if (kDebugMode) {
        debugPrint('URL/coordinates detected, navigating to student selection');
      }
      
      // Navigate to student selection screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SelectStudentForLocationScreen(
              sharedUrl: cleanedText,
            ),
          ),
        );
      });    } else {
      if (kDebugMode) {
        debugPrint('No Google Maps URL or coordinates detected');
      }
      
      // Show a message for non-map URLs
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text('ลิงก์ที่แชร์ไม่ใช่ Google Maps URL: $cleanedText'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'ดูรายละเอียด',
                onPressed: () {
                  _showDebugDialog(cleanedText);
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