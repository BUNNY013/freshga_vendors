import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, String>> _faqs = [
    {
      'q': 'How long does it take to deliver?',
      'a': 'Orders are usually delivered within 3-7 business days depending on your location.',
    },
    {
      'q': 'Do you use preservatives?',
      'a': 'No, we don\'t use any preservatives or artificial colors in our products.',
    },
    {
      'q': 'How should I store the products?',
      'a': 'Store in a cool, dry place. Use clean and dry spoon while handling.',
    },
    {
      'q': 'Do you ship internationally?',
      'a': 'Currently, we only ship within India.',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'FAQ',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Frequently Asked Questions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 24),
            ..._faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              return Column(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0,
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        faq['q']!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      iconColor: const Color(0xFF94A3B8),
                      collapsedIconColor: const Color(0xFF94A3B8),
                      childrenPadding: const EdgeInsets.only(bottom: 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq['a']!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                ],
              );
            }).toList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
                label: const Text('Add New Question', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
