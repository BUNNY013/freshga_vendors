import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AuthProvider _authProvider;
  bool _isNavigating = false;
  bool _animationCompleted = false;

  late AnimationController _scaleController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Text fade and slide animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider = context.read<AuthProvider>();
      _authProvider.addListener(_onAuthStateChanged);
      _playAnimations();
    });
  }

  Future<void> _playAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _scaleController.forward();
    
    // Stagger the text animation
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    
    _animationCompleted = true;
    _checkAuthAndRoute();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted || _isNavigating || !_animationCompleted) return;
    _checkAuthAndRoute();
  }

  void _checkAuthAndRoute() {
    if (_isNavigating || !_animationCompleted) return;

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
      } else if (_authProvider.applicationModel!.status == 'pending' || _authProvider.applicationModel!.status == 'changes_required') {
        context.go('/pending');
      } else if (_authProvider.applicationModel!.status == 'rejected' || _authProvider.applicationModel!.status == 'rejected_permanent') {
        context.go('/rejected');
      } else {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6CBF43), // FreshGa Green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'FreshGa',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Business',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
