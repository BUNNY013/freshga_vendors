import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../screens/order_details_screen.dart';
import 'dispatch_bottom_sheet.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String, Map<String, dynamic>?) onStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  Future<void> _confirmAndUpdate(BuildContext context, String newStatus, {Map<String, dynamic>? payload}) async {
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
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Order #${order.orderId} moved to $newStatus', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
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

  String _getShortAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length <= 2) return address;
    // Show first part (block/street) and last two parts (City, State Pincode) if possible
    if (parts.length >= 4) {
      return "${parts.first}, ${parts[parts.length - 2]}, ${parts.last}";
    }
    return "${parts.first}, ${parts.last}";
  }

  @override
  Widget build(BuildContext context) {
    final bool isPaid = order.paymentStatus.toLowerCase() == 'paid' || 
                        order.paymentStatus.toLowerCase() == 'completed' ||
                        order.paymentStatus.toLowerCase() == 'success';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              order: order,
              onStatusUpdate: onStatusUpdate,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order #${order.orderId}", style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSecondary, fontSize: 13, letterSpacing: -0.2)),
                    if (order.orderStatus == 'Accepted' || order.orderStatus == 'Packed') ...[
                      const SizedBox(height: 4),
                      Builder(builder: (context) {
                        final isOverdue = DateTime.now().isAfter(order.maxDispatchDate);
                        final badgeColor = isOverdue ? Colors.red : Colors.orange;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(isOverdue ? Icons.error_outline : Icons.schedule, size: 12, color: badgeColor.shade800),
                              const SizedBox(width: 4),
                              Text(
                                isOverdue ? "OVERDUE: Dispatch Immediately!" : "Dispatch By: ${DateFormat('MMM d, h:mm a').format(order.maxDispatchDate)}", 
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor.shade800),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getShortAddress(order.deliveryAddress),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${item.quantity}x", style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                            if (item.variantLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.variantLabel, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                      Text("₹${item.price * item.quantity}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Amount", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text("₹${(order.totalAmount - order.platformFee).toStringAsFixed(2)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -0.5)),
                  ],
                ),
                _buildActionButtons(context),
              ],
            ),
            
            _buildAutoCancelWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCancelWarning() {
    if (order.orderStatus != 'New') return const SizedBox.shrink();
    
    final diff = order.expiresAt.difference(DateTime.now());
    // Only show warning if there's less than 5 hours left (not from start)
    if (diff.inHours >= 5) return const SizedBox.shrink();
    
    String timeStr;
    if (diff.isNegative) {
      timeStr = "any minute now";
    } else if (diff.inHours > 0) {
      timeStr = "in ${diff.inHours} hours";
    } else {
      timeStr = "in ${diff.inMinutes} mins";
    }

    final isCritical = diff.inHours < 1;
    final color = isCritical ? Colors.red : Colors.orange.shade700;
    final bgColor = isCritical ? Colors.red.shade50 : Colors.orange.shade50.withOpacity(0.5);
    final borderColor = isCritical ? Colors.red.shade200 : Colors.orange.shade300;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Accept quickly! Order will auto-cancel $timeStr if ignored.",
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (order.orderStatus) {
      case 'New': color = const Color(0xFF4A90D9); break;
      case 'Accepted': color = const Color(0xFFE67E22); break;
      case 'Packed': color = const Color(0xFF9B59B6); break;
      case 'Shipped': color = const Color(0xFFF39C12); break;
      case 'Delivered': color = const Color(0xFF2ECC71); break;
      default: color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            order.orderStatus,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.orderStatus == 'New') {
      return _buildSingleAction(context, "Accept Order", 'Accepted', const Color(0xFF4A90D9));
    } else if (order.orderStatus == 'Accepted') {
      return _buildSingleAction(context, "Mark as Packed", 'Packed', const Color(0xFFE67E22));
    } else if (order.orderStatus == 'Packed') {
      return ElevatedButton(
        onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (sheetContext) => DispatchBottomSheet(
                  orderId: order.orderId,
                  onDispatch: (payload) async {
                    Navigator.pop(sheetContext);
                    await _confirmAndUpdate(context, 'Shipped', payload: payload);
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B59B6),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
        child: const Text("Dispatch Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else if (order.orderStatus == 'Shipped') {
      return _buildSingleAction(context, "Mark Delivered", 'Delivered', const Color(0xFFF39C12));
    }
    
    return const SizedBox.shrink(); // No actions for delivered
  }

  Widget _buildSingleAction(BuildContext context, String label, String newStatus, Color color) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Confirm Action"),
            content: Text("Are you sure you want to $label for Order #${order.orderId}?"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _confirmAndUpdate(context, newStatus);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Confirm"),
              ),
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
