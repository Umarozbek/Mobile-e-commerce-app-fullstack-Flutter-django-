
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/service/firebase_messaging_service.dart';
import '../../../../core/service/secure_storage.dart';
import '../../../../dependencies_injection.dart';

class FcmTokenPage extends StatefulWidget {
  const FcmTokenPage({super.key});

  @override
  State<FcmTokenPage> createState() => _FcmTokenPageState();
}

class _FcmTokenPageState extends State<FcmTokenPage> {
  String? _fcmToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() => _isLoading = true);
    
    // Try to get from secure storage first
    final storage = SecureStorage();
    String? token = await storage.read(key: 'fcm_token');
    
    // If not in storage, get fresh token
    if (token == null || token.isEmpty) {
      final fcmService = sl<FirebaseMessagingService>();
      token = await fcmService.getToken();
      if (token != null) {
        await storage.write(key: 'fcm_token', value: token);
      }
    }
    
    setState(() {
      _fcmToken = token;
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Token copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Firebase Cloud Messaging Token',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bu tokenni Firebase Console da test notification yuborish uchun ishlatishingiz mumkin.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_fcmToken != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy Token'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Test Notification Yuborish:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionStep(
                      '1',
                      'Firebase Console ga kiring',
                      'https://console.firebase.google.com',
                    ),
                    _buildInstructionStep(
                      '2',
                      'Cloud Messaging bo\'limiga o\'ting',
                      'Project Settings > Cloud Messaging',
                    ),
                    _buildInstructionStep(
                      '3',
                      'Send test message tugmasini bosing',
                      null,
                    ),
                    _buildInstructionStep(
                      '4',
                      'Yuqoridagi tokenni joylashtiring va Send qiling',
                      null,
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        'no_data'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadToken,
                      child: Text('retry'.tr()),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInstructionStep(String number, String text, String? link) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 14),
                ),
                if (link != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    link,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
