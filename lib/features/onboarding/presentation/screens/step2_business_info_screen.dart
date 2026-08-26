import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../widgets/primary_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Step2BusinessInfoScreen extends StatefulWidget {
  const Step2BusinessInfoScreen({super.key});

  @override
  State<Step2BusinessInfoScreen> createState() => _Step2BusinessInfoScreenState();
}

class _Step2BusinessInfoScreenState extends State<Step2BusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  void _nextStep() {
    final provider = context.read<OnboardingProvider>();
    
    // Manual validation for conditional fields
    if (provider.taxRegistrationType != 'NeedsHelp' && provider.taxNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your Tax Registration Number')));
      return;
    }
    
    if (provider.taxRegistrationType != 'NeedsHelp' && provider.taxImage == null && (provider.existingTaxUrl == null || provider.existingTaxUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your Tax Registration Document')));
      return;
    }
    
    if (provider.fssaiStatus == 'Have' && provider.fssaiNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your FSSAI Number')));
      return;
    }
    
    if (provider.fssaiStatus == 'Have' && provider.fssaiImage == null && (provider.existingFssaiUrl == null || provider.existingFssaiUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your FSSAI Certificate')));
      return;
    }
    
    if (provider.panNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your PAN Number')));
      return;
    }
    
    if (provider.panImage == null && (provider.existingPanUrl == null || provider.existingPanUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your PAN Card Photo')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      provider.saveDraft();
      context.push('/onboarding/step3');
    }
  }

  Widget _buildPhotoUploadButton(BuildContext context, String label, String type, OnboardingProvider provider) {
    File? imageFile;
    String? existingUrl;
    if (type == 'pan') { imageFile = provider.panImage; existingUrl = provider.existingPanUrl; }
    if (type == 'tax') { imageFile = provider.taxImage; existingUrl = provider.existingTaxUrl; }
    if (type == 'fssai') { imageFile = provider.fssaiImage; existingUrl = provider.existingFssaiUrl; }

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
              onTap: () => provider.removeImage(type),
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
                    provider.pickImage(type, source: ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.pickImage(type, source: ImageSource.gallery);
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
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
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
      appBar: const OnboardingAppBar(step: 2),
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
                        'Legal & Tax Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This information is required by the Government of India.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // PAN CARD (Mandatory)
                      Text('PAN Card Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      PremiumTextField(
                        label: 'PAN Number',
                        controller: provider.panNumberController,
                        hintText: 'Enter 10-digit PAN',
                        prefixIcon: const Icon(Icons.credit_card_outlined, size: 20, color: AppColors.grey400),
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                          UpperCaseTextFormatter(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPhotoUploadButton(context, 'Upload PAN Card Photo', 'pan', provider),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),

                      // GST / Enrolment
                      Text('Tax Registration', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Text(
                              'Do you have a GST Number?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: provider.taxRegistrationType,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'GSTIN', child: Text('Yes, I have a GST Number', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'EnrolmentNumber', child: Text('No, I have an Enrolment ID', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'NeedsHelp', child: Text('No, I need help getting one', style: TextStyle(fontSize: 14))),
                            ],
                            onChanged: (val) {
                              if (val != null) provider.setTaxRegistrationType(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.taxRegistrationType != 'NeedsHelp') ...[
                        PremiumTextField(
                          label: provider.taxRegistrationType == 'GSTIN' ? 'GST Number' : 'Enrolment ID',
                          controller: provider.taxNumberController,
                          hintText: 'Enter Document Number',
                          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.grey400),
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(provider.taxRegistrationType == 'GSTIN' ? 15 : 20),
                            UpperCaseTextFormatter(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPhotoUploadButton(
                          context, 
                          'Upload ${provider.taxRegistrationType == 'GSTIN' ? 'GST' : 'Enrolment'} Certificate', 
                          'tax', 
                          provider
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Don\'t worry! You can complete your application now, and our agent will call you to help you get a free Enrolment ID.', style: TextStyle(color: Colors.orange.shade900))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 32),

                      // FSSAI
                      Text('Food Safety (FSSAI)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0, bottom: 4.0),
                            child: Text(
                              'Do you have an FSSAI Certificate?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: provider.fssaiStatus,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Have', child: Text('Yes, I have FSSAI Registration', style: TextStyle(fontSize: 14))),
                              DropdownMenuItem(value: 'NeedsHelp', child: Text('No, I need help getting one', style: TextStyle(fontSize: 14))),
                            ],
                            onChanged: (val) {
                              if (val != null) provider.setFssaiStatus(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (provider.fssaiStatus == 'Have') ...[
                        PremiumTextField(
                          label: '14-Digit FSSAI Number',
                          controller: provider.fssaiNumberController,
                          hintText: 'Enter FSSAI Number',
                          prefixIcon: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.grey400),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(14),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPhotoUploadButton(context, 'Upload FSSAI Certificate', 'fssai', provider),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.help_outline, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(child: Text('An FSSAI Basic Registration costs ₹100/year. Our agent will help you get it registered easily!', style: TextStyle(color: Colors.orange.shade900))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: PrimaryButton(text: 'Continue', onPressed: _nextStep),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
