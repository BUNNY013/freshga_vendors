import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../orders/domain/models/order_model.dart';

class VendorPayoutDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> payoutData;

  const VendorPayoutDetailsScreen({super.key, required this.payoutData});

  @override
  Widget build(BuildContext context) {
    final amount = payoutData['amount'] ?? 0;
    final date = (payoutData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final adminRef = payoutData['adminReference'] ?? 'N/A';
    final List<dynamic> orderIds = payoutData['orderIds'] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payout Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
                  const SizedBox(height: 12),
                  const Text('Settled Amount', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  if (payoutData['orderAmount'] != null && payoutData['shippingAmount'] != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Order Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹${(payoutData['orderAmount'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Shipping Cost', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹${(payoutData['shippingAmount'] as num).toDouble().toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  _buildDetailRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(date)),
                  const SizedBox(height: 8),
                  _buildDetailRow('Reference ID', adminRef),
                  const SizedBox(height: 8),
                  _buildDetailRow('Orders Included', '${orderIds.length} Orders'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (payoutData['receiptUrl'] != null) ...[
              const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  payoutData['receiptUrl'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 32),
            ],
            const Text('Orders Settled in this Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (orderIds.isEmpty)
              const Center(child: Text('No orders found for this payout.', style: TextStyle(color: Colors.grey)))
            else
              _buildOrdersList(orderIds.cast<String>()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildOrdersList(List<String> orderIds) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('orders').where(FieldPath.documentId, whereIn: orderIds.take(10).toList()).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Could not fetch order details.', style: TextStyle(color: Colors.grey));
        }

        final orders = snapshot.data!.docs.map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>)).toList();
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    Text('₹${(order.subTotal + order.deliveryFee).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Delivered on: ${DateFormat('dd MMM yyyy').format(order.updatedAt)}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 13))),
                              Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )).toList(),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order Subtotal:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('₹${order.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (order.deliveryFee > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Shipping Fee:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                Text('+ ₹${order.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
