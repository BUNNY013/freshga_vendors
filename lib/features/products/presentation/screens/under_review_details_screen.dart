import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';
import '../widgets/product_preview_sheet.dart';

enum _StepState { completed, active, pending }

class UnderReviewDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const UnderReviewDetailsScreen({super.key, required this.product});

  // Determines the index for the stepper
  int _getStepIndex() {
    if (product.status == 'Submitted' || product.status == 'Update Under Review') return 0;
    if (product.status == 'Under Review') return 1;
    if (product.status == 'Approved') return 2;
    if (product.status == 'Live') return 3;
    return 0; // Default
  }

  String _getTimeAgo(String isoString) {
    if (isoString.isEmpty) return 'recently';
    try {
      final date = DateTime.parse(isoString);
      final difference = DateTime.now().difference(date);
      if (difference.inDays > 7) {
         return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'Pending';
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[date.month - 1];
      int hour = date.hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} $month ${date.year}, $hour:$minute $ampm';
    } catch (e) {
      return 'Pending';
    }
  }

  void _handleWithdraw(BuildContext context) async {
    final provider = context.read<ProductProvider>();
    final success = await provider.withdrawSubmission(product);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission withdrawn successfully.')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${provider.errorMessage}')));
      }
    }
  }

  void _handleDelete(BuildContext context) async {
    final bool isUpdate = product.status == 'Update Under Review' || product.status == 'Live + Update Pending';
    final title = isUpdate ? 'Discard Update?' : 'Delete Submission?';
    final content = isUpdate ? 'Are you sure you want to discard this pending update? Your live product will remain unchanged.' : 'Are you sure you want to delete this completely? This action cannot be undone.';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(isUpdate ? 'Discard' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ProductProvider>();
      
      bool success = false;
      if (isUpdate) {
        success = await provider.withdrawSubmission(product);
      } else {
        success = await provider.deleteProduct(product.productId);
      }

      if (context.mounted) {
        if (success) {
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${provider.errorMessage}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Very light grey bg
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Under Review Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                
                _buildVerticalTimelineStepper(),
                const SizedBox(height: 24),

                _buildWhatHappensNextCard(),
                const SizedBox(height: 24),

                _buildProductInformationCard(),
                const SizedBox(height: 24),

                _buildNeedChangesCard(context),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: _buildBottomActions(context),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final double startingPrice = product.variants.isEmpty ? product.price : product.variants.first.price;
    final int packCount = product.variants.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(width: 80, height: 80, color: Colors.grey.shade200),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'From ₹${startingPrice.toStringAsFixed(0)}  •  ${packCount > 0 ? packCount : 1} pack sizes',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        product.status == 'Update Under Review' ? 'Update Under Review' : 'Under Review',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted ${_getTimeAgo(product.updatedAt)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVerticalTimelineStepper() {
    final int currentStep = _getStepIndex();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Status', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 32),
          _buildStepRow(
            title: 'Product Created',
            subtitle: _formatDateTime(product.createdAt),
            description: null,
            state: currentStep >= 0 ? _StepState.completed : _StepState.active,
            isFirst: true,
            isLast: false,
          ),
          _buildStepRow(
            title: 'Submitted',
            subtitle: _formatDateTime(product.updatedAt),
            description: null,
            state: currentStep >= 0 ? _StepState.completed : _StepState.active,
            isFirst: false,
            isLast: false,
          ),
          _buildStepRow(
            title: 'Under Review',
            subtitle: currentStep >= 1 ? _formatDateTime(product.updatedAt) : null,
            description: currentStep == 1 ? 'Our team is reviewing your product.' : null,
            state: currentStep > 1 ? _StepState.completed : (currentStep == 1 ? _StepState.active : _StepState.pending),
            isFirst: false,
            isLast: false,
          ),
          _buildStepRow(
            title: 'Approved',
            subtitle: null,
            description: 'Will be updated within 24 hours.',
            state: currentStep >= 2 ? _StepState.completed : _StepState.pending,
            isFirst: false,
            isLast: true,
          ),
          const SizedBox(height: 16),
          _buildHelpCard(),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    String? subtitle,
    String? description,
    required _StepState state,
    required bool isFirst,
    required bool isLast,
  }) {
    Color circleColor;
    Color borderColor;
    Widget icon;

    if (state == _StepState.completed) {
      circleColor = const Color(0xFFF0FAF3);
      borderColor = const Color(0xFFD6F0E0);
      icon = const Icon(Icons.check, size: 16, color: Color(0xFF198754));
    } else if (state == _StepState.active) {
      circleColor = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFFE4C4);
      icon = const Icon(Icons.hourglass_empty, size: 16, color: Colors.orange);
    } else {
      circleColor = Colors.white;
      borderColor = Colors.grey.shade300;
      icon = Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle));
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Center(child: icon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StepState.completed ? const Color(0xFFD6F0E0) : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 6),
                    Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, color: Color(0xFF198754), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Contact our support if you have any questions.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatHappensNextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // very light orange
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.access_time, color: Color(0xFF334155), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(
                  'Our team is reviewing your product details, images, and information. You\'ll receive a notification once the review is complete (usually within 24 hours).',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInformationCard() {
    // Determine data to show (use pendingUpdate if exists)
    final pending = product.pendingUpdate ?? {};
    
    final category = pending['categoryName'] ?? product.categoryName;
    final imagesList = pending['images'] ?? product.images;
    final photoCount = imagesList.length;
    final description = pending['description'] ?? product.description;
    
    Widget buildRow(IconData icon, String title, Widget content) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                  const SizedBox(height: 6),
                  content,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Product Information', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 24),
          
          buildRow(
            Icons.local_offer_outlined, 
            'Category', 
            Text(category, style: TextStyle(color: Colors.grey.shade700, fontSize: 14))
          ),
          
          buildRow(
            Icons.sell_outlined, 
            'Collections', 
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            )
          ),

          buildRow(
            Icons.layers_outlined, 
            'Pack Sizes', 
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.variants.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text('${v.label} - ₹${v.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            )
          ),

          buildRow(
            Icons.image_outlined, 
            'Photos', 
            Text('$photoCount photos', style: TextStyle(color: Colors.grey.shade700, fontSize: 14))
          ),

          buildRow(
            Icons.description_outlined, 
            'Description', 
            Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5))
          ),
        ],
      ),
    );
  }

  Widget _buildNeedChangesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange),
              const SizedBox(width: 12),
              const Text('Need to make changes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you want to update something, withdraw this submission first, make changes, and resubmit.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _handleWithdraw(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.white,
              ),
              child: const Text('Withdraw Submission', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star_border, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: Keep everything accurate and clear for a faster approval.',
              style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => ProductPreviewSheet.show(context, product),
            icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
            label: const Text('Preview Product'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleDelete(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete Submission'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
