import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';

class BankingDetailsScreen extends StatelessWidget {
  const BankingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Stored Data
    final String savedAccountHolder = "Saraswathi Devi";
    final String savedAccountType = "Savings Account";
    final String savedAccountNumber = "9876543210123";
    final String savedIFSC = "HDFC0001234";
    final String savedBankName = "HDFC Bank";
    final String savedBranch = "Madhapur Branch";
    final String savedCity = "Hyderabad";
    final String savedState = "Telangana";
    final String lastVerified = "May 20, 2026";

    String maskedAccount = savedAccountNumber.length > 4 
      ? '•••• •••• •••• ${savedAccountNumber.substring(savedAccountNumber.length - 4)}'
      : '•••• •••• ••••';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Banking & Payouts',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payout account is securely locked to prevent unauthorized changes. To update your bank details, please contact Support.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // View Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
                  const SizedBox(height: 24),
                  _buildViewRow('Account Holder', savedAccountHolder),
                  const SizedBox(height: 16),
                  _buildViewRow('Account Type', savedAccountType),
                  const SizedBox(height: 16),
                  _buildViewRow('Bank', savedBankName),
                  const SizedBox(height: 16),
                  _buildViewRow('Account Number', maskedAccount),
                  const SizedBox(height: 16),
                  _buildViewRow('IFSC', savedIFSC),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildViewRow('Branch', savedBranch)),
                      Expanded(child: _buildViewRow('City', savedCity)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildViewRow('State', savedState),
                  const SizedBox(height: 24),
                  _buildDocumentAction(context, 'View Cancelled Cheque / Passbook', 'https://images.unsplash.com/photo-1579621970588-a35d0e7ab9b6'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Verification Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verification Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Verified & Active', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 2),
                          Text('Last Verified: $lastVerified', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payout Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payout Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 16),
                  _buildInfoRow('Settlement Schedule', 'Weekly'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                  _buildInfoRow('Currency', 'INR'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                  _buildInfoRow('Platform', 'FreshGa Marketplace'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildDocumentAction(BuildContext context, String title, String url) {
    return GestureDetector(
      onTap: () async {
        if (url.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf?')) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
