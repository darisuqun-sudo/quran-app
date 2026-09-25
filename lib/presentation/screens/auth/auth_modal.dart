import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';

class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AuthModal(),
    );
  }

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form
  final _loginEmailController = TextEditingController();
  final _loginPassController = TextEditingController();
  bool _obscureLoginPass = true;

  // Register form
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPassController = TextEditingController();
  bool _obscureRegPass = true;

  // Admin PIN form
  final _adminPassController = TextEditingController();
  bool _isAdminMode = false;
  bool _obscureAdminPass = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPassController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPassController.dispose();
    _adminPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppTheme.accentGold.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: authState.isLoggedIn
                ? _buildLoggedInProfile(context, authState)
                : (_isAdminMode
                    ? _buildAdminLoginView(context, authState)
                    : _buildVisitorAuthView(context, authState)),
          ),
        ),
      ),
    );
  }

  /// View when user is already logged in (Profile & Logout)
  Widget _buildLoggedInProfile(BuildContext context, AuthState authState) {
    final user = authState.currentUser!;
    final settings = ref.watch(appSettingsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'شەخسىي ئەزا مەركىزى',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 16),

        // Avatar
        CircleAvatar(
          radius: 38,
          backgroundColor: user.isAdmin
              ? AppTheme.accentGold
              : AppTheme.primaryEmerald,
          child: Icon(
            user.isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.person_rounded,
            size: 42,
            color: user.isAdmin ? AppTheme.deepEmerald : AppTheme.accentGold,
          ),
        ),
        const SizedBox(height: 12),

        // Name
        Text(
          user.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 10),

        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: user.isAdmin
                ? AppTheme.accentGold.withValues(alpha: 0.2)
                : AppTheme.primaryEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: user.isAdmin ? AppTheme.accentGold : AppTheme.primaryEmerald,
              width: 1,
            ),
          ),
          child: Text(
            user.isAdmin
                ? '🛡️ سېستىما باشقۇرغۇچىسى (Admin)'
                : '✓ رەسمىي ئەزا (Member)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: user.isAdmin
                  ? AppTheme.accentGold
                  : AppTheme.primaryEmerald,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Stats card for regular member
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.bookmark_added_rounded,
                      color: AppTheme.accentGold),
                  const SizedBox(height: 6),
                  Text(
                    '${settings.bookmarks.length}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('خەتكۈچلەر', style: TextStyle(fontSize: 12)),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
              Column(
                children: [
                  const Icon(Icons.timer_rounded,
                      color: AppTheme.accentGold),
                  const SizedBox(height: 6),
                  Text(
                    '${user.dailyGoalMinutes} مىنۇت',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text('كۈندىلىك نىشان', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // If Admin: show direct entry to Admin Dashboard
        if (user.isAdmin) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.deepEmerald,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text(
              'ئارقا باشقۇرۇش سۇپىسىنى ئېچىش (Admin Dashboard)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminDashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Logout button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text(
            'ھېساباتتىن چېكىنىش (چىقىش)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }

  /// Normal Visitor view (Login / Register Tabs)
  Widget _buildVisitorAuthView(BuildContext context, AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'ئەزا مەركىزى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 8),

        // Tabs
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.accentGold,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'ئەزا كىرىش (Login)'),
              Tab(text: 'ئەزا بولۇش (Register)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Error message if any
        if (authState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          height: 240,
          child: TabBarView(
            controller: _tabController,
            children: [
              // Login Tab
              _buildLoginTab(authState),
              // Register Tab
              _buildRegisterTab(authState),
            ],
          ),
        ),

        const Divider(height: 24),

        // Secret Admin Portal Entry
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.accentGold,
          ),
          icon: const Icon(Icons.lock_outline_rounded, size: 16),
          label: const Text(
            'باشقۇرغۇچى سۈپىتىدە كىرىش (Admin Mode)',
            style: TextStyle(fontSize: 13),
          ),
          onPressed: () {
            setState(() {
              _isAdminMode = true;
            });
          },
        ),
      ],
    );
  }

  /// Login Tab
  Widget _buildLoginTab(AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'ئېلېكترونلۇق خەت (ئىمائىل)',
              hintText: 'user@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loginPassController,
            obscureText: _obscureLoginPass,
            decoration: InputDecoration(
              labelText: 'مەخپىي نومۇر',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureLoginPass
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () =>
                    setState(() => _obscureLoginPass = !_obscureLoginPass),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: authState.isLoading
                ? null
                : () async {
                    final ok = await ref.read(authProvider.notifier).login(
                          email: _loginEmailController.text,
                          password: _loginPassController.text,
                        );
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('مۇۋەپپەقىيەتلىك كىردىڭىز!')),
                      );
                    }
                  },
            icon: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: const Text(
              'كىرىش',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// Register Tab
  Widget _buildRegisterTab(AuthState authState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _regNameController,
            decoration: InputDecoration(
              labelText: 'ئىسمىڭىز',
              hintText: 'مەسىلەن: مۇھەممەد',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'ئېلېكترونلۇق خەت (ئىمائىل)',
              hintText: 'user@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _regPassController,
            obscureText: _obscureRegPass,
            decoration: InputDecoration(
              labelText: 'مەخپىي نومۇر (ئەڭ ئاز 4 ھەرپ)',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscureRegPass
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () =>
                    setState(() => _obscureRegPass = !_obscureRegPass),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.deepEmerald,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: authState.isLoading
                ? null
                : () async {
                    final ok = await ref.read(authProvider.notifier).register(
                          name: _regNameController.text,
                          email: _regEmailController.text,
                          password: _regPassController.text,
                        );
                    if (ok && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ھېساباتىڭىز مۇۋەپپەقىيەتلىك تىزىملاتتى!'),
                        ),
                      );
                    }
                  },
            icon: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: const Text(
              'ھەقسىز ئەزا بولۇش',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// Admin Master PIN Login View
  Widget _buildAdminLoginView(BuildContext context, AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => setState(() => _isAdminMode = false),
            ),
            const Text(
              'باشقۇرغۇچى كىرىش (Admin)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),

        const Center(
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFF0A261B),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: AppTheme.accentGold,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'بۇ بەت پەقەت ئەپ باشقۇرغۇچىسى ئۈچۈن ئېچىۋېتىلگەن. ئارقا سەھنىگە كىرىش ئۈچۈن مەخسۇس ئادمىن كودىنى كىرگۈزۈڭ.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        if (authState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Text(
              authState.errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),

        TextField(
          controller: _adminPassController,
          obscureText: _obscureAdminPass,
          decoration: InputDecoration(
            labelText: 'باشقۇرغۇچى شىفىرى (Admin Key)',
            hintText: 'ئەسلى كود: admin7788',
            prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppTheme.accentGold),
            suffixIcon: IconButton(
              icon: Icon(_obscureAdminPass
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded),
              onPressed: () =>
                  setState(() => _obscureAdminPass = !_obscureAdminPass),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 18),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.deepEmerald,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: authState.isLoading
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  final ok = await ref
                      .read(authProvider.notifier)
                      .loginAsAdmin(_adminPassController.text);
                  if (ok && mounted) {
                    nav.pop();
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardScreen(),
                      ),
                    );
                  }
                },
          icon: authState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_rounded),
          label: const Text(
            'ئارقا سۇپىغا كىرىش',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 8),

        TextButton(
          onPressed: () => setState(() => _isAdminMode = false),
          child: const Text('ئادەتتىكى ئەزا كىرىشكە قايتىش'),
        ),
      ],
    );
  }
}
