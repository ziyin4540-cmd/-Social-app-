import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

const String supabaseUrl = 'https://kngqwiscyivobiiqunve.supabase.co';
const String supabaseAnonKey = 'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ3F3aXNjeWl2b2JpaXF1bnZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNzc1ODAsImV4cCI6MjEwNjg1MzU4MH0.YXQtqHQ9LKdynxN7lqPONRwsQbxEV_ervwo6AY12eR8';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const DarkSocialApp());
}

class DarkSocialApp extends StatelessWidget {
  const DarkSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dark Social',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const UserHomeScreen(),
    const RealtimeChatScreen(),
    const VideoDownloaderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Downloader'),
        ],
      ),
    );
  }
}

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dark Social Home")),
      body: const Center(child: Text("Welcome to Dark Social App", style: TextStyle(fontSize: 18))),
    );
  }
}

class RealtimeChatScreen extends StatelessWidget {
  const RealtimeChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Realtime Chat")),
      body: const Center(child: Text("Chat Room")),
    );
  }
}

class VideoDownloaderScreen extends StatelessWidget {
  const VideoDownloaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Downloader")),
      body: const Center(child: Text("Downloader Screen")),
    );
  }
}
