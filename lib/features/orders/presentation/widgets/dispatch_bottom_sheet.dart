import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class DispatchBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onDispatch;
  final String orderId;

  const DispatchBottomSheet({super.key, required this.onDispatch, required this.orderId});

  @override
  State<DispatchBottomSheet> createState() => _DispatchBottomSheetState();
}

class _DispatchBottomSheetState extends State<DispatchBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMethod = 'Courier';
  String _selectedProvider = 'Delhivery';
  
  final _trackingIdController = TextEditingController();
  final _trackingLinkController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _receiptController = TextEditingController();
  final _customProviderController = TextEditingController();
  
  DateTime? _selectedDeliveryTime;
  File? _receiptImage;
  bool _isUploading = false;

  final List<String> _courierProviders = ['Delhivery', 'DTDC', 'BlueDart', 'Ecom Express', 'Shadowfax', 'XpressBees', 'India Post', 'Other'];
  final List<String> _hyperlocalProviders = ['Rapido', 'Uber Connect', 'Dunzo', 'Porter', 'Swiggy Genie', 'Borzo', 'Other'];
  final List<String> _transportProviders = ['State Transport Bus (RTC)', 'Private Bus', 'Train / Railway', 'Auto / Cab', 'Other'];

  @override
  void initState() {
    super.initState();
    _selectedProvider = _courierProviders.first;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDeliveryTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<String?> _uploadReceiptImage() async {
    if (_receiptImage == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('dispatch_receipts/${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_receiptImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Image Upload Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMethod == 'Self Delivery' && _selectedDeliveryTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an expected delivery time.')));
        return;
      }
      
      setState(() => _isUploading = true);
      final imageUrl = await _uploadReceiptImage();
      
      String finalProvider = _selectedProvider;
      if (_selectedProvider == 'Other' && _customProviderController.text.isNotEmpty) {
        finalProvider = _customProviderController.text;
      } else if (_selectedMethod == 'Local Transport' && _customProviderController.text.isNotEmpty) {
        finalProvider = '$_selectedProvider (${_customProviderController.text})';
      }
      
      final payload = {
        'shippingMethod': _selectedMethod,
        'shippingProvider': finalProvider,
        'trackingId': _trackingIdController.text,
        'trackingLink': _trackingLinkController.text,
        'contactNumber': _contactNumberController.text,
        'receiptNumber': _receiptController.text,
        'deliveryTime': _selectedDeliveryTime != null ? DateFormat('dd MMM, hh:mm a').format(_selectedDeliveryTime!) : '',
        if (imageUrl != null) 'receiptImageUrl': imageUrl,
      };
      
      setState(() => _isUploading = false);
      widget.onDispatch(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Dispatch Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Select how you are shipping this order to the customer.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: InputDecoration(
                  labelText: 'Shipping Method',
                  prefixIcon: const Icon(Icons.local_shipping, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Courier', child: Text('Courier / Parcel Service')),
                  DropdownMenuItem(value: 'Hyperlocal', child: Text('Hyperlocal (Rapido, Uber)')),
                  DropdownMenuItem(value: 'Local Transport', child: Text('Local Transport (Bus, Auto)')),
                  DropdownMenuItem(value: 'Self Delivery', child: Text('Self Delivery / Pickup')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMethod = val;
                      _trackingIdController.clear();
                      _trackingLinkController.clear();
                      _contactNumberController.clear();
                      _receiptController.clear();
                      _customProviderController.clear();
                      _selectedDeliveryTime = null;
                      
                      if (val == 'Courier') _selectedProvider = _courierProviders.first;
                      else if (val == 'Hyperlocal') _selectedProvider = _hyperlocalProviders.first;
                      else if (val == 'Local Transport') _selectedProvider = _transportProviders.first;
                      else _selectedProvider = 'Vendor';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              if (_selectedMethod == 'Courier') ...[
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: 'Courier Name',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _courierProviders.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedProvider = val!;
                    if (val != 'Other') _customProviderController.clear();
                  }),
                ),
                const SizedBox(height: 16),
                if (_selectedProvider == 'Other') ...[
                  TextFormField(
                    controller: _customProviderController,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      labelText: 'Custom Courier Name',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _trackingIdController,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'Tracking ID',
                    prefixIcon: const Icon(Icons.tag),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _trackingLinkController,
                  decoration: InputDecoration(
                    labelText: 'Tracking Link (Optional)',
                    prefixIcon: const Icon(Icons.link),
                    helperText: 'Paste link so customers can track instantly.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (_selectedMethod == 'Hyperlocal') ...[
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    prefixIcon: const Icon(Icons.two_wheeler),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _hyperlocalProviders.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() {
                    _selectedProvider = val!;
                    if (val != 'Other') _customProviderController.clear();
                  }),
                ),
                const SizedBox(height: 16),
                if (_selectedProvider == 'Other') ...[
                  TextFormField(
                    controller: _customProviderController,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    decoration: InputDecoration(
                      labelText: 'Custom Service Name',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _trackingLinkController,
                  decoration: InputDecoration(
                    labelText: 'Live Tracking Link (Optional)',
                    prefixIcon: const Icon(Icons.map),
                    helperText: 'Share the live ride link from the app.',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'Rider Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (_selectedMethod == 'Local Transport') ...[
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: InputDecoration(
                    labelText: 'Transport Type',
                    prefixIcon: const Icon(Icons.directions_bus),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _transportProviders.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) => setState(() => _selectedProvider = val!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customProviderController,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'Transport Name (e.g. KSRTC, SRS Travels)',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiptController,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'LR / Ticket Number',
                    prefixIcon: const Icon(Icons.receipt),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Driver Contact (Optional)',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else if (_selectedMethod == 'Self Delivery') ...[
                InkWell(
                  onTap: _pickDateTime,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Expected Delivery Time',
                      prefixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _selectedDeliveryTime != null 
                          ? DateFormat('dd MMM, yyyy - hh:mm a').format(_selectedDeliveryTime!)
                          : 'Tap to select time',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  decoration: InputDecoration(
                    labelText: 'Delivery Person Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              const Text('Photo Proof (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Upload a photo of the courier receipt, LR copy, or parcel to protect yourself from disputes.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _receiptImage != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_receiptImage!, fit: BoxFit.cover),
                            Container(color: Colors.black38),
                            const Center(child: Icon(Icons.edit, color: Colors.white)),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Tap to upload photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                ),
              ),

              const SizedBox(height: 32),
              
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Confirm Dispatch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
