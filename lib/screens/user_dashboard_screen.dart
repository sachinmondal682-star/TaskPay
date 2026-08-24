import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class UserDashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const UserDashboardScreen({super.key, required this.onLogout});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _user;
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final token = await _storage.read(key: 'jwt_token');
    try {
      final userRes = await ApiService.dio.get('/api/v1/users/me',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      final offersRes = await ApiService.dio.get('/api/v1/offers',
          options: Options(headers: {'Authorization': 'Bearer $token'}));

      if (mounted) {
        setState(() {
          _user = userRes.data['data']['user'];
          _offers = offersRes.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStartOffer(int offerId) async {
    final token = await _storage.read(key: 'jwt_token');
    try {
      final res = await ApiService.dio.post(
        '/api/v1/clicks/create',
        data: {'offer_id': offerId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.data['status'] == 'success') {
        final url = Uri.parse(res.data['data']['tracking_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      );
    }

    final balance = _user?['coin_balance'] ?? '0.00';
    final name = _user?['name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paisa Loots', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFFFF6B00),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text('₹$balance', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 48),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Available Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_offers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No active tasks right now.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._offers.map((offer) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(offer['title'] ?? 'Task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('+₹${offer['payout_amount'] ?? '0'}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(offer['description'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _handleStartOffer(offer['id']),
                              child: const Text('Start Task'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
