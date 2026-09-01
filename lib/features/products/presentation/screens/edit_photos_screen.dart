import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../../utils/product_change_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class EditPhotosScreen extends StatefulWidget {
  final ProductModel product;

  const EditPhotosScreen({super.key, required this.product});

  @override
  State<EditPhotosScreen> createState() => _EditPhotosScreenState();
}

class _EditPhotosScreenState extends State<EditPhotosScreen> {
  late ProductModel _product;
  bool _isSaving = false;
  late List<String> _images;
  late List<String> _originalApprovedImages;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
    _images = List<String>.from(_product.images);
    _originalApprovedImages = List<String>.from(widget.product.images);
  }

  bool get _isLocked => widget.product.status == 'Under Review' || widget.product.status == 'Live + Update Pending';

  bool get _hasNewUploads => _images.any((img) => !_originalApprovedImages.contains(img));

  bool get _hasChanges {
    final original = widget.product.applyDraftUpdates().images;
    if (_images.length != original.length) return true;
    for (int i = 0; i < _images.length; i++) {
      if (_images[i] != original[i]) return true;
    }
    return false;
  }

  bool get _canSave => _hasChanges && !_isSaving && !_isLocked;

  Future<void> _saveInstantPhotoChange(String message) async {
    try {
      final provider = context.read<ProductProvider>();
      await provider.updateOperationalFields(
        widget.product.productId,
        {'images': _images},
        clearRequiredFix: 'photos',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      
      final req = await provider.updateDraftContent(
        widget.product,
        {'images': _images},
        clearRequiredFix: 'photos',
      );
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (req == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to save changes. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        context.pop();
        
        if (widget.product.status == 'Changes Required' || req == ReviewRequirement.noReview) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos updated successfully.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New photos submitted for review! Existing approved photos remain live on your store.'),
              backgroundColor: Color(0xFF2563EB),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showPhotoMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            if (index != 0 && _originalApprovedImages.contains(_images[index]))
              ListTile(
                leading: const Icon(Icons.star_outline, color: Color(0xFF111827)),
                title: const Text('Set As Cover', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final img = _images.removeAt(index);
                    _images.insert(0, img);
                  });
                  if (!_hasNewUploads) {
                    _saveInstantPhotoChange('✓ Cover photo updated successfully! ⚡');
                  }
                },
              )
            else if (index != 0 && !_originalApprovedImages.contains(_images[index]))
              ListTile(
                leading: const Icon(Icons.star_outline, color: Colors.grey),
                title: const Text('Set As Cover', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                subtitle: const Text('Cannot set as cover until verified by admin', style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pending review images cannot be chosen as cover photo until verified by admin.'),
                      backgroundColor: Color(0xFF2563EB),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Photo', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                if (_images.length <= 1) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least 1 photo is required')));
                  return;
                }
                setState(() => _images.removeAt(index));
                if (!_hasNewUploads) {
                  _saveInstantPhotoChange('✓ Photo removed successfully! ⚡');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadNewPhotos() async {
    if (_images.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 10 photos allowed')));
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 85);
      if (picked.isEmpty) return;

      setState(() => _isUploading = true);

      List<String> uploadedUrls = [];
      for (int i = 0; i < picked.length; i++) {
        if (_images.length + uploadedUrls.length >= 10) break;
        final xFile = picked[i];
        final isCover = _images.isEmpty && uploadedUrls.isEmpty;
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: xFile.path,
          maxWidth: 1080,
          maxHeight: 1080,
          compressQuality: 80,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: isCover ? 'Crop Cover Photo (1:1)' : 'Crop Product Photo (1:1)',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: isCover ? 'Crop Cover Photo (1:1)' : 'Crop Product Photo (1:1)',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final file = File(croppedFile.path);
          final ref = FirebaseStorage.instance.ref().child(
            'product_images/${widget.product.productId}/image_new_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          final snapshot = await ref.putFile(file);
          final downloadUrl = await snapshot.ref.getDownloadURL();
          uploadedUrls.add(downloadUrl);
        }
      }

      if (mounted) {
        setState(() {
          _images.addAll(uploadedUrls);
          _isUploading = false;
        });
        if (uploadedUrls.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photos uploaded! Tap "Submit New Photos" in top-right to request admin review.'),
              backgroundColor: Color(0xFF2563EB),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading photos: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildPhotoCard(String imgUrl, int index, bool isCover) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: imgUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 400, // optimize memory and load speed
            placeholder: (context, url) => Container(color: Colors.grey.shade200),
            errorWidget: (context, url, error) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
        ),
        if (isCover)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        if (!_originalApprovedImages.contains(imgUrl))
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Pending Review', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _showPhotoMenu(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
              child: const Icon(Icons.more_horiz, color: Color(0xFF111827), size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final imgUrl = _images[index];
        final isCover = index == 0;
        return _buildPhotoCard(imgUrl, index, isCover);
      },
    );
  }

  Widget _buildGuidelineCheck(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, color: Color(0xFF16A34A), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF374151), fontSize: 13))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackData = _product.reviewFeedback?['photos'];
    final bool isNeedsFix = feedbackData?['status'] == 'needs_fix';
    final String feedbackMsg = feedbackData?['feedback'] ?? 'Please update the photos as requested.';

    return PopScope(
      canPop: !_hasChanges || _isSaving,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Editing')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard Changes', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (discard == true && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product Photos', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          if (_hasNewUploads)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSubmit,
                icon: const Icon(Icons.shield_outlined, size: 14),
                label: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit New Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNeedsFix) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Changes Required', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(feedbackMsg, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
            const SizedBox(height: 16),
            
            if (_images.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                        child: const Icon(Icons.photo_library_outlined, size: 40, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 16),
                      const Text('No photos uploaded yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      const SizedBox(height: 8),
                      const Text('Add product photos to help customers\nunderstand your product better.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadNewPhotos,
                        icon: _isUploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add, size: 18),
                        label: Text(_isUploading ? 'Uploading...' : 'Add Photos'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                      )
                    ],
                  ),
                ),
              )
            else
              _buildPhotoGrid(),

            if (_images.length < 10) ...[
              const SizedBox(height: 24),
              InkWell(
                onTap: _isUploading ? null : _pickAndUploadNewPhotos,
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: DashedRectPainter(color: const Color(0xFFE5E7EB), strokeWidth: 1.5, gap: 5.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                          child: _isUploading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)))
                              : const Icon(Icons.add, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isUploading ? 'Uploading Photos...' : 'Upload More Photos',
                          style: const TextStyle(color: Color(0xFF16A34A), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isUploading
                              ? 'Please wait while we crop & upload your images'
                              : 'You can add up to 10 photos (${_images.length} / 10 uploaded)',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Text('Photo Guidelines', style: TextStyle(color: Color(0xFF16A34A), fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGuidelineCheck('Use high quality images (1080px or more)'),
                  _buildGuidelineCheck('Show product from multiple angles'),
                  _buildGuidelineCheck('Avoid text, logos or watermarks'),
                  _buildGuidelineCheck('Maximum 10 photos allowed'),
                ],
              ),
            ),


            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: !_hasNewUploads
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSubmit,
                  icon: const Icon(Icons.shield_outlined, size: 20),
                  label: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Submit New Photos for Review',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
    ));
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    
    PathMetrics pathMetrics = path.computeMetrics();
    Path dashedPath = Path();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
