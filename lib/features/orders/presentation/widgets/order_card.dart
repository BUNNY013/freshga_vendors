import 'package:flutter/material.dart';
import '../../domain/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(String) onStatusUpdate;

  const OrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text("${item.quantity}x ${item.productName}", style: const TextStyle(fontSize: 14)),
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
          const SizedBox(height: 16),
          
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (order.orderStatus) {
      case 'New': color = Colors.orange; break;
      case 'Accepted': color = Colors.blue; break;
      case 'Packed': color = Colors.purple; break;
      case 'Shipped': color = Colors.amber; break;
      case 'Delivered': color = Colors.green; break;
      default: color = AppColors.grey500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        order.orderStatus,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (order.orderStatus == 'New') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => onStatusUpdate('Accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Accept Order", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    } else if (order.orderStatus == 'Accepted') {
      return _buildSingleAction("Mark as Packed", 'Packed', Colors.purple);
    } else if (order.orderStatus == 'Packed') {
      return _buildSingleAction("Mark as Shipped", 'Shipped', Colors.amber);
    } else if (order.orderStatus == 'Shipped') {
      return _buildSingleAction("Mark as Delivered", 'Delivered', Colors.green);
    }
    
    return const SizedBox.shrink(); // No actions for delivered
  }

  Widget _buildSingleAction(String label, String newStatus, Color color) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => onStatusUpdate(newStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
