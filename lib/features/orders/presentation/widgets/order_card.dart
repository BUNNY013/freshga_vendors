import 'package:flutter/material.dart';
import '../../domain/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../screens/order_details_screen.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String, Map<String, dynamic>?) onStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Order #${order.orderId.substring(0, 6)}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey500)),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(order.customerName, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(order.deliveryAddress, style: const TextStyle(color: AppColors.grey600, fontSize: 14)),
          const Divider(height: 24),
          
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item.quantity}x ${item.productName}",
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text("₹${item.price * item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: AppTextStyles.subtitle),
              Text("₹${order.totalAmount}", style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Payment Status", style: TextStyle(color: AppColors.grey600, fontSize: 12)),
              Text(
                order.paymentStatus,
                style: TextStyle(
                  color: order.paymentStatus == 'Paid' ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildActionButtons(context),
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
      return _buildSingleAction("Accept Order", 'Accepted', const Color(0xFF4A90D9));
    } else if (order.orderStatus == 'Accepted') {
      return _buildSingleAction("Prepare & Pack", 'Packed', const Color(0xFFE67E22));
    } else if (order.orderStatus == 'Packed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // For packed, navigating to details is better to dispatch,
            // or just trigger the detail screen dispatch flow directly.
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9B59B6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Dispatch Order", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    } else if (order.orderStatus == 'Shipped') {
      return _buildSingleAction("Mark Delivered", 'Delivered', const Color(0xFFF39C12));
    }
    
    return const SizedBox.shrink(); // No actions for delivered
  }

  Widget _buildSingleAction(String label, String newStatus, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => onStatusUpdate(newStatus, null),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
