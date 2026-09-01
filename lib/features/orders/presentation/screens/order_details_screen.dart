import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order_model.dart';
import '../widgets/dispatch_bottom_sheet.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;
  final Function(String, Map<String, dynamic>?) onStatusUpdate;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (order.orderStatus.toLowerCase() == 'accepted' || order.orderStatus.toLowerCase() == 'packed')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _showDeclineDialog(context);
                }
              },
              icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
              color: Colors.white,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Cancel Order', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAlertBanners(),
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildCustomerCard(),
            const SizedBox(height: 16),
            _buildItemsCard(),
            const SizedBox(height: 16),
            _buildTimelineCard(),
            const SizedBox(height: 16),
            _buildPaymentSummaryCard(),
            if (order.orderStatus.toLowerCase() == 'delivered') ...[
              const SizedBox(height: 16),
              _buildCustomerFeedbackCard(),
            ],
            const SizedBox(height: 100), // padding for bottom action bar
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context),
    );
  }

  Widget _buildAlertBanners() {
    final List<Widget> banners = [];

    if (order.orderStatus.toLowerCase() == 'declined' && order.rejectionReason.isNotEmpty) {
      banners.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Declined', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    Text(order.rejectionReason, style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (order.isIssueReported) {
      banners.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer Reported Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    Text(order.issueStatus.isNotEmpty ? order.issueStatus : 'Please check customer support tickets.', style: TextStyle(color: Colors.orange.shade900, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(children: banners);
  }

  Widget _buildHeaderCard() {
    Color statusColor;
    switch (order.orderStatus.toLowerCase()) {
      case 'new':
        statusColor = Colors.blue;
        break;
      case 'accepted':
      case 'packed':
        statusColor = Colors.orange;
        break;
      case 'shipped':
        statusColor = Colors.purple;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderId.toUpperCase()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.orderStatus.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMM d, yyyy • h:mm a').format(order.createdAt),
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : 'C', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (order.customerPhone.isNotEmpty)
                      Text(order.customerPhone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              if (order.customerPhone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.call, color: AppColors.primary),
                  onPressed: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                ),
            ],
          ),
          const Divider(height: 32),
          const Text('Delivery Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(order.deliveryAddress, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (order.deliveryLatitude != null && order.deliveryLongitude != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = 'https://www.google.com/maps/search/?api=1&query=${order.deliveryLatitude},${order.deliveryLongitude}';
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.location_on, size: 18),
                label: const Text('View on Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Items (${order.items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.background, child: const Icon(Icons.image, color: Colors.grey)))
                      : Container(
                          width: 48, height: 48, color: AppColors.background, 
                          child: const Icon(Icons.image, color: Colors.grey, size: 24)
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      if (item.variantLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item.variantLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                      const SizedBox(height: 4),
                      Row(
                         children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 8),
                            Text('₹${item.price.toStringAsFixed(2)} each', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                         ],
                      ),
                    ],
                  ),
                ),
                Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    final events = order.timeline;
    if (events.isEmpty) {
      // Fallback timeline for older orders
      return const SizedBox(); 
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...List.generate(events.length, (index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            final time = DateTime.tryParse(event['time'] ?? '');
            
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event['status'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          if (time != null) ...[
                            const SizedBox(height: 2),
                            Text(DateFormat('MMM d, h:mm a').format(time), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                          if (event['note'] != null && event['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(event['note'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', order.subTotal > 0 ? order.subTotal : order.totalAmount),
          if (order.deliveryFee > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Delivery Fee', order.deliveryFee),
          ],
          if (order.taxes > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Taxes', order.taxes),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your Payout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹${(order.totalAmount - order.platformFee).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerFeedbackCard() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where('orderId', isEqualTo: order.orderId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final reviews = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Customer Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...reviews.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final rating = data['rating'] ?? 0;
                final feedback = data['feedback'] ?? '';
                final productName = data['productName'] ?? 'Product';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < rating ? Icons.star : Icons.star_border,
                                color: index < rating ? Colors.orange : Colors.grey.shade300,
                                size: 16,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (feedback.toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "\"$feedback\"",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDeduction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          isDeduction ? '- ₹${amount.abs().toStringAsFixed(2)}' : '₹${amount.toStringAsFixed(2)}', 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDeduction ? Colors.red : AppColors.textPrimary)
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final status = order.orderStatus.toLowerCase();
    
    if (status == 'delivered' || status == 'declined') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (status == 'new') ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDeclineDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _processAction(context, 'Accepted');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ] else if (status == 'accepted') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _processAction(context, 'Packed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.inventory_2_rounded, size: 20, color: Colors.white),
                  label: const Text('Mark as Packed', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ] else if (status == 'packed') ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showDispatchSheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.local_shipping_rounded, size: 20, color: Colors.white),
                  label: const Text('Dispatch Order', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ] else if (status == 'shipped') ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _processAction(context, 'Delivered');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Mark as Delivered', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline Order?'),
        content: Text('Are you sure you want to decline Order #${order.orderId}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              _processAction(context, 'Declined', payload: {'rejectionReason': 'Vendor declined'});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDispatchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => DispatchBottomSheet(
        orderId: order.orderId,
        onDispatch: (payload) async {
          Navigator.pop(sheetContext); // Close bottom sheet
          _processAction(context, 'Shipped', payload: payload);
        },
      ),
    );
  }

  void _processAction(BuildContext context, String newStatus, {Map<String, dynamic>? payload, bool closeDetails = true}) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Updating order...'), duration: Duration(seconds: 30)),
    );

    bool success;
    try {
      final result = await onStatusUpdate(newStatus, payload);
      success = result != false;
    } catch (_) {
      success = false;
    }

    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;

    if (success) {
      final statusText = newStatus.toLowerCase() == 'declined' ? 'Order #${order.orderId} Declined' : 'Order #${order.orderId} moved to $newStatus';
      final bgColor = newStatus.toLowerCase() == 'declined' ? Colors.red : const Color(0xFF16A34A);

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(newStatus.toLowerCase() == 'declined' ? Icons.cancel : Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

      if (closeDetails) {
        Navigator.pop(context); // Close details screen
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to update the order. Please check your connection and try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
