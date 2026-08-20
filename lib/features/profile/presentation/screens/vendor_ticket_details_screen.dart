import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';

class VendorTicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> initialTicketData;

  const VendorTicketDetailsScreen({
    super.key,
    required this.ticketId,
    required this.initialTicketData,
  });

  @override
  State<VendorTicketDetailsScreen> createState() => _VendorTicketDetailsScreenState();
}

class _VendorTicketDetailsScreenState extends State<VendorTicketDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final vendorId = context.read<AuthProvider>().userModel?.userId;
    if (vendorId == null) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // 1. Add reply to subcollection
      final replyRef = FirebaseFirestore.instance
          .collection('vendor_support_tickets')
          .doc(widget.ticketId)
          .collection('replies')
          .doc();
          
      batch.set(replyRef, {
        'senderId': vendorId,
        'senderType': 'vendor',
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update parent ticket timestamp and potentially status if it was waiting
      final ticketRef = FirebaseFirestore.instance.collection('vendor_support_tickets').doc(widget.ticketId);
      batch.update(ticketRef, {
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        // Optional: change status to Open if it was waiting for vendor
      });

      await batch.commit();

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ticket Details",
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              "ID: ${widget.ticketId.substring(0, 8).toUpperCase()}",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header info
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('vendor_support_tickets').doc(widget.ticketId).snapshots(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data() as Map<String, dynamic>? ?? widget.initialTicketData;
              final status = data['status'] ?? 'Open';
              final isResolved = status == 'Resolved';
              final statusColor = isResolved ? Colors.green : Colors.orange;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['topic'] ?? 'General Query',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Original Message
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Original Request", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  widget.initialTicketData['message'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Chat Thread
          Expanded(
            child: _buildChatThread(),
          ),

          // Message Input Area (if not resolved)
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatThread() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendor_support_tickets')
          .doc(widget.ticketId)
          .collection('replies')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No replies yet.\nWe'll notify you when an admin responds.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        final replies = snapshot.data!.docs;

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final replyData = replies[index].data() as Map<String, dynamic>;
            final isVendor = replyData['senderType'] == 'vendor';
            final message = replyData['message'] ?? '';
            final timestamp = replyData['timestamp'] as Timestamp?;

            return _buildMessageBubble(
              message: message,
              isMe: isVendor,
              time: timestamp != null ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate()) : 'Sending...',
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble({required String message, required bool isMe, required String time}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : 'Admin Support',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendor_support_tickets').doc(widget.ticketId).snapshots(),
      builder: (context, snapshot) {
        final status = (snapshot.data?.data() as Map<String, dynamic>?)?['status'] ?? 'Open';
        
        if (status == 'Resolved') {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text("This ticket is resolved.", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a reply...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: _isSending 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _sendMessage,
                        ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
