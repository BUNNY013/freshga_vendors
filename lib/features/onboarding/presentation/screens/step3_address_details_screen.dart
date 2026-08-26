import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../widgets/primary_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Step3AddressDetailsScreen extends StatefulWidget {
  const Step3AddressDetailsScreen({super.key});

  @override
  State<Step3AddressDetailsScreen> createState() => _Step3AddressDetailsScreenState();
}

class _Step3AddressDetailsScreenState extends State<Step3AddressDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreedToTerms = false;

  void _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service to continue.')),
      );
      return;
    }

    final provider = context.read<OnboardingProvider>();
    
    if (provider.bankImage == null && (provider.existingBankUrl == null || provider.existingBankUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a photo of your Bank Passbook or Cancelled Cheque')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      final provider = context.read<OnboardingProvider>();
      final success = await provider.submitApplication();

      if (success && mounted) {
        context.go('/pending');
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error!)));
      }
    }
  }

  Widget _buildBankPhotoUploadButton(BuildContext context, OnboardingProvider provider) {
    final imageFile = provider.bankImage;
    final existingUrl = provider.existingBankUrl;

    if (imageFile != null || (existingUrl != null && existingUrl.isNotEmpty)) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: EdgeInsets.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InteractiveViewer(
                        child: imageFile != null ? Image.file(imageFile) : Image.network(existingUrl!),
                      ),
                      Positioned(
                        top: 40,
                        right: 20,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                image: DecorationImage(
                  image: imageFile != null ? FileImage(imageFile) as ImageProvider : NetworkImage(existingUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => provider.removeImage('bank'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                  ],
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.pickImage('bank', source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.pickImage('bank', source: ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.grey300, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('Upload Passbook / Cheque', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Tap to take a photo or select from gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 3),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Your earnings will be securely transferred to this account.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontSize: 15)),
                      const SizedBox(height: 32),
                      
                      PremiumTextField(
                        label: 'Account Holder Name',
                        controller: provider.accountNameController,
                        hintText: 'As per bank records (Must match PAN Card)',
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.grey400),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Text(
                              'Account Type',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: provider.accountType,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.grey400),
                            ),
                        items: const [
                          DropdownMenuItem(value: 'Savings', child: Text('Savings Account')),
                          DropdownMenuItem(value: 'Current', child: Text('Current Account')),
                        ],
                            onChanged: (val) {
                              if (val != null) provider.setAccountType(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PremiumTextField(
                        label: 'Account Number',
                        controller: provider.accountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter account number',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.grey400),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(30),
                        ],
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Confirm Account Number',
                        controller: provider.confirmAccountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Re-enter account number',
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.grey400),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(30),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value != provider.accountNumberController.text) return 'Account numbers do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'IFSC Code',
                        controller: provider.ifscController,
                        textCapitalization: TextCapitalization.characters,
                        prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.grey400),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          UpperCaseTextFormatter(),
                        ],
                        hintText: '11-character IFSC code',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 11) return 'Invalid IFSC length';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Bank Name',
                        controller: provider.bankNameController,
                        hintText: 'Auto-fetched using IFSC',
                        prefixIcon: const Icon(Icons.account_balance_outlined, size: 20, color: AppColors.grey400),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'UPI ID (Optional)',
                        controller: provider.upiController,
                        hintText: 'e.g. yourname@upi',
                        prefixIcon: const Icon(Icons.payment_outlined, size: 20, color: AppColors.grey400),
                        isRequired: false,
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                        child: Text(
                          'Upload Passbook / Cancelled Cheque *',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                        ),
                      ),
                      _buildBankPhotoUploadButton(context, provider),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text('This is required to verify your bank details', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ),
                      
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                                  children: [
                                    const TextSpan(text: 'I have read and agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(Uri.parse('https://sites.google.com/view/freshaga/home'));
                                        },
                                    ),
                                    const TextSpan(text: ', Commission Structure, and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launchUrl(Uri.parse('https://sites.google.com/view/freshaga/home'));
                                        },
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: PrimaryButton(
                  text: 'Submit Application',
                  onPressed: _submit,
                  isLoading: provider.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
