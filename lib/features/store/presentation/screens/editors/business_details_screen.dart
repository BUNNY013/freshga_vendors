import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/app_colors.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  bool _isLoading = true;
  String _savedOwnerName = "";
  String _savedEmail = "";
  String _savedPhone = "";
  String _taxType = "";
  String _savedGst = "";
  String _savedFssai = "";
  String _savedAddress = "";
  String _savedVillage = "";
  String _savedDistrict = "";
  String _savedCity = "";
  String _savedState = "";
  String _savedPincode = "";
  String _fssaiUrl = "";
  String _taxUrl = "";
  
  // Verification states
  final bool _isFssaiVerified = true;
  final bool _isEmailVerified = true;
  final bool _isPhoneVerified = true;

  @override
  void initState() {
    super.initState();
    _fetchBusinessDetails();
  }

  Future<void> _fetchBusinessDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('supplierApplications')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            _savedOwnerName = data['fullName'] ?? '';
            _savedEmail = data['email'] ?? '';
            _savedPhone = data['phone'] ?? '';
            _taxType = data['taxRegistrationType'] ?? 'GST Number';
            _savedGst = data['taxNumber'] ?? '';
            _savedFssai = data['fssaiNumber'] ?? '';
            _fssaiUrl = data['fssaiCertificateImage'] ?? '';
            _taxUrl = data['taxImage'] ?? '';
            _savedAddress = data['businessAddress'] ?? '';
            _savedVillage = data['village'] ?? '';
            _savedDistrict = data['district'] ?? '';
            _savedCity = data['city'] ?? '';
            _savedState = data['state'] ?? '';
            _savedPincode = data['pincode'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching business details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

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
                  _buildViewRow(Icons.person_outline, 'Owner Name', _savedOwnerName),
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
                  _buildViewRow(Icons.phone_outlined, 'Phone Number', _savedPhone.isNotEmpty ? _savedPhone : 'Not provided', isVerified: _savedPhone.isNotEmpty ? _isPhoneVerified : false),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.email_outlined, 'Email Address', _savedEmail.isNotEmpty ? _savedEmail : 'Not provided', isVerified: _savedEmail.isNotEmpty ? _isEmailVerified : false),
                  const SizedBox(height: 20),
                  _buildViewRow(
                    Icons.security_outlined, 
                    'FSSAI License', 
                    _savedFssai.isNotEmpty ? _savedFssai : 'Not provided', 
                    isVerified: _savedFssai.isNotEmpty ? _isFssaiVerified : false,
                    bottomWidget: _savedFssai.isNotEmpty && _fssaiUrl.isNotEmpty ? _buildDocumentAction(context, 'View FSSAI Certificate', _fssaiUrl) : null,
                  ),
                  const SizedBox(height: 20),
                  _buildViewRow(
                    Icons.receipt_long_outlined, 
                    _taxType.isNotEmpty ? _taxType : 'Tax Registration', 
                    _savedGst.isNotEmpty ? _savedGst : 'Not provided', 
                    isVerified: false, 
                    showVerifyBadge: false,
                    bottomWidget: _savedGst.isNotEmpty && _taxUrl.isNotEmpty ? _buildDocumentAction(context, 'View Tax Document', _taxUrl) : null,
                  ),
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
                  _buildViewRow(Icons.home_outlined, 'Address Details', _savedAddress.isNotEmpty ? _savedAddress : 'Not provided', isVerified: true),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.map_outlined, 'Village / Area', _savedVillage.isNotEmpty ? _savedVillage : 'Not provided', showVerifyBadge: false),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.location_city_outlined, 'District', _savedDistrict.isNotEmpty ? _savedDistrict : 'Not provided', showVerifyBadge: false),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.location_city_outlined, 'City / Block', _savedCity.isNotEmpty ? _savedCity : 'Not provided', showVerifyBadge: false),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.map_outlined, 'State', _savedState.isNotEmpty ? _savedState : 'Not provided', showVerifyBadge: false),
                  const SizedBox(height: 20),
                  _buildViewRow(Icons.pin_drop_outlined, 'Pincode', _savedPincode.isNotEmpty ? _savedPincode : 'Not provided', showVerifyBadge: false),
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
