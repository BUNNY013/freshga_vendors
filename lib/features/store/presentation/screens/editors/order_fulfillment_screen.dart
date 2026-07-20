import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../providers/store_provider.dart';
import '../../../../../data/models/delivery_area_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'state_selection_screen.dart';

class OrderFulfillmentScreen extends StatefulWidget {
  const OrderFulfillmentScreen({super.key});

  @override
  State<OrderFulfillmentScreen> createState() => _OrderFulfillmentScreenState();
}

class _OrderFulfillmentScreenState extends State<OrderFulfillmentScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchStore();
    });
  }

  void _showEditAreaBottomSheet(DeliveryAreaModel area, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditDeliveryAreaSheet(
        area: area,
        onSave: (updatedArea) async {
          setState(() { _isLoading = true; });
          
          try {
            final storeProvider = context.read<StoreProvider>();
            await storeProvider.updateDeliveryArea(index, updatedArea);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            setState(() { _isLoading = false; });
          }
        },
      ),
    );
  }

  void _showAddAreaBottomSheet() {
    final store = context.read<StoreProvider>().store;
    if (store == null) return;
    
    // Calculate available states
    final allStates = [
      'Andaman and Nicobar Islands', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 
      'Bihar', 'Chandigarh', 'Chhattisgarh', 'Dadra and Nagar Haveli and Daman and Diu', 
      'Delhi', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jammu and Kashmir', 
      'Jharkhand', 'Karnataka', 'Kerala', 'Ladakh', 'Lakshadweep', 'Madhya Pradesh', 
      'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 
      'Puducherry', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 
      'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
    ];
    
    final usedStates = <String>{};
    for (var area in store.deliveryAreas) {
      usedStates.addAll(area.states);
    }
    
    final availableStates = allStates.where((s) => !usedStates.contains(s) && s != store.state).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddDeliveryAreaSheet(
        availableStates: availableStates,
        onSave: (newArea) async {
          setState(() { _isLoading = true; });
          try {
            final storeProvider = context.read<StoreProvider>();
            
            // To maintain "Remaining India" at the end, insert before the last element
            // Wait, we can just use `addDeliveryArea` and sort or handle it later.
            // Actually, we should ideally insert it before "Remaining India" if it exists.
            
            final newAreas = List<DeliveryAreaModel>.from(store.deliveryAreas);
            
            // Remove "Remaining India" temporarily if it exists
            final remainingAreaIndex = newAreas.indexWhere((a) => a.areaId == 'area_remaining');
            DeliveryAreaModel? remainingArea;
            if (remainingAreaIndex != -1) {
              remainingArea = newAreas.removeAt(remainingAreaIndex);
            }
            
            newAreas.add(newArea);
            
            if (remainingArea != null) {
              newAreas.add(remainingArea);
            }
            
            // Overwrite all areas via a single update for simplicity
            await FirebaseFirestore.instance.collection('stores').doc(store.storeId).update({
              'deliveryAreas': newAreas.map((e) => e.toJson()).toList(),
            });
            await storeProvider.fetchStore();
            
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          } finally {
            setState(() { _isLoading = false; });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();
    final store = storeProvider.store;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Shipping Settings',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
      ),
      body: storeProvider.isLoading || _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : store == null
              ? const Center(child: Text("Could not load store data"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fulfillment Method',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How will you dispatch your orders?',
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildFulfillmentCard(
                        title: 'FreshGa Delivery (Shiprocket)',
                        description: 'We calculate shipping rates automatically and schedule pickups for you.',
                        icon: Icons.local_shipping_outlined,
                        isSelected: store.shippingConfig['shippingMode'] != 'self',
                        onTap: () {
                           storeProvider.updateShippingMode('freshga');
                        }
                      ),
                      const SizedBox(height: 12),
                      _buildFulfillmentCard(
                        title: 'Self Shipping',
                        description: 'You handle the delivery and set your own manual shipping rates.',
                        icon: Icons.inventory_2_outlined,
                        isSelected: store.shippingConfig['shippingMode'] == 'self',
                        onTap: () {
                           storeProvider.updateShippingMode('self');
                        }
                      ),
                      
                      if (store.shippingConfig['shippingMode'] == 'self') ...[
                        const SizedBox(height: 40),
                        const Text(
                          'Manual Delivery Areas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.canSellPanIndia
                              ? 'Configure your manual shipping rules for local and national deliveries.'
                              : 'Configure your manual local shipping rules. As an enrolled vendor, you can only sell within your state.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            children: store.deliveryAreas.asMap().entries.map((entry) {
                              final index = entry.key;
                              final area = entry.value;
                              final isLast = index == store.deliveryAreas.length - 1;
                              return Column(
                                children: [
                                  _buildDeliveryAreaCard(area, store.state, index, () => _showEditAreaBottomSheet(area, index)),
                                  if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        
                        if (store.canSellPanIndia)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                            child: OutlinedButton.icon(
                              onPressed: _showAddAreaBottomSheet,
                              icon: const Icon(Icons.add_location_alt_outlined, color: AppColors.primary),
                              label: const Text('Add Delivery Area', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildDeliveryAreaCard(DeliveryAreaModel area, String storeState, int index, VoidCallback onTap) {
    final isMyState = area.areaType == 'My State';
    final isRest = area.areaType == 'Remaining India';
    
    // Formatting title
    String title = '';
    if (isMyState) {
      title = '$storeState (My State)';
    } else if (isRest) {
      title = 'Rest of India';
    } else {
      title = area.states.join(', ');
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F4E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534), fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isMyState ? storeState : title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A), fontFamily: 'sans-serif'),
                        ),
                        if (isMyState)
                          const TextSpan(
                            text: ' (My State)',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (area.ruleType == 'free')
                    const Text('Free Shipping', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13))
                  else if (area.ruleType == 'flat')
                    Text('₹${area.deliveryCharge.toInt()} Shipping', style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 13))
                  else if (area.ruleType == 'flat_plus_free_above')
                    Row(
                      children: [
                        Text('₹${area.deliveryCharge.toInt()} Shipping', style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold, fontSize: 13)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('•', style: TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        Text('Free above ₹${area.freeShippingThreshold?.toInt()}', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.more_vert, color: Color(0xFF475569), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFulfillmentCard({required String title, required String description, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : const Color(0xFF64748B)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569))),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _EditDeliveryAreaSheet extends StatefulWidget {
  final DeliveryAreaModel area;
  final Function(DeliveryAreaModel) onSave;

  const _EditDeliveryAreaSheet({required this.area, required this.onSave});

  @override
  State<_EditDeliveryAreaSheet> createState() => _EditDeliveryAreaSheetState();
}

class _EditDeliveryAreaSheetState extends State<_EditDeliveryAreaSheet> {
  late String _ruleType;
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ruleType = widget.area.ruleType;
    if (_ruleType != 'free') {
      _rateController.text = widget.area.deliveryCharge.toInt().toString();
    }
    if (_ruleType == 'flat_plus_free_above' && widget.area.freeShippingThreshold != null) {
      _thresholdController.text = widget.area.freeShippingThreshold!.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${widget.area.areaType}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildRadioOption('free', 'Free Shipping', 'Customer pays ₹0 for delivery'),
              const SizedBox(height: 12),
              _buildRadioOption('flat', 'Flat Rate', 'Customer pays a fixed amount'),
              const SizedBox(height: 12),
              _buildRadioOption('flat_plus_free_above', 'Flat Rate + Free Above', 'Offer free shipping over a certain order value'),
              
              if (_ruleType == 'flat' || _ruleType == 'flat_plus_free_above') ...[
                const SizedBox(height: 24),
                const Text('Delivery Charge (₹)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 50',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ],
              
              if (_ruleType == 'flat_plus_free_above') ...[
                const SizedBox(height: 16),
                const Text('Free Shipping Threshold (₹)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 999',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final double charge = _ruleType == 'free' ? 0.0 : (double.tryParse(_rateController.text) ?? 0.0);
                    final double? threshold = _ruleType == 'flat_plus_free_above' ? double.tryParse(_thresholdController.text) : null;
                    
                    final updatedArea = DeliveryAreaModel(
                      areaId: widget.area.areaId,
                      areaType: widget.area.areaType,
                      states: widget.area.states,
                      ruleType: _ruleType,
                      deliveryCharge: charge,
                      freeShippingThreshold: threshold,
                    );
                    
                    Navigator.pop(context);
                    widget.onSave(updatedArea);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, String title, String subtitle) {
    final isSelected = _ruleType == value;
    return GestureDetector(
      onTap: () => setState(() => _ruleType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDeliveryAreaSheet extends StatefulWidget {
  final List<String> availableStates;
  final Function(DeliveryAreaModel) onSave;

  const _AddDeliveryAreaSheet({required this.availableStates, required this.onSave});

  @override
  State<_AddDeliveryAreaSheet> createState() => _AddDeliveryAreaSheetState();
}

class _AddDeliveryAreaSheetState extends State<_AddDeliveryAreaSheet> {
  String _ruleType = 'flat';
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final List<String> _selectedStates = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Custom Delivery Area',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select States', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  if (_selectedStates.isNotEmpty)
                    Text(
                      '${_selectedStates.length} Selected',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              OutlinedButton.icon(
                onPressed: () => _showStateSelectionDialog(context),
                icon: const Icon(Icons.public, color: AppColors.primary),
                label: Text(_selectedStates.isEmpty ? 'Choose States' : 'Edit States', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              
              if (_selectedStates.isNotEmpty) ...[
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _selectedStates.map((state) {
                      return Chip(
                        label: Text(state, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                        onDeleted: () {
                          setState(() {
                            _selectedStates.remove(state);
                          });
                        },
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.transparent)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              const Text('Shipping Rule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              
              _buildRadioOption('free', 'Free Shipping', 'Customer pays ₹0 for delivery'),
              const SizedBox(height: 12),
              _buildRadioOption('flat', 'Flat Rate', 'Customer pays a fixed amount'),
              const SizedBox(height: 12),
              _buildRadioOption('flat_plus_free_above', 'Flat Rate + Free Above', 'Offer free shipping over a certain order value'),
              
              if (_ruleType == 'flat' || _ruleType == 'flat_plus_free_above') ...[
                const SizedBox(height: 24),
                const Text('Delivery Charge (₹)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 50',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ],
              
              if (_ruleType == 'flat_plus_free_above') ...[
                const SizedBox(height: 16),
                const Text('Free Shipping Threshold (₹)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 999',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedStates.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one state')));
                      return;
                    }
                    
                    final double charge = _ruleType == 'free' ? 0.0 : (double.tryParse(_rateController.text) ?? 0.0);
                    final double? threshold = _ruleType == 'flat_plus_free_above' ? double.tryParse(_thresholdController.text) : null;
                    
                    final newArea = DeliveryAreaModel(
                      areaId: 'area_${DateTime.now().millisecondsSinceEpoch}',
                      areaType: 'Selected States',
                      states: _selectedStates,
                      ruleType: _ruleType,
                      deliveryCharge: charge,
                      freeShippingThreshold: threshold,
                    );
                    
                    Navigator.pop(context);
                    widget.onSave(newArea);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Area', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String value, String title, String subtitle) {
    final isSelected = _ruleType == value;
    return GestureDetector(
      onTap: () => setState(() => _ruleType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStateSelectionDialog(BuildContext context) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => StateSelectionScreen(
          availableStates: widget.availableStates,
          initialSelectedStates: _selectedStates,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedStates.clear();
        _selectedStates.addAll(result);
      });
    }
  }
}
