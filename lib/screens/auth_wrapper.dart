import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'admin_panel_screen.dart';
import 'user_dashboard_screen.dart';
import '../services/api_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _storage = const FlutterSecureStorage();

  static const String appVersion = "v1.0.1 (Build 2)";

  // Integrated Web Client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '411220621839-oalmi65mt66eve831m1okr92pkjcoj5s.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  bool _isLoading = true;
  String? _userRole;
  bool _needsRegistrationForm = false;

  String? _tempGoogleEmail;
  String? _tempGoogleId;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await ApiService.dio.get(
        '/api/v1/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.data['status'] == 'success') {
        final user = res.data['data']['user'];
        setState(() {
          _userRole = user['role'] ?? 'USER';
          _isLoading = false;
        });
      } else {
        await _storage.deleteAll();
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await ApiService.dio.post('/api/v1/auth/check-user', data: {
        'email': googleUser.email,
      });

      if (response.data['status'] == 'success') {
        if (response.data['is_registered'] == true) {
          final token = response.data['data']['token'];
          final user = response.data['data']['user'];
          await _storage.write(key: 'jwt_token', value: token);

          setState(() {
            _userRole = user['role'];
            _needsRegistrationForm = false;
            _isLoading = false;
          });
        } else {
          _tempGoogleEmail = googleUser.email;
          _tempGoogleId = googleUser.id;
          _nameController.text = googleUser.displayName ?? '';

          setState(() {
            _needsRegistrationForm = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleCompleteRegistration() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name aur 10-digit Phone Number mandatory hai.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await ApiService.dio.post('/api/v1/auth/register-complete', data: {
        'email': _tempGoogleEmail,
        'google_id': _tempGoogleId,
        'full_name': name,
        'phone_number': phone,
      });

      if (res.data['status'] == 'success') {
        final token = res.data['data']['token'];
        final user = res.data['data']['user'];
        await _storage.write(key: 'jwt_token', value: token);

        setState(() {
          _userRole = user['role'];
          _needsRegistrationForm = false;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleLogout() async {
    await _storage.deleteAll();
    await _googleSignIn.signOut();
    setState(() {
      _userRole = null;
      _needsRegistrationForm = false;
      _tempGoogleEmail = null;
      _tempGoogleId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))),
      );
    }

    // SCREEN 1: Registration Completion Card
    if (_needsRegistrationForm) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B00).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFFF6B00), size: 28),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: _handleLogout,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text('Complete Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Verify account for rewards & instant payouts.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              prefixText: '+91  ',
                              prefixIcon: const Icon(Icons.phone_android_rounded),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B00),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isSubmitting ? null : _handleCompleteRegistration,
                              child: _isSubmitting
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Submit & Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      appVersion,
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // SCREEN 2: Google Sign-In Card
    if (_userRole == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, size: 56, color: Color(0xFFFF6B00)),
                          ),
                          const SizedBox(height: 24),
                          const Text('Paisa Loots', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text('Complete tasks & earn daily rewards', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _handleGoogleSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.g_mobiledata_rounded, size: 34, color: Color(0xFFFF6B00)),
                                  SizedBox(width: 8),
                                  Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      appVersion,
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // SCREEN 3: Dynamic Dashboards
    return _userRole == 'ADMIN'
        ? AdminPanelScreen(onSwitchToUser: _handleLogout)
        : UserDashboardScreen(onLogout: _handleLogout);
  }
}
