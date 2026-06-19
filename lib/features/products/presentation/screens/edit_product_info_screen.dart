import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class EditProductInfoScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductInfoScreen({super.key, required this.product});

  @override
  State<EditProductInfoScreen> createState() => _EditProductInfoScreenState();
}

class _EditProductInfoScreenState extends State<EditProductInfoScreen> {
  late ProductModel _product;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _descCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    
    // Check if there is an existing pending update for these fields
    final pending = _product.pendingUpdate ?? {};
    
    _nameCtrl = TextEditingController(text: pending['name'] ?? _product.name);
    _shortDescCtrl = TextEditingController(text: pending['shortDescription'] ?? _product.shortDescription);
    _descCtrl = TextEditingController(text: pending['description'] ?? _product.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameCtrl.text.trim();
    final shortDesc = _shortDescCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product name is required.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProductProvider>();
      
      // If the fields are identical to live fields, we might not even need an update,
      // but for simplicity, we'll package them up.
      Map<String, dynamic> currentPending = _product.pendingUpdate != null ? Map.from(_product.pendingUpdate!) : {};
      
      currentPending['name'] = name;
      currentPending['shortDescription'] = shortDesc;
      currentPending['description'] = desc;

      Map<String, dynamic> updates = {
        'pendingUpdate': currentPending,
        // If the product is Live, we change it to Update Under Review
        // If it's already Draft, it stays Draft.
        'status': (_product.status == 'Live' || _product.status == 'Approved') ? 'Update Under Review' : _product.status,
      };

      await provider.updateProductPartial(_product.productId, updates);

      if (mounted) {
        setState(() => _isSaving = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product info submitted for review!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _product.pendingUpdate != null && 
        (_product.pendingUpdate!.containsKey('name') || 
         _product.pendingUpdate!.containsKey('description') || 
         _product.pendingUpdate!.containsKey('shortDescription'));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
            ),
            Text(
              'Name and descriptions',
              style: TextStyle(color: AppColors.grey500, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF673AB7), // Purple for content review actions
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notice Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFE8FF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF673AB7), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Content updates require admin review. Your current live details will remain visible to customers until approved.',
                      style: TextStyle(color: Color(0xFF673AB7), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (hasPending)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.pending_actions, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('You are editing an unapproved draft.', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField('Product Name', 'e.g., Homemade Mango Pickle', _nameCtrl, maxLines: 1),
                  const SizedBox(height: 24),
                  _buildTextField('Short Description', 'A brief 1-line summary...', _shortDescCtrl, maxLines: 2),
                  const SizedBox(height: 24),
                  _buildTextField('Full Description', 'Describe your product in detail. What makes it special?', _descCtrl, maxLines: 6),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.normal),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
