import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';

class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final List<UserModel> registeredUsers;
  final String adminPassword;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.registeredUsers = const [],
    this.adminPassword = 'admin',
  });

  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => currentUser?.role == UserRole.admin;

  AuthState copyWith({
    UserModel? currentUser,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<UserModel>? registeredUsers,
    String? adminPassword,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      registeredUsers: registeredUsers ?? this.registeredUsers,
      adminPassword: adminPassword ?? this.adminPassword,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const _kCurrentUserKey = 'quran_current_user_v1';
  static const _kUsersListKey = 'quran_registered_users_v1';
  static const _kAdminPasswordKey = 'quran_admin_password_v1';

  @override
  AuthState build() {
    _loadState();
    return const AuthState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load admin password (default: admin7788)
      final adminPass = prefs.getString(_kAdminPasswordKey) ?? 'admin7788';

      // Load registered users
      final usersJson = prefs.getString(_kUsersListKey);
      List<UserModel> users = [];
      if (usersJson != null) {
        final list = json.decode(usersJson) as List<dynamic>;
        users = list.map((e) => UserModel.fromMap(e as Map<String, dynamic>)).toList();
      }

      // Load current user session
      final currentUserJson = prefs.getString(_kCurrentUserKey);
      UserModel? current;
      if (currentUserJson != null) {
        current = UserModel.fromJson(currentUserJson);
      }

      state = state.copyWith(
        currentUser: current,
        registeredUsers: users,
        adminPassword: adminPass,
      );
    } catch (_) {
      // Fallback
    }
  }

  /// Register visitor with email and password
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ئىسمىڭىزنى تولۇق كىرگۈزۈڭ.',
      );
      return false;
    }

    if (!cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ئېلېكترونلۇق خەت (ئىمائىل) ئادرېسى توغرا ئەمەس.',
      );
      return false;
    }

    if (password.trim().length < 4) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'مەخپىي نومۇر ئەڭ ئاز بولغاندا 4 ھەرپ ياكى رەقەم بولسۇن.',
      );
      return false;
    }

    final exists = state.registeredUsers.any((u) => u.email.toLowerCase() == cleanEmail);
    if (exists) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'بۇ ئېلېكترونلۇق خەت ئاللىقاچان تىزىملىتىلغان، بىۋاسىتە كىرىڭ.',
      );
      return false;
    }

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      email: cleanEmail,
      role: UserRole.member,
      createdAt: DateTime.now(),
    );

    final updatedUsers = [...state.registeredUsers, newUser];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsersListKey, json.encode(updatedUsers.map((u) => u.toMap()).toList()));
    await prefs.setString(_kCurrentUserKey, newUser.toJson());

    state = state.copyWith(
      isLoading: false,
      currentUser: newUser,
      registeredUsers: updatedUsers,
      clearError: true,
    );
    return true;
  }

  /// Login as visitor / member with email & password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    // Check if logging in as Admin via credentials
    if ((cleanEmail == 'admin' || cleanEmail == 'admin@quran.com') &&
        cleanPassword == state.adminPassword) {
      return loginAsAdmin(cleanPassword);
    }

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ئىمائىل ۋە مەخپىي نومۇرنى تولۇق كىرگۈزۈڭ.',
      );
      return false;
    }

    // Find registered user
    final match = state.registeredUsers.where((u) => u.email.toLowerCase() == cleanEmail);
    if (match.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'بۇ ئىمائىل تېخى ئەزا بولمىغان، ئاۋۋال ئەزا بولۇڭ.',
      );
      return false;
    }

    final user = match.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUserKey, user.toJson());

    state = state.copyWith(
      isLoading: false,
      currentUser: user,
      clearError: true,
    );
    return true;
  }

  /// Login specifically as Administrator using Master Password / PIN
  Future<bool> loginAsAdmin(String enteredPassword) async {
    state = state.copyWith(isLoading: true, clearError: true);

    if (enteredPassword.trim() == state.adminPassword) {
      final adminUser = UserModel(
        id: 'admin_master',
        name: 'قۇرئان باشقۇرغۇچىسى',
        email: 'admin@quran.com',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCurrentUserKey, adminUser.toJson());

      state = state.copyWith(
        isLoading: false,
        currentUser: adminUser,
        clearError: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'باشقۇرغۇچى شىفىرى توغرا كەلمىدى! (ئەسلى شىفىر: admin7788)',
      );
      return false;
    }
  }

  /// Change admin password
  Future<bool> changeAdminPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.trim() != state.adminPassword) {
      state = state.copyWith(errorMessage: 'ھازىرقى كونا شىفىر خاتا!');
      return false;
    }
    if (newPassword.trim().length < 4) {
      state = state.copyWith(errorMessage: 'يېڭى شىفىر بەك قىسقا!');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAdminPasswordKey, newPassword.trim());

    state = state.copyWith(
      adminPassword: newPassword.trim(),
      clearError: true,
    );
    return true;
  }

  /// Sign out current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserKey);
    state = state.copyWith(clearUser: true, clearError: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
