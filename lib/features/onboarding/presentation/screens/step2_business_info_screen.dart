import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/onboarding_app_bar.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class Step2BusinessInfoScreen extends StatefulWidget {
  const Step2BusinessInfoScreen({super.key});

  @override
  State<Step2BusinessInfoScreen> createState() =>
      _Step2BusinessInfoScreenState();
}

class _Step2BusinessInfoScreenState extends State<Step2BusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    'Pickles',
    'Sweets',
    'Snacks',
    'Honey',
    'Cookies',
    'Masalas',
    'Chutneys',
    'Bakery',
  ];

  final List<String> _dispatchTimes = [
    'Same Day',
    '24 Hours',
    '2 Days',
    '3–5 Days',
  ];

  void _nextStep() {
    final provider = context.read<OnboardingProvider>();
    if (_formKey.currentState!.validate()) {
      if (provider.selectedFoodCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one food category'),
          ),
        );
        return;
      }
      if (provider.selectedDispatchTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a dispatch time')),
        );
        return;
      }

      provider.saveDraft();
      context.push('/onboarding/step3');
    }
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
                        'Tell customers what makes your food special ❤️',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Business Description',
                        controller: provider.businessDescController,
                        hintText: 'Describe your food and story...',
                        maxLines: 4,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          text: 'Food Categories',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = provider.selectedFoodCategories
                              .contains(category);
                          return ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            onSelected: (selected) {
                              provider.toggleCategory(category);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      RichText(
                        text: TextSpan(
                          text: 'Dispatch Time',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dispatchTimes.map((time) {
                          final isSelected =
                              provider.selectedDispatchTime == time;
                          return ChoiceChip(
                            label: Text(time),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                provider.setDispatchTime(time);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),

                      CustomTextField(
                        label: 'Experience (Years)',
                        controller: provider.experienceController,
                        hintText: 'E.g., 5 Years',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
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
