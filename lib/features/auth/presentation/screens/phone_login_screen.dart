import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../core/theme/app_text_styles.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  String? _localError;
  
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onContinue() {
    setState(() => _localError = null);
    // Strip everything except digits in case autofill pastes formatted string
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Validation
    if (phone.isEmpty) {
      setState(() => _localError = 'Please enter your phone number.');
      return;
    }
    if (phone.length < 10) {
      setState(() => _localError = 'Please enter a valid 10-digit phone number.');
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

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight,
            child: Image.asset(
              'assets/images/vendor_login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).viewInsets.bottom),
                child: IntrinsicHeight(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const Spacer(),
                        
                        // Slide Up Card
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Branding
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  Text(
                                    'FreshGa',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vendor Portal',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      height: 1.2,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Enter your registered mobile number to access your store.',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Phone Input Area
                                  AutofillGroup(
                                    child: PremiumTextField(
                                      label: 'Phone Number',
                                      isRequired: true,
                                      controller: _phoneController,
                                      focusNode: _phoneFocus,
                                      keyboardType: TextInputType.phone,
                                      autofillHints: const [AutofillHints.telephoneNumber],
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      hintText: '00000 00000',
                                      errorText: errorMessage,
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
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
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onChanged: (val) {
                                        if (_localError != null) setState(() => _localError = null);
                                        context.read<AuthProvider>().clearError();
                                      },
                                    ),
                                  ),
                                    
                                  const SizedBox(height: 32),
                                  
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
                                              'Get Started',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
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
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                launchUrl(Uri.parse('https://sites.google.com/view/freshaga/home'));
                                              },
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Privacy Policy',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                launchUrl(Uri.parse('https://sites.google.com/view/freshaga/home'));
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
