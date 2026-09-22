import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Map<String, dynamic> user;
  final String role;
  final String? companyName;
  final String? companyLogo;

  const Authenticated({
    required this.user,
    required this.role,
    this.companyName,
    this.companyLogo,
  });

  @override
  List<Object?> get props => [user, role, companyName, companyLogo];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository = AuthRepository();
  StreamSubscription? _unauthorizedSub;

  AuthCubit() : super(AuthInitial()) {
    _unauthorizedSub = ApiClient().onUnauthorized.listen((_) {
      emit(Unauthenticated());
    });
  }

  @override
  Future<void> close() {
    _unauthorizedSub?.cancel();
    return super.close();
  }

  Future<void> checkAuthStatus() async {
    final user = await _repository.validateSession();
    if (user != null) {
      final role = user['role']?.toString() ?? 'STAFF';
      final company = user['company'] as Map<String, dynamic>?;
      emit(Authenticated(
        user: user,
        role: role,
        companyName: company?['name']?.toString(),
        companyLogo: company?['logo']?.toString() ?? user['companyLogo']?.toString(),
      ));
      return;
    }
    emit(Unauthenticated());
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final res = await _repository.login(email: email, password: password);
      if (res.success && res.data != null) {
        final user = res.data!['user'] as Map<String, dynamic>;
        final role = user['role']?.toString() ?? 'STAFF';
        final company = user['company'] as Map<String, dynamic>?;

        emit(Authenticated(
          user: user,
          role: role,
          companyName: company?['name']?.toString(),
          companyLogo: company?['logo']?.toString() ?? user['companyLogo']?.toString(),
        ));
      } else {
        emit(AuthError(res.message));
      }
    } catch (e) {
      emit(AuthError('Login failed: $e'));
    }
  }

  void updateCompanyInfo({String? name, String? logo}) {
    if (state is Authenticated) {
      final curr = state as Authenticated;
      final updatedUser = Map<String, dynamic>.from(curr.user);
      final company = Map<String, dynamic>.from(updatedUser['company'] as Map<String, dynamic>? ?? {});
      if (name != null) company['name'] = name;
      if (logo != null) company['logo'] = logo;
      updatedUser['company'] = company;

      emit(Authenticated(
        user: updatedUser,
        role: curr.role,
        companyName: name ?? curr.companyName,
        companyLogo: logo ?? curr.companyLogo,
      ));
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(Unauthenticated());
  }
}
