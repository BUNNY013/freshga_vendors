import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/states/app_state_widgets.dart';
import '../../domain/models/order_model.dart';
import '../widgets/order_card.dart';
import '../../../../data/models/user_model.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vendor_issues_screen.dart';

class OrdersListScreen extends StatelessWidget {
  final int initialIndex;
  const OrdersListScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      blurValue: 1,
      enableAutoScroll: true,
      builder: (context) => _OrdersListContent(initialIndex: initialIndex),
    );
  }
}

class _OrdersListContent extends StatefulWidget {
  final int initialIndex;
  const _OrdersListContent({this.initialIndex = 0});

  @override
  State<_OrdersListContent> createState() => _OrdersListContentState();
}

class _OrdersListContentState extends State<_OrdersListContent> {
  final GlobalKey _newKey = GlobalKey();
  final GlobalKey _prepKey = GlobalKey();
  final GlobalKey _readyKey = GlobalKey();
  final GlobalKey _shippedKey = GlobalKey();
  final GlobalKey _deliveredKey = GlobalKey();
  final GlobalKey _cancelledKey = GlobalKey();
  final GlobalKey _issuesKey = GlobalKey();
  bool _hasCheckedTutorial = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkOrdersTutorial() async {
    if (_hasCheckedTutorial) return;
    _hasCheckedTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_orders_tutorial') ?? false;
    
    if (!hasSeenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([_newKey, _prepKey, _readyKey, _shippedKey, _deliveredKey, _cancelledKey, _issuesKey]);
        }
      });
      await prefs.setBool('has_seen_orders_tutorial', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: ErrorStateWidget(message: 'Not authenticated', onRetry: () {}));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(body: ErrorStateWidget(message: 'Failed to load user data', onRetry: () {}));
        }
        if (!userSnap.hasData) {
          return const Scaffold(body: LoadingStateWidget(message: 'Loading store data...'));
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) {
          return Scaffold(body: ErrorStateWidget(message: 'User data not found', onRetry: () {}));
        }

        final storeId = UserModel.fromJson(userData).storeId;

        if (storeId.isEmpty) {
          return Scaffold(
            body: Center(
              child: EmptyStateWidget(
                icon: Icons.store_mall_directory_outlined,
                title: 'Store not set up',
                message: 'Please complete your store profile to start receiving orders.',
              ),
            ),
          );
        }


        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('orders').where('storeId', isEqualTo: storeId).snapshots(),
          builder: (context, ordersSnap) {
            if (ordersSnap.hasError) {
              return Scaffold(body: ErrorStateWidget(message: 'Failed to load orders', onRetry: () {}));
            }
            final ordersList = ordersSnap.data?.docs.map((d) => OrderModel.fromJson(d.data() as Map<String, dynamic>)).toList() ?? [];
            final newCount = ordersList.where((o) => o.orderStatus.toLowerCase() == 'new').length;
            final prepCount = ordersList.where((o) => o.orderStatus.toLowerCase() == 'accepted').length;
            final readyCount = ordersList.where((o) => o.orderStatus.toLowerCase() == 'packed').length;
            final shippedCount = ordersList.where((o) => o.orderStatus.toLowerCase() == 'shipped').length;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('refund_requests').where('storeId', isEqualTo: storeId).snapshots(),
              builder: (context, issuesSnap) {
                if (issuesSnap.hasError) {
                  return Scaffold(body: ErrorStateWidget(message: 'Failed to load orders', onRetry: () {}));
                }
                final issuesList = issuesSnap.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];
                final issuesCount = issuesList.where((i) => i['status'] != 'Refund Processed' && i['status'] != 'Rejected').length;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkOrdersTutorial();
                });

                return DefaultTabController(
                  length: 6,
                  initialIndex: widget.initialIndex,
                  child: Scaffold(
                    backgroundColor: AppColors.background,
                    appBar: AppBar(
                      centerTitle: false,
                      title: const Text(
                        'Orders',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1.0),
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      actions: [
                        Showcase(
                          key: _issuesKey,
                          title: '7 of 7: Customer Issues',
                          description: 'Manage and resolve customer complaints or refund requests.',
                          tooltipBackgroundColor: AppColors.primary,
                          textColor: Colors.white,
                          targetPadding: const EdgeInsets.all(4),
                          overlayOpacity: 0.5,
                          tooltipActions: [
                            TooltipActionButton(
                              type: TooltipDefaultActionType.next,
                              name: 'Finish',
                              backgroundColor: Colors.white,
                              textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorIssuesScreen()));
                                },
                              ),
                              if (issuesCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: Text(
                                      '$issuesCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      bottom: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.3),
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            child: Showcase(
                              key: _newKey,
                              title: '1 of 7: New Orders',
                              description: 'Incoming orders appear here. Accept them to start preparing.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: Text(newCount > 0 ? 'New ($newCount)' : 'New'),
                            ),
                          ),
                          Tab(
                            child: Showcase(
                              key: _prepKey,
                              title: '2 of 7: Preparing',
                              description: 'Orders you are currently cooking or preparing.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: Text(prepCount > 0 ? 'Preparing ($prepCount)' : 'Preparing'),
                            ),
                          ),
                          Tab(
                            child: Showcase(
                              key: _readyKey,
                              title: '3 of 7: Ready',
                              description: 'Orders packed and ready for delivery/pickup.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: Text(readyCount > 0 ? 'Ready ($readyCount)' : 'Ready'),
                            ),
                          ),
                          Tab(
                            child: Showcase(
                              key: _shippedKey,
                              title: '4 of 7: Shipped',
                              description: 'Orders that are out for delivery.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: Text(shippedCount > 0 ? 'Shipped ($shippedCount)' : 'Shipped'),
                            ),
                          ),
                          Tab(
                            child: Showcase(
                              key: _deliveredKey,
                              title: '5 of 7: Delivered',
                              description: 'Successfully completed orders.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: const Text('Delivered'),
                            ),
                          ),
                          Tab(
                            child: Showcase(
                              key: _cancelledKey,
                              title: '6 of 7: Cancelled',
                              description: 'Orders that were rejected or cancelled.',
                              tooltipBackgroundColor: AppColors.primary,
                              textColor: Colors.white,
                              targetPadding: const EdgeInsets.all(4),
                              overlayOpacity: 0.5,
                              tooltipActions: [
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.skip,
                                  name: 'Skip Tutorial',
                                  textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                TooltipActionButton(
                                  type: TooltipDefaultActionType.next,
                                  name: 'Next',
                                  backgroundColor: Colors.white,
                                  textStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                              child: const Text('Cancelled'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      children: [
                        _OrderListTab(orders: ordersList, statusFilter: const ['New']),
                        _OrderListTab(orders: ordersList, statusFilter: const ['Accepted']),
                        _OrderListTab(orders: ordersList, statusFilter: const ['Packed']),
                        _OrderListTab(orders: ordersList, statusFilter: const ['Shipped']),
                        _OrderListTab(orders: ordersList, statusFilter: const ['Delivered']),
                        _OrderListTab(orders: ordersList, statusFilter: const ['Cancelled', 'Rejected', 'Declined']),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OrderListTab extends StatelessWidget {
  final List<OrderModel> orders;
  final List<String> statusFilter;

  const _OrderListTab({required this.orders, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    // Client-side filter by status (case-insensitive)
    final filteredOrders = orders
        .where((order) => statusFilter.any((s) => s.toLowerCase() == order.orderStatus.toLowerCase()))
        .toList();

    // Sort by createdAt descending
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filteredOrders.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)), // staggered effect
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: OrderCard(
            order: filteredOrders[index],
            onStatusUpdate: (newStatus, payload) async {
            final order = filteredOrders[index];
            final timeline = List<Map<String, dynamic>>.from(order.timeline);

            String? note;
            if (payload != null && payload.containsKey('shippingMethod')) {
              final method = payload['shippingMethod'];
              if (method == 'Courier') note = 'Shipped via ${payload['shippingProvider']} (Tracking: ${payload['trackingId']})';
              if (method == 'Hyperlocal') note = 'Dispatched via ${payload['shippingProvider']}';
              if (method == 'Local Transport') note = 'Sent via ${payload['shippingProvider']} (LR: ${payload['receiptNumber']})';
              if (method == 'Self Delivery') note = 'Vendor delivering directly by ${payload['deliveryTime']}';
            } else if (payload != null && payload.containsKey('rejectionReason')) {
              note = 'Reason: ${payload['rejectionReason']}';
            }

            timeline.add({
              'status': newStatus,
              'time': DateTime.now().toIso8601String(),
              if (note != null) 'note': note,
            });

            final updates = <String, dynamic>{
              'orderStatus': newStatus,
              'timeline': timeline,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            if (payload != null) {
              if (payload.containsKey('shippingMethod')) updates.addAll(payload);
              if (payload.containsKey('rejectionReason')) updates['rejectionReason'] = payload['rejectionReason'];
            }

            try {
              final db = FirebaseFirestore.instance;
              
              if (newStatus == 'Cancelled' || newStatus == 'Rejected' || newStatus == 'Declined') {
                await db.runTransaction((transaction) async {
                  final orderRef = db.collection('orders').doc(order.orderId);
                  
                  Map<String, DocumentReference> productRefs = {};
                  Map<String, DocumentSnapshot> productDocs = {};
                  
                  for (var item in order.items) {
                    productRefs[item.productId] = db.collection('products').doc(item.productId);
                  }
                  
                  for (var productId in productRefs.keys) {
                    productDocs[productId] = await transaction.get(productRefs[productId]!);
                  }
                  
                  for (var productId in productDocs.keys) {
                    final doc = productDocs[productId]!;
                    if (doc.exists) {
                      final data = doc.data() as Map<String, dynamic>;
                      List<dynamic> variants = data['variants'] ?? [];
                      bool updated = false;
                      
                      final productItems = order.items.where((i) => i.productId == productId);
                      for (var item in productItems) {
                        for (int i = 0; i < variants.length; i++) {
                          if (variants[i]['label'] == item.variantLabel) {
                            if (variants[i]['manageStock'] == true) {
                              variants[i]['stock'] = (variants[i]['stock'] ?? 0) + item.quantity;
                              if (variants[i]['stock'] > 0) {
                                variants[i]['inStock'] = true;
                              }
                              updated = true;
                            }
                            break;
                          }
                        }
                      }
                      if (updated) {
                        transaction.update(productRefs[productId]!, {'variants': variants});
                      }
                    }
                  }
                  transaction.update(orderRef, updates);
                });
              } else {
                await db.collection('orders').doc(order.orderId).update(updates);
                
                if (newStatus == 'Delivered') {
                  await db.collection('stores').doc(order.storeId).update({
                    'totalOrders': FieldValue.increment(1),
                  });
                }
              }

              return true;
            } catch (e) {
              debugPrint('Failed to update order ${order.orderId}: $e');
              return false;
            }
          },
        ),
      );
    },
  );
  }

  Widget _buildEmptyState() {
    IconData iconData;
    String title;
    String subtitle;
    
    switch (statusFilter.first.toLowerCase()) {
      case 'new':
        iconData = Icons.receipt_long_rounded;
        title = 'No new orders yet';
        subtitle = 'Share your store to get your first order!';
        break;
      case 'accepted':
        iconData = Icons.soup_kitchen_rounded;
        title = 'No orders preparing';
        subtitle = 'Orders you have accepted will appear here while you prepare them.';
        break;
      case 'packed':
        iconData = Icons.inventory_2_rounded;
        title = 'No orders ready';
        subtitle = 'Packed orders ready for dispatch will appear here.';
        break;
      case 'shipped':
        iconData = Icons.local_shipping_rounded;
        title = 'No orders in transit';
        subtitle = 'Orders out for delivery will be shown here.';
        break;
      case 'delivered':
        iconData = Icons.check_circle_outline_rounded;
        title = 'No delivered orders';
        subtitle = 'Successfully completed orders will appear here.';
        break;
      case 'cancelled':
        iconData = Icons.cancel_outlined;
        title = 'No cancelled orders';
        subtitle = 'Orders that were declined or cancelled will appear here.';
        break;
      default:
        iconData = Icons.receipt_long;
        title = 'No orders found';
        subtitle = 'There are no orders matching this status.';
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: EmptyStateWidget(
          icon: iconData,
          title: title,
          message: subtitle,
        ),
      ),
    );
  }
}
