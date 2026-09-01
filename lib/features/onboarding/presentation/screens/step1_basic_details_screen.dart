import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../widgets/primary_button.dart';
import 'location_picker_screen.dart';

class Step1BasicDetailsScreen extends StatefulWidget {
  const Step1BasicDetailsScreen({super.key});

  @override
  State<Step1BasicDetailsScreen> createState() =>
      _Step1BasicDetailsScreenState();
}

class _Step1BasicDetailsScreenState extends State<Step1BasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 
    'Delhi', 'Lakshadweep', 'Puducherry', 'Jammu and Kashmir', 'Ladakh'
  ];

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<OnboardingProvider>();
      if (provider.latitude == null || provider.longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pin your location on the map')),
        );
        return;
      }
      provider.saveDraft();
      context.push('/onboarding/step2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const OnboardingAppBar(step: 1),
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
                        'Business Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s start with the basics of your business.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 32),
                      PremiumTextField(
                        label: 'Owner Full Name',
                        isRequired: true,
                        controller: provider.fullNameController,
                        hintText: 'Enter owner full name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.grey400),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(50),
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s\.\-]')),
                        ],
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Business Name',
                        isRequired: true,
                        controller: provider.businessNameController,
                        hintText: 'Enter your business name',
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 20, color: AppColors.grey400),
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Phone Number',
                        isRequired: true,
                        controller: provider.phoneController,
                        keyboardType: TextInputType.phone,
                        readOnly: true, // Phone is prefilled and read-only
                        hintText: 'XXXXX XXXXX',
                        prefixText: '+91 ',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.grey400),
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Alternate Phone Number',
                        controller: provider.alternatePhoneController,
                        keyboardType: TextInputType.phone,
                        hintText: 'Enter alternate phone number',
                        prefixText: '+91 ',
                        prefixIcon: const Icon(Icons.phone_android_outlined, size: 20, color: AppColors.grey400),
                        isRequired: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 10) {
                            return 'Enter valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Email Address',
                        controller: provider.emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your email address',
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.grey400),
                        isRequired: false,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: AppColors.grey300),
                      const SizedBox(height: 32),
                      Text(
                        'Business Address',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'Address Details (Door No, Building, Street)',
                        isRequired: true,
                        controller: provider.businessAddressController,
                        hintText: 'Enter permanent business address',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.grey400),
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(200),
                        ],
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PremiumTextField(
                              label: 'Pincode',
                              isRequired: true,
                              controller: provider.pincodeController,
                              keyboardType: TextInputType.number,
                              hintText: 'Enter pincode',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.length != 6) return 'Invalid pincode';
                                return null;
                              },
                              suffixIcon: provider.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PremiumTextField(
                              label: 'City/Block',
                              isRequired: true,
                              controller: provider.cityController,
                              hintText: 'Enter city or block',
                              readOnly: provider.isLocationFetched,
                              textCapitalization: TextCapitalization.words,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(50),
                              ],
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      if (provider.error != null && provider.error!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Text(
                            '${provider.error}. Please enter your details manually.',
                            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                      ],
                      PremiumTextField(
                        label: 'Village/Area',
                        isRequired: true,
                        controller: provider.villageController,
                        hintText: 'Enter village or area',
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      PremiumTextField(
                        label: 'District',
                        isRequired: true,
                        controller: provider.districtController,
                        hintText: 'Enter district',
                        readOnly: provider.isLocationFetched,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(50),
                        ],
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      provider.isLocationFetched
                          ? PremiumTextField(
                              label: 'State',
                              isRequired: true,
                              controller: provider.stateController,
                              hintText: 'Enter state',
                              readOnly: true,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                                  child: RichText(
                                    text: const TextSpan(
                                      text: 'State',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _indianStates.contains(provider.stateController.text) ? provider.stateController.text : null,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.grey300, width: 1.0)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                  ),
                                  hint: const Text('Select State', style: TextStyle(fontSize: 14, color: AppColors.grey400)),
                                  items: _indianStates.map((state) {
                                    return DropdownMenuItem(
                                      value: state, 
                                      child: Text(
                                        state, 
                                        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        provider.stateController.text = val;
                                      });
                                    }
                                  },
                                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                ),
                              ],
                            ),
                            
                      // Location Picker Button Moved inside SingleChildScrollView
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final latLng = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocationPickerScreen(
                                initialLat: provider.latitude,
                                initialLng: provider.longitude,
                              ),
                            ),
                          );
                          if (latLng != null) {
                            provider.latitude = latLng.latitude;
                            provider.longitude = latLng.longitude;
                            provider.saveDraft();
                            setState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: provider.latitude != null ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: provider.latitude != null ? Colors.green : AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                provider.latitude != null ? Icons.check_circle : Icons.pin_drop,
                                color: provider.latitude != null ? Colors.green : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.latitude != null ? 'Location Pinned' : 'Pin Location on Map *',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: provider.latitude != null ? Colors.green[800] : AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (provider.latitude != null)
                                      Text(
                                        '${provider.latitude!.toStringAsFixed(4)}, ${provider.longitude!.toStringAsFixed(4)}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: provider.latitude != null ? Colors.green : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
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
