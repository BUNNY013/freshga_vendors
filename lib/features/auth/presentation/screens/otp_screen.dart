import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  int _secondsRemaining = 30;
  Timer? _timer;
  String? _localError;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus OTP field
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _otpFocusNode.requestFocus();
    });
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_isVerifying) return; // Prevent double taps

    setState(() => _localError = null);
    
    final otp = _otpController.text;
    if (otp.length < 6) {
      setState(() => _localError = 'Please enter a complete 6-digit OTP');
      return;
    }
    
    setState(() => _isVerifying = true);
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOTP(otp);
    
    if (mounted) {
      setState(() => _isVerifying = false);
      if (success) {
        // Navigation is handled by Splash/Auth Listener once user data is fetched
        // but we pop to let the Splash/Listener handle the routing properly
        context.go('/splash'); 
      }
    }
  }

  void _resendOtp() async {
    if (_secondsRemaining > 0) return;
    
    setState(() => _localError = null);
    _otpController.clear();
    _otpFocusNode.requestFocus();
    
    await context.read<AuthProvider>().resendOTP(widget.phone);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    // Either verifying via user input or loading via firebase resend
    final isLoading = _isVerifying || authProvider.isLoading;
    final errorMessage = _localError ?? authProvider.errorMessage;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: const TextStyle(
        fontSize: 24, 
        color: AppColors.textPrimary, 
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Verify Your\nNumber 🔒',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 32,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                        children: [
                          const TextSpan(text: 'We\'ve sent a 6-digit code to\n'),
                          TextSpan(
                            text: widget.phone,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const TextSpan(text: '  '),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: isLoading ? null : () => context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Change number',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Pinput(
                          length: 6,
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: defaultPinTheme.copyDecorationWith(
                            border: Border.all(color: AppColors.primary, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          errorPinTheme: defaultPinTheme.copyDecorationWith(
                            border: Border.all(color: AppColors.error, width: 2),
                          ),
                          onCompleted: (pin) => _verifyOtp(),
                          onChanged: (pin) {
                            if (_localError != null) setState(() => _localError = null);
                          },
                        ),
                      ),
                    ),
                    
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    const Spacer(),
                    
                    // Resend Section
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _secondsRemaining > 0
                            ? RichText(
                                key: const ValueKey('timer'),
                                text: TextSpan(
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  children: [
                                    const TextSpan(text: 'Resend code in '),
                                    TextSpan(
                                      text: '$_secondsRemaining s',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            : TextButton(
                                key: const ValueKey('resend'),
                                onPressed: isLoading ? null : _resendOtp,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                ),
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: isLoading ? 0 : 4,
                          shadowColor: AppColors.primary.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
