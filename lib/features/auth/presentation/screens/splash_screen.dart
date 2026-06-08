import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthProvider _authProvider;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _authProvider.addListener(_onAuthStateChanged);
      _checkAuthAndRoute();
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted || _isNavigating) return;
    _checkAuthAndRoute();
  }

  void _checkAuthAndRoute() {
    if (_isNavigating) return;

    if (_authProvider.state == AuthState.unauthenticated) {
      _isNavigating = true;
      context.go('/login');
    } else if (_authProvider.state == AuthState.authenticated) {
      _isNavigating = true;
      
      final isApproved = _authProvider.userModel?.isVerified == true || 
                         _authProvider.applicationModel?.status == 'approved';
      
      if (isApproved) {
        if (_authProvider.userModel?.storeId == null || _authProvider.userModel!.storeId.isEmpty) {
          context.go('/store-setup');
        } else {
          context.go('/dashboard');
        }
      } else if (_authProvider.applicationModel == null) {
        context.go('/welcome');
      } else if (_authProvider.applicationModel!.status == 'pending') {
        context.go('/pending');
      } else if (_authProvider.applicationModel!.status == 'rejected') {
        context.go('/rejected');
      } else {
        context.go('/welcome');
      }
    }
    // If state is loading or initial, stay on splash screen
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, size: 80, color: AppColors.primary),
            SizedBox(height: 24),
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
