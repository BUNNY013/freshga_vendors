import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
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
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
    _images = List<String>.from(_product.images);
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSaving = true);
    try {
      final provider = context.read<ProductProvider>();
      await provider.updateDraftContent(
        widget.product,
        {'images': _images},
        clearRequiredFix: 'photos',
      );
      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved to draft.')));
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
            if (index != 0)
              ListTile(
                leading: const Icon(Icons.star_outline, color: Color(0xFF111827)),
                title: const Text('Set As Cover', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    final img = _images.removeAt(index);
                    _images.insert(0, img);
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.find_replace, color: Color(0xFF111827)),
              title: const Text('Replace Photo', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Replace not implemented in MVP')));
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
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String imgUrl, int index, bool isCover) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
          ),
        ),
        if (isCover && !_isReordering)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
              child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        if (_isReordering)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                child: Text(isCover ? 'Cover' : '${index + 1}', style: const TextStyle(color: Color(0xFF111827), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        if (!_isReordering)
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
        
        Widget card = _buildPhotoCard(imgUrl, index, isCover);
        
        if (!_isReordering) {
          return card;
        }

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) {
            setState(() {
              final draggedItem = _images.removeAt(details.data);
              _images.insert(index, draggedItem);
            });
          },
          builder: (context, candidateData, rejectedData) {
            return LongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: (MediaQuery.of(context).size.width - 32 - 12) / 2,
                height: (MediaQuery.of(context).size.width - 32 - 12) / 2,
                child: Material(
                  color: Colors.transparent,
                  child: Opacity(opacity: 0.8, child: _buildPhotoCard(imgUrl, index, isCover)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: card),
              child: card,
            );
          },
        );
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

    return Scaffold(
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    SizedBox(width: 8),
                    Text('(Drag to reorder)', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
                InkWell(
                  onTap: () {
                    if (_isReordering) {
                      setState(() => _isReordering = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo order updated successfully')));
                    } else {
                      setState(() => _isReordering = true);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        Text(_isReordering ? 'Done' : 'Reorder', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600, fontSize: 14)),
                        if (!_isReordering) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.tune, color: Color(0xFF16A34A), size: 18),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Photos'),
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
                onTap: () {},
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
                          child: const Icon(Icons.add, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(height: 12),
                        const Text('Upload More Photos', style: TextStyle(color: Color(0xFF16A34A), fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('You can add up to 10 photos (${_images.length} / 10 uploaded)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFF16A34A), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tips for better results', style: TextStyle(color: Color(0xFF16A34A), fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Good lighting, clean background and multiple angles help customers trust your product.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save to Draft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Content updates require admin review before going live.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
