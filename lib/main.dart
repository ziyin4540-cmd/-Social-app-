import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

// API Keys Configuration
const String supabaseUrl = 'https://kngqwiscyivobiiqunve.supabase.co';
const String supabaseAnonKey = 'EyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ3F3aXNjeWl2b2JpaXF1bnZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyNzc1ODAsImV4cCI6MjEwNjg1MzU4MH0.YXQtqHQ9LKdynxN7lqPONRwsQbxEV_ervwo6AY12eR8';
const String agoraAppId = 'Da9f4fb04e764f8e8eff889f37562706';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

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
      home: const AuthRoleWrapper(),
    );
  }
}

// Auth Role Switcher (User vs Admin Panel)
class AuthRoleWrapper extends StatefulWidget {
  const AuthRoleWrapper({super.key});

  @override
  State<AuthRoleWrapper> createState() => _AuthRoleWrapperState();
}

class _AuthRoleWrapperState extends State<AuthRoleWrapper> {
  bool _isLoading = true;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && data['role'] == 'admin') {
        setState(() => _role = 'admin');
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _role == 'admin' ? const AdminDashboardScreen() : const UserHomeScreen();
  }
}

// User Dashboard
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  AudioSession? _session;
  String _audioOutput = "Speakerphone";
  File? _stickerFile;

  @override
  void initState() {
    super.initState();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    _session = await AudioSession.instance;
    await _session?.configure(const AudioSessionConfiguration.voiceChat());
  }

  Future<void> _switchAudio(String device) async {
    if (device == 'Ear Speaker') {
      await _session?.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
    } else {
      await _session?.configure(const AudioSessionConfiguration.voiceChat());
    }
    setState(() => _audioOutput = device);
  }

  Future<void> _createSticker() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sticker Creator',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
          )
        ],
      );

      if (cropped != null) {
        final file = File(cropped.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';

        // Supabase Storage Bucket သို့ တိုက်ရိုက် Upload တင်ခြင်း
        await Supabase.instance.client.storage
            .from('stickers')
            .upload(fileName, file);

        final String publicUrl = Supabase.instance.client.storage
            .from('stickers')
            .getPublicUrl(fileName);

        setState(() {
          _stickerFile = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sticker Uploaded! URL: $publicUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dark Social - User")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.deepPurple.shade900,
              child: ListTile(
                leading: const Icon(Icons.video_call, size: 40, color: Colors.white),
                title: const Text("Start Video / Audio Call", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("HD Quality WebRTC Call"),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CallScreen(channelName: 'dark_social_room')),
                    );
                  },
                  child: const Text("Join Call"),
                ),
              ),
            ),
            const SizedBox(height: 15),

            Card(
              child: ListTile(
                title: const Text("Audio Output Route"),
                subtitle: Text("Current Route: $_audioOutput"),
                trailing: PopupMenuButton<String>(
                  onSelected: _switchAudio,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Ear Speaker', child: Text('Ear Speaker')),
                    const PopupMenuItem(value: 'Speakerphone', child: Text('Speaker / Bluetooth')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Photo to Sticker Maker", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _stickerFile != null
                        ? Image.file(_stickerFile!, height: 150, width: 150)
                        : const Icon(Icons.palette, size: 80, color: Colors.grey),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _createSticker,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Select & Crop Sticker"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Call Screen Setup
class CallScreen extends StatefulWidget {
  final String channelName;
  const CallScreen({super.key, required this.channelName});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call Room: ${widget.channelName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => _engine.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 160,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: "mute",
                    backgroundColor: _isMuted ? Colors.red : Colors.grey,
                    onPressed: () {
                      setState(() => _isMuted = !_isMuted);
                      _engine.muteLocalAudioStream(_isMuted);
                    },
                    child: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton(
                    heroTag: "end_call",
                    backgroundColor: Colors.red,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return const Text(
        'Waiting for other user to join...',
        textAlign: TextAlign.center,
      );
    }
  }
}

// Admin Panel Dashboard
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dark Social - Admin Panel"),
        backgroundColor: Colors.redAccent,
      ),
      body: const Center(
        child: Text("Admin Control Panel & System Analytics"),
      ),
    );
  }
}
