import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _usernameOrEmailController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;
  bool _isLoading = false;
  String _selectedLang = 'ئۇيغۇرچە';

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final usernameOrEmail = _usernameOrEmailController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خاتالىق: ئىشلەتكۈچى ئىسمى ياكى ئىمنى تولۇق كىرگۈزۈڭ.';
      });
      return;
    }

    // Try logging in via auth provider
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    bool ok = false;
    if ((usernameOrEmail.toLowerCase() == 'admin' ||
            usernameOrEmail.toLowerCase() == 'admin@quran.com') &&
        (password == authState.adminPassword || password == 'admin7788')) {
      ok = await authNotifier.loginAsAdmin(password);
    } else {
      ok = await authNotifier.login(
        email: usernameOrEmail,
        password: password,
      );
    }

    if (!mounted) return;

    if (ok) {
      final updatedAuth = ref.read(authProvider);
      if (updatedAuth.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ئەزا ھالىتىدە كىردىڭىز.')),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خاتالىق: كىرگۈزگەن ئىشلەتكۈچى ئىسمى ياكى ئىم خاتا.';
      });
    }
  }

  void _showLostPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('پارولنى ئەسلىگە كەلتۈرۈش'),
          content: const Text(
            'باشقۇرغۇچىنىڭ ئەسلى شىفىرى: admin7788\n\nئەگەر يېڭىلىغان بولسىڭىز، ئارقا باشقۇرۇش مەركىزى زاپاس ھۆججىتىدىن كۆرەلەيسىز.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('چۈشەندىم'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F1), // Exact WordPress style background
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Circular Emblem (WordPress / Quran Emblem)
                  _buildTopLogo(),
                  const SizedBox(height: 24),

                  // Error notification box if error
                  if (_errorMessage != null) ...[
                    _buildErrorNotice(_errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  // Main White Login Box (Classic CMS Form)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFC3C4C7)),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Field 1: Username / Email
                        const Text(
                          'ئىشلەتكۈچى ئىسمى ياكى ئېلخەت ئادرېسى',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3338),
                            fontFamily: 'NotoNaskhArabic',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameOrEmailController,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C3338),
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF8C8F94)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF8C8F94)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFF2271B1),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Field 2: Password
                        const Text(
                          'ئىم',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3338),
                            fontFamily: 'NotoNaskhArabic',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2C3338),
                          ),
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF2271B1),
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF8C8F94)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: Color(0xFF8C8F94)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: Color(0xFF2271B1),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Checkbox: Remember me
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: const Color(0xFF2271B1),
                                onChanged: (val) => setState(
                                  () => _rememberMe = val ?? false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'كىرىش ئۇچۇرلىرىم ساقلانسۇن',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF50575E),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'كېيىنكى قېتىم كىرگەندە ساقلانغان ھالەتتە تۇرىدۇ',
                              child: Icon(
                                Icons.help_outline_rounded,
                                size: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Submit Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 90,
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2271B1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'كىرىش',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoNaskhArabic',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Bottom Link 1: Lost Password
                  InkWell(
                    onTap: _showLostPasswordDialog,
                    child: const Text(
                      'پارولنى ئۇنتۇپسىزمۇ؟',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2271B1),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Link 2: Go Back to Quran App
                  InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamed(context, '/');
                      }
                    },
                    child: const Text(
                      '← قۇرئان كەرىم ئەپ مەركىزىگە قايتىش',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2271B1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Language Switcher (Exact match to image)
                  _buildLanguageSwitcher(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Top Circular Logo matching the screenshot
  Widget _buildTopLogo() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF2C3338),
          width: 3.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2C3338),
          ),
          child: const Center(
            child: Icon(
              Icons.menu_book_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// Error Notice Bar (WordPress style)
  Widget _buildErrorNotice(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFD63638), width: 4),
          top: BorderSide(color: Color(0xFFC3C4C7), width: 0.5),
          left: BorderSide(color: Color(0xFFC3C4C7), width: 0.5),
          bottom: BorderSide(color: Color(0xFFC3C4C7), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2C3338),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Language Switcher (matching bottom of image)
  Widget _buildLanguageSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Language Icon
        const Icon(
          Icons.translate_rounded,
          size: 18,
          color: Color(0xFF50575E),
        ),
        const SizedBox(width: 8),
        const Text(
          'تىل',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF50575E),
          ),
        ),
        const SizedBox(width: 10),

        // Dropdown
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF8C8F94)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLang,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2C3338),
                fontFamily: 'NotoNaskhArabic',
              ),
              items: const [
                DropdownMenuItem(value: 'ئۇيغۇرچە', child: Text('ئۇيغۇرچە')),
                DropdownMenuItem(value: 'العربية', child: Text('العربية')),
                DropdownMenuItem(value: 'English', child: Text('English')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedLang = val);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Change button
        SizedBox(
          height: 36,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2271B1),
              side: const BorderSide(color: Color(0xFF2271B1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تىل «$_selectedLang» غا تەڭشەلدى.')),
              );
            },
            child: const Text(
              'ئۆزگەرت',
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'NotoNaskhArabic',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
