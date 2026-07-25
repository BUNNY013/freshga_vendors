import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/refund_request_model.dart';

class VendorIssueDetailsScreen extends StatefulWidget {
  final RefundRequestModel issue;

  const VendorIssueDetailsScreen({super.key, required this.issue});

  @override
  State<VendorIssueDetailsScreen> createState() => _VendorIssueDetailsScreenState();
}

class _VendorIssueDetailsScreenState extends State<VendorIssueDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _updateIssueStatus(String status) async {
    setState(() => _isProcessing = true);
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final issueRef = FirebaseFirestore.instance.collection('refund_requests').doc(widget.issue.requestId);
        final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.issue.orderId);

        transaction.update(issueRef, {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(orderRef, {
          'issueStatus': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issue marked as $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showDisputeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispute Issue'),
        content: const Text('Are you sure you want to dispute this claim? This will escalate the issue to FreshGa Support for mediation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateIssueStatus('Disputed');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Dispute'),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Refund'),
        content: const Text('Are you sure you want to accept this claim? The customer will be refunded for the selected items and the amount will be deducted from your payouts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateIssueStatus('Approved by Vendor');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept Refund'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Issue Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(issue.status, style: TextStyle(color: _getStatusColor(issue.status), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Customer Details
            const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (issue.customerPhone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(issue.customerPhone, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                        if (issue.customerAddress.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(issue.customerAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (issue.customerPhone.isNotEmpty)
                    IconButton(
                      onPressed: () async {
                        final uri = Uri.parse('tel:${issue.customerPhone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
                        }
                      },
                      icon: const Icon(Icons.phone, color: AppColors.primary),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Issue Details
            const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason: ${issue.reason}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(issue.description, style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Photos
            if (issue.imageUrls.isNotEmpty) ...[
              const Text('Proof Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: issue.imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, issue.imageUrls[index]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: issue.imageUrls[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Items
            Text('Affected Items (${issue.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: issue.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${item.variantLabel} • Qty: ${item.quantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('₹${(item.price * item.quantity).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Refund Requested', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('₹${issue.refundAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.orange)),
              ],
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: issue.status == 'Pending Vendor' ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ]
        ),
        child: _isProcessing ? const Center(child: CircularProgressIndicator()) : Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _showDisputeDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Dispute'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _showAcceptDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept Refund', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ) : null,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending Vendor': return Colors.orange;
      case 'Approved by Vendor':
      case 'Refund Processed': return Colors.green;
      case 'Disputed': return Colors.red;
      default: return Colors.grey;
    }
  }
}
