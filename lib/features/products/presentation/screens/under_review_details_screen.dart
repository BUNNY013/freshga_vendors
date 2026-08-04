import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

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

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _handleWithdrawSubmission(BuildContext context) async {
    final bool isUpdate = product.status == 'Update Under Review' || product.status == 'Live + Update Pending';
    final title = isUpdate ? 'Withdraw Pending Update?' : 'Withdraw Review Submission?';
    final content = isUpdate
        ? 'Are you sure you want to withdraw this pending update? Your live product will remain active on the store without changes.'
        : 'Are you sure you want to withdraw this submission from the review queue? You can edit and resubmit anytime.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(height: 1.4, color: Color(0xFF475569))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ProductProvider>();
      final success = await provider.withdrawSubmission(product);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Submission withdrawn successfully. Ready for new edits! ⚡'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          _safePop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${provider.errorMessage}')),
          );
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
          onPressed: () => _safePop(context),
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
                _buildLiveReassuranceBanner(),
                _buildHeaderCard(),
                const SizedBox(height: 24),

                _buildSubmittedScopeCard(context),
                const SizedBox(height: 24),
                
                _buildVerticalTimelineStepper(),
                const SizedBox(height: 24),

                _buildAuditChecklistCard(),
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
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFEA580C)),
              SizedBox(width: 12),
              Text('Need to make changes?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF9A3412))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you want to update something while in review, withdraw this submission using the button below, make your changes, and resubmit.',
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
          ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Need to edit or cancel this review request?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleWithdrawSubmission(context),
            icon: const Icon(Icons.undo_rounded, size: 20),
            label: const Text(
              'Withdraw Submission',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF9A3412),
              backgroundColor: const Color(0xFFFFEDD5),
              elevation: 0,
              side: const BorderSide(color: Color(0xFFFDBA74), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveReassuranceBanner() {
    final bool isUpdate = product.status == 'Update Under Review' || product.status == 'Live + Update Pending';
    if (!isUpdate) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🟢 Live on Store',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  'Your current approved version remains active and shoppable for customers while this update is audited.',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedScopeCard(BuildContext context) {
    final bool isUpdate = product.status == 'Update Under Review' || 
                          product.status == 'Live + Update Pending' || 
                          product.lastApprovedAt != null;

    if (isUpdate) {
      return _buildUpdateDiffCard(context);
    } else {
      return _buildNewProductDossierCard(context);
    }
  }

  Widget _buildUpdateDiffCard(BuildContext context) {
    final pending = product.pendingReviewVersion ?? product.pendingUpdate ?? {};
    final imagesList = (pending['images'] != null && (pending['images'] as List).isNotEmpty)
        ? List<String>.from(pending['images'])
        : product.images;
    final category = pending['categoryName'] ?? product.categoryName;
    
    final String? newName = pending['name'] as String?;
    final bool nameChanged = newName != null && newName != product.name;

    final String? newDesc = pending['description'] as String?;
    final bool descChanged = newDesc != null && newDesc != product.description;

    final String? newCat = pending['categoryName'] as String?;
    final bool catChanged = newCat != null && newCat != product.categoryName;

    final dynamic newPrice = pending['price'];
    final bool priceChanged = newPrice != null && (newPrice is num ? newPrice.toDouble() : double.tryParse(newPrice.toString()) ?? product.price) != product.price;

    final String? newShelf = pending['shelfLife'] as String?;
    final bool shelfChanged = newShelf != null && newShelf != product.shelfLife;

    final List? newTags = pending['tags'] as List?;
    final bool tagsChanged = newTags != null && newTags.join(', ') != product.tags.join(', ');

    final bool imagesChanged = pending['images'] != null && (pending['images'] as List).join(',') != product.images.join(',');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.difference_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted Modifications (Diff vs. Live Store)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Auditing changes to your live store product',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          if (nameChanged) ...[
            _buildDiffRow('Title Modified', product.name, newName!),
            const SizedBox(height: 14),
          ],

          if (catChanged) ...[
            _buildDiffRow('Category Modified', product.categoryName, newCat!),
            const SizedBox(height: 14),
          ],

          if (priceChanged) ...[
            _buildDiffRow('Price Modified', '₹${product.price.toStringAsFixed(0)}', '₹${newPrice.toString()}'),
            const SizedBox(height: 14),
          ],

          if (shelfChanged) ...[
            _buildDiffRow('Shelf Life / Prep Time Modified', product.shelfLife, newShelf!),
            const SizedBox(height: 14),
          ],

          if (tagsChanged) ...[
            _buildDiffRow('Collections / Tags Modified', product.tags.join(', '), newTags.join(', ')),
            const SizedBox(height: 14),
          ],

          if (descChanged) ...[
            const Text(
              'DESCRIPTION UPDATED',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
                        child: const Text('New Submitted Description', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(newDesc!, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          if (imagesChanged) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBMITTED PHOTOS GALLERY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    'Updated (${product.images.length} ➔ ${imagesList.length} photos)',
                    style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: imagesList.isEmpty
                  ? Center(child: Text('No photos submitted', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imagesList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final url = imagesList[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                              if (index == 0)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
                                    child: const Text(
                                      'Cover',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 16, color: Color(0xFF475569)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All other live product settings (photos, category, pricing) remain unchanged.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewProductDossierCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Product Submission Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Complete initial dossier submitted for store approval',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          const Text(
            'SUBMITTED PHOTOS GALLERY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: product.images.isEmpty
                ? Center(child: Text('No photos uploaded', style: TextStyle(color: Colors.grey.shade500)))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final url = product.images[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                            if (index == 0)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
                                  child: const Text(
                                    'Cover',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          const Text(
            'SUBMITTED DESCRIPTION',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              product.description.isEmpty ? 'No description provided' : product.description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
            ),
          ),
          const SizedBox(height: 16),

          if (product.variants.isNotEmpty) ...[
            const Text(
              'SUBMITTED PACK SIZES & PRICING',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.variants.map((v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '${v.label} - ₹${v.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              _buildMiniScopeChip(Icons.category_outlined, 'Category', product.categoryName),
              const SizedBox(width: 10),
              _buildMiniScopeChip(Icons.photo_library_outlined, 'Uploaded Photos', '${product.images.length} photos'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(String label, String oldVal, String newVal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live: $oldVal',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), decoration: TextDecoration.lineThrough),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New: $newVal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScopeChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Quality Audit Checklist',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Avg Turnaround SLA: 2–4 business hours',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          _buildChecklistItem('Photo Quality & Guidelines', 'No watermarks, clear lighting, and authentic food images.'),
          const SizedBox(height: 10),
          _buildChecklistItem('Pricing & Pack Quantities', 'Accurate pack sizes, MRP, and reasonable homemade pricing.'),
          const SizedBox(height: 10),
          _buildChecklistItem('Homemade Standards', 'Authentic ingredient description and hygienic preparation details.'),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
