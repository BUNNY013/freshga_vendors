import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';

class BusinessDetailsScreen extends StatelessWidget {
  const BusinessDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Stored Data (simulating fetched DB state)
    final String savedOwnerName = "Saraswathi Devi";
    final String savedBusinessType = "Home Based Business";
    final String savedExperience = "5+ Years";
    final String savedEmail = "hello@ammassecrets.com";
    final String savedPhone = "9876543210";
    final String savedGst = "";
    final String savedFssai = "21220183001524";
    final String savedAddress = "Plot 42, Jubilee Hills Road No. 36\nHyderabad, Telangana 500033";
    
    // Verification states
    final bool isFssaiVerified = true;
    final bool isEmailVerified = true;
    final bool isPhoneVerified = true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Business Details',
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
                  Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your business identity is protected. Essential details are locked after verification to ensure platform trust and safety.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Core Details Card
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
                  const Text('Business Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
                  const SizedBox(height: 24),
                  _buildViewRow(Icons.person_outline, 'Owner Name', savedOwnerName),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.storefront_outlined, 'Business Type', savedBusinessType),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.workspace_premium_outlined, 'Experience', savedExperience),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contact & Compliance Card
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
                  const Text('Contact & Compliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
                  const SizedBox(height: 24),
                  _buildViewRow(Icons.phone_outlined, 'Phone Number', '+91 $savedPhone', isVerified: isPhoneVerified),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.email_outlined, 'Email Address', savedEmail, isVerified: isEmailVerified),
                  const SizedBox(height: 20),
                  _buildViewRow(
                    Icons.security_outlined, 
                    'FSSAI License', 
                    savedFssai.isNotEmpty ? savedFssai : 'Not provided', 
                    isVerified: savedFssai.isNotEmpty ? isFssaiVerified : false,
                    bottomWidget: savedFssai.isNotEmpty ? _buildDocumentAction(context, 'View FSSAI Certificate', 'https://images.unsplash.com/photo-1618044733300-9472054094ee') : null,
                  ),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.receipt_long_outlined, 'GST Number', savedGst.isNotEmpty ? savedGst : 'Not provided', isVerified: false, showVerifyBadge: false),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Registered Premises Card
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
                  const Text('Registered Premises', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  const Text('This is your official pickup address tied to your FSSAI license.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  _buildViewRow(Icons.location_on_outlined, 'Pickup Location', savedAddress, isVerified: true),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRow(IconData icon, String label, String value, {bool isVerified = false, bool showVerifyBadge = true, Widget? bottomWidget}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(value, style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                  ),
                  if (showVerifyBadge && isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Verified', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              if (bottomWidget != null) bottomWidget,
            ],
          ),
        ),
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
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
