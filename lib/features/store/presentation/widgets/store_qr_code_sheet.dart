import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';

class StoreQrCodeSheet extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String storeSlug;

  const StoreQrCodeSheet({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.storeSlug,
  });

  @override
  State<StoreQrCodeSheet> createState() => _StoreQrCodeSheetState();
}

class _StoreQrCodeSheetState extends State<StoreQrCodeSheet> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  void _shareLink() {
    Share.share(
      'Check out ${widget.storeName} on FreshGa!\n\nhttps://freshga-homemades.web.app/store/${widget.storeId}',
      subject: 'Check out this store!',
    );
  }

  void _shareQrCode() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    
    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 3.0, // High quality
      );
      
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/${widget.storeId}_qrcode.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Scan this QR code to visit ${widget.storeName} on FreshGa Homemades!',
          subject: 'Store QR Code',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share QR code: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Screenshot area
          Screenshot(
            controller: _screenshotController,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1054 / 1492,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 1054,
                    height: 1492,
                    child: Stack(
                      children: [
                        // Background Template
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/store_qr_sheet.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // QR Code Safe Area
                        Positioned(
                          top: 530, // Shifted down
                          left: 0,
                          right: 30, // Shifted left
                          child: Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 600, // Safe area
                              height: 600, // Safe area
                              child: Center(
                                child: QrImageView(
                                  data: 'https://freshga-homemades.web.app/store/${widget.storeId}',
                                  version: QrVersions.auto,
                                  size: 560.0,
                                  backgroundColor: Colors.transparent,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF2B3A2C), // Very dark green/black
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF2B3A2C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Store Handle / Name
                        Positioned(
                          bottom: 195, // Shifted further down to perfectly align with the template
                          left: 0,
                          right: 0,
                          child: Text(
                            '@${widget.storeSlug}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 48, // Reduced from 54 to fit beautifully between the leaves
                              fontWeight: FontWeight.w600, // Semi-Bold
                              color: Color(0xFF234B28), // Deep green to match the FreshGa branding
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _shareLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Share Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareQrCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: _isSharing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.qr_code_2_rounded),
                    label: Text(
                      _isSharing ? 'Loading...' : 'Share QR',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
