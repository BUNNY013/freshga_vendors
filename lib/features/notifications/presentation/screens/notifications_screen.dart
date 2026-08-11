import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _markAllAsRead() {
    context.read<NotificationProvider>().markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _markAsRead(String id) {
    context.read<NotificationProvider>().markAsRead(id);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }

  Widget _getIconForType(String type) {
    switch (type) {
      case 'order':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
          child: Icon(Icons.shopping_bag_outlined, color: Colors.green.shade600, size: 24),
        );
      case 'payout':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
          child: Icon(Icons.account_balance_wallet_outlined, color: Colors.orange.shade600, size: 24),
        );
      case 'alert':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
          child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 24),
        );
      case 'system':
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
          child: Icon(Icons.info_outline_rounded, color: Colors.blue.shade600, size: 24),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final isLoading = notificationProvider.isLoading;

    final today = notifications.where((n) => n.createdAt.day == DateTime.now().day).toList();
    final yesterday = notifications.where((n) => n.createdAt.day == DateTime.now().subtract(const Duration(days: 1)).day).toList();
    final earlier = notifications.where((n) => n.createdAt.isBefore(DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0))).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          if (notifications.any((n) => !n.isRead))
            IconButton(
              tooltip: "Mark all as read",
              icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No notifications yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text("We'll let you know when something arrives.", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    if (today.isNotEmpty) _buildSectionHeader("Today"),
                    ...today.map((n) => _buildNotificationTile(n)),
                    if (yesterday.isNotEmpty) _buildSectionHeader("Yesterday"),
                    ...yesterday.map((n) => _buildNotificationTile(n)),
                    if (earlier.isNotEmpty) _buildSectionHeader("Earlier"),
                    ...earlier.map((n) => _buildNotificationTile(n)),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    return InkWell(
      onTap: () => _markAsRead(notification.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.transparent : Colors.green.shade50.withOpacity(0.3),
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _getIconForType(notification.type),
                if (!notification.isRead)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                          color: notification.isRead ? Colors.grey.shade500 : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: notification.isRead ? AppColors.textSecondary : Colors.black87,
                      fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
