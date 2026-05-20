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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndRoute();
    });
  }

  void _checkAuthAndRoute() {
    final auth = context.read<AuthProvider>();
    
    // We listen to the state changes to navigate appropriately
    auth.addListener(() {
      if (mounted) {
        _navigateBasedOnState(auth);
      }
    });

    // Initial check
    _navigateBasedOnState(auth);
  }

  void _navigateBasedOnState(AuthProvider auth) {
    if (auth.state == AuthState.unauthenticated) {
      context.go('/login');
    } else if (auth.state == AuthState.authenticated) {
      if (auth.userModel?.isVerified == true) {
        context.go('/dashboard');
      } else if (auth.applicationModel == null) {
        context.go('/welcome');
      } else if (auth.applicationModel!.status == 'pending') {
        context.go('/pending');
      } else if (auth.applicationModel!.status == 'approved') {
        context.go('/dashboard');
      } else if (auth.applicationModel!.status == 'rejected') {
        context.go('/rejected');
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minimal logo placeholder
            Icon(Icons.storefront_rounded, size: 80, color: AppColors.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
