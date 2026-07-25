import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

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
      context.read<OnboardingProvider>().saveDraft();
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
                        'Let’s start with your business basics ✨',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Owner Full Name',
                        controller: provider.fullNameController,
                        hintText: 'Enter owner full name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Business Name',
                        controller: provider.businessNameController,
                        hintText: 'Enter your business name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Phone Number',
                        controller: provider.phoneController,
                        keyboardType: TextInputType.phone,
                        readOnly: true, // Phone is prefilled and read-only
                        hintText: 'XXXXX XXXXX',
                        prefixText: '+91 ',
                      ),
                      CustomTextField(
                        label: 'Alternate Phone Number',
                        controller: provider.alternatePhoneController,
                        keyboardType: TextInputType.phone,
                        hintText: 'Enter alternate phone number',
                        prefixText: '+91 ',
                        isRequired: false,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 10) {
                            return 'Enter valid phone number';
                          }
                          return null;
                        },
                      ),
                      CustomTextField(
                        label: 'Email Address',
                        controller: provider.emailController,
                        keyboardType: TextInputType.emailAddress,
                        hintText: 'Enter your email address',
                        isRequired: false,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Business Address',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Address Details (Door No, Building, Street)',
                        controller: provider.businessAddressController,
                        hintText: 'Enter permanent business address',
                        maxLines: 2,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'Pincode',
                        controller: provider.pincodeController,
                        keyboardType: TextInputType.number,
                        hintText: 'Enter 6-digit pincode',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length != 6) return 'Enter valid pincode';
                          return null;
                        },
                        suffixIcon: provider.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      if (provider.error != null && provider.error!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            '${provider.error}. Please enter your details manually.',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                      CustomTextField(
                        label: 'Village/Area',
                        controller: provider.villageController,
                        hintText: 'Enter village or area',
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'City/Block',
                        controller: provider.cityController,
                        hintText: 'Enter city or block',
                        readOnly: provider.isLocationFetched,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      CustomTextField(
                        label: 'District',
                        controller: provider.districtController,
                        hintText: 'Enter district',
                        readOnly: provider.isLocationFetched,
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      provider.isLocationFetched
                          ? CustomTextField(
                              label: 'State',
                              controller: provider.stateController,
                              hintText: 'Enter state',
                              readOnly: true,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('State', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _indianStates.contains(provider.stateController.text) ? provider.stateController.text : null,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  hint: const Text('Select State', style: TextStyle(fontSize: 14)),
                                  items: _indianStates.map((state) {
                                    return DropdownMenuItem(value: state, child: Text(state, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)));
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
                                const SizedBox(height: 16),
                              ],
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
