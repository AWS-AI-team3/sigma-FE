import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  Map<String, dynamic>? _backendStatus;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkBackendStatus();
  }

  // 백엔드 상태 확인
  Future<void> _checkBackendStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _backendStatus = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '백엔드 응답 오류: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '백엔드 연결 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('SIGMA Control Panel'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBackendStatus,
            tooltip: '상태 새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkBackendStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 백엔드 상태 카드
              _buildStatusCard(),
              
              const SizedBox(height: 20),
              
              // MediaPipe 설정 카드
              _buildMediaPipeCard(),
              
              const SizedBox(height: 20),
              
              // AWS 설정 카드
              _buildAWSCard(),
              
              const SizedBox(height: 20),
              
              // 액션 버튼들
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // 백엔드 상태 카드
  Widget _buildStatusCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart,
                  color: Colors.orange.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Backend Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
            else if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              )
            else if (_backendStatus != null)
              Column(
                children: [
                  _buildStatusRow('Status', _backendStatus!['status'], Colors.green),
                  _buildStatusRow('MediaPipe', _backendStatus!['mediapipe'], Colors.blue),
                  _buildStatusRow('Camera', _backendStatus!['camera'].toString(), 
                    _backendStatus!['camera'] ? Colors.green : Colors.red),
                  _buildStatusRow('Connected Clients', _backendStatus!['clients'].toString(), Colors.orange),
                  _buildStatusRow('Timestamp', _backendStatus!['timestamp'], Colors.grey),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MediaPipe 설정 카드
  Widget _buildMediaPipeCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gesture,
                  color: Colors.green.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'MediaPipe Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 설정 옵션들
            _buildSettingTile('Hand Detection', 'Enabled', Icons.pan_tool, Colors.green),
            _buildSettingTile('Max Hands', '2', Icons.confirmation_number, Colors.blue),
            _buildSettingTile('Detection Confidence', '70%', Icons.trending_up, Colors.orange),
            _buildSettingTile('Tracking Confidence', '50%', Icons.track_changes, Colors.purple),
          ],
        ),
      ),
    );
  }

  // AWS 설정 카드
  Widget _buildAWSCard() {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: Colors.blue.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'AWS Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildSettingTile('Transcribe', 'Ready', Icons.mic, Colors.green),
            _buildSettingTile('Bedrock', 'Connected', Icons.psychology, Colors.blue),
            _buildSettingTile('Region', 'us-east-1', Icons.public, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 액션 버튼들
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/overlay');
            },
            icon: const Icon(Icons.visibility),
            label: const Text('Start Overlay Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // 설정 페이지로 이동
            },
            icon: const Icon(Icons.settings),
            label: const Text('Advanced Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}