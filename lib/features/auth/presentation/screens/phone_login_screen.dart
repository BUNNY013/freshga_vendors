import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  String? _localError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onContinue() {
    setState(() => _localError = null);
    final phone = _phoneController.text.trim();
    
    // Validation
    if (phone.isEmpty) {
      setState(() => _localError = 'Please enter your phone number.');
      return;
    }
    if (phone.length < 10) {
      setState(() => _localError = 'Please enter a valid 10-digit phone number.');
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() => _localError = 'Only numbers are allowed.');
      return;
    }

    final fullPhone = '+91$phone';
    
    context.read<AuthProvider>().verifyPhone(
      fullPhone,
      codeSentCallback: () {
        if (mounted) {
          context.push('/otp', extra: fullPhone);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading = authProvider.isLoading;
    final errorMessage = _localError ?? authProvider.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Branding
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 32),
                
                Text(
                  'Start Your\nHomemade Brand 🚀',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    height: 1.2,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'FreshGa HomeMades\nIndia\'s Homemade Food Marketplace ❤️',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Phone Input Area
                Text(
                  'Mobile Number',
                  style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: errorMessage != null ? AppColors.error : AppColors.grey300,
                      width: errorMessage != null ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Image.network(
                              'https://flagcdn.com/w40/in.png',
                              width: 24,
                              errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.flag, size: 24, color: AppColors.grey500),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: AppColors.grey300,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          style: const TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '00000 00000',
                            hintStyle: TextStyle(
                              color: AppColors.grey400,
                              fontSize: 18,
                              letterSpacing: 1.5,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onChanged: (val) {
                            if (_localError != null) setState(() => _localError = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Error message
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                const SizedBox(height: 40),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onContinue,
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
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Terms
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.grey500, fontSize: 12, height: 1.5),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our\n'),
                        TextSpan(
                          text: 'Terms of Service',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
