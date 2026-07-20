import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 32),
            SizedBox(height: 8),
            Text('Upload Passbook / Cheque', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                        'Bank Details & Agreement 💸',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Your earnings will be securely transferred to this account.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 32),
                      
                      CustomTextField(
                        label: 'Account Holder Name',
                        controller: provider.accountNameController,
                        hintText: 'As per bank records (Must match PAN Card)',
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),
                      Text('Account Type', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: provider.accountType,
                        decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: AppColors.surface),
                        items: const [
                          DropdownMenuItem(value: 'Savings', child: Text('Savings Account')),
                          DropdownMenuItem(value: 'Current', child: Text('Current Account')),
                        ],
                        onChanged: (val) {
                          if (val != null) provider.setAccountType(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Account Number',
                        controller: provider.accountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter account number',
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Confirm Account Number',
                        controller: provider.confirmAccountNumberController,
                        keyboardType: TextInputType.number,
                        hintText: 'Re-enter account number',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value != provider.accountNumberController.text) return 'Account numbers do not match';
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'IFSC Code',
                        controller: provider.ifscController,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [UpperCaseTextFormatter()],
                        hintText: '11-character IFSC code',
                        maxLength: 11,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 11) return 'Invalid IFSC length';
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'Bank Name',
                        controller: provider.bankNameController,
                        hintText: 'Auto-fetched using IFSC',
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),

                      CustomTextField(
                        label: 'UPI ID (Optional)',
                        controller: provider.upiController,
                        hintText: 'e.g. yourname@upi',
                        isRequired: false,
                      ),
                      
                      const SizedBox(height: 16),
                      Text('Upload Passbook / Cancelled Cheque *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _buildBankPhotoUploadButton(context, provider),
                      const SizedBox(height: 4),
                      Text('This is required to verify your bank details', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),
                      
                      Text('Platform Agreement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('1. FreshGa charges a standard platform commission on all orders to cover software, payment gateways, and support.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 8),
                            const Text('2. By checking the box below, you guarantee that all food prepared for FreshGa customers is made in safe, sanitary, and hygienic conditions.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 8),
                            const Text('3. You agree to indemnify FreshGa against any claims related to food quality or safety.', style: TextStyle(fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Service, Commission Structure, and Food Safety Guarantees.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
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
