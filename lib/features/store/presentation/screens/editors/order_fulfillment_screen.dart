import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

class OrderFulfillmentScreen extends StatefulWidget {
  const OrderFulfillmentScreen({super.key});

  @override
  State<OrderFulfillmentScreen> createState() => _OrderFulfillmentScreenState();
}

class _OrderFulfillmentScreenState extends State<OrderFulfillmentScreen> {
  final List<String> _packagingTags = [
    'Fragile', 'Glass Bottles', 'Leak Proof',
    'Food Grade', 'Vacuum Packed', 'Perishable'
  ];

  final Set<String> _selectedTags = {'Fragile', 'Glass Bottles', 'Leak Proof', 'Food Grade'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Order Fulfillment',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Pickup Address', required: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Same as Business Address', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('Contact Person', required: true),
            const SizedBox(height: 8),
            _buildTextField(initialValue: 'Lakshmi Devi', hintText: 'Name'),
            const SizedBox(height: 24),
            _buildLabel('Phone Number', required: true),
            const SizedBox(height: 8),
            _buildTextField(initialValue: '+91 98765 43210', hintText: 'Phone'),
            const SizedBox(height: 24),
            _buildLabel('Dispatch Time', required: true),
            const SizedBox(height: 8),
            _buildDropdown(
              value: '1 Business Day',
              items: ['1 Business Day', '2 Business Days', '3 Business Days'],
            ),
            const SizedBox(height: 24),
            _buildLabel('Pickup Availability', required: true),
            const SizedBox(height: 12),
            _buildAvailabilityRow('Monday', '9:00 AM - 6:00 PM'),
            _buildAvailabilityRow('Tuesday', '9:00 AM - 6:00 PM'),
            _buildAvailabilityRow('Wednesday', '9:00 AM - 6:00 PM'),
            _buildAvailabilityRow('Thursday', '9:00 AM - 6:00 PM'),
            _buildAvailabilityRow('Friday', '9:00 AM - 6:00 PM'),
            _buildAvailabilityRow('Saturday', '9:00 AM - 1:00 PM', true),
            _buildAvailabilityRow('Sunday', 'Not Available', false, true),
            
            const SizedBox(height: 32),
            _buildLabel('Packaging & Shipping', required: false),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _packagingTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            _buildLabel('Default Package Weight', required: false),
            const SizedBox(height: 8),
            _buildTextField(
              initialValue: '500',
              hintText: 'Weight',
              suffixWidget: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text('grams', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLabel('Default Package Dimensions', required: false),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildDimField('Length', '20')),
                const SizedBox(width: 12),
                Expanded(child: _buildDimField('Width', '15')),
                const SizedBox(width: 12),
                Expanded(child: _buildDimField('Height', '10')),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        if (required)
          const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
        if (!required)
          const Text(' (Optional)', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  Widget _buildAvailabilityRow(String day, String time, [bool isHalfDay = false, bool isOff = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
          Row(
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  color: isOff ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                isOff ? Icons.close : Icons.check,
                color: isOff ? const Color(0xFF94A3B8) : AppColors.primary,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hintText,
    Widget? suffixWidget,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: suffixWidget,
      ),
    );
  }

  Widget _buildDimField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        _buildTextField(
          initialValue: value,
          hintText: '',
          suffixWidget: const Padding(
            padding: EdgeInsets.all(14.0),
            child: Text('cm', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String value, required List<String> items}) {
    return DropdownButtonFormField<String>(
      value: value,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (val) {},
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: ElevatedButton(
        onPressed: () => context.pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
