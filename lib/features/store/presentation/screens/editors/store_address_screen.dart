import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/store_model.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../../core/theme/app_colors.dart';

class StoreAddress {
  final String id;
  final String houseNumber;
  final String area;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final bool isPrimary;

  StoreAddress({
    required this.id,
    required this.houseNumber,
    required this.area,
    this.landmark = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.isPrimary = false,
  });

  StoreAddress copyWith({
    String? id,
    String? houseNumber,
    String? area,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    bool? isPrimary,
  }) {
    return StoreAddress(
      id: id ?? this.id,
      houseNumber: houseNumber ?? this.houseNumber,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class StoreAddressScreen extends StatefulWidget {
  const StoreAddressScreen({super.key});

  @override
  State<StoreAddressScreen> createState() => _StoreAddressScreenState();
}

class _StoreAddressScreenState extends State<StoreAddressScreen> {
  List<StoreAddress> _addresses = [];
  bool _isLoading = true;
  String? _storeId;

  bool _isFormMode = false;
  StoreAddress? _editingAddress;

  final _houseController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  bool _isFetchingPincode = false;
  bool _isApiFallback = true;
  String? _pincodeError;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana',
    'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 
    'Delhi', 'Lakshadweep', 'Puducherry', 'Jammu and Kashmir', 'Ladakh'
  ];

  @override
  void initState() {
    super.initState();
    _loadStoreAddress();
    _pincodeController.addListener(() {
      if (_pincodeController.text.length == 6 && !_isFetchingPincode) {
        _fetchCityStateFromPincode(_pincodeController.text);
      } else if (_pincodeController.text.length < 6) {
        if (_pincodeError != null) setState(() => _pincodeError = null);
      }
    });
  }

  @override
  void dispose() {
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreAddress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      _storeId = userDoc.data()?['storeId'];
      if (_storeId == null) return;
      
      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(_storeId).get();
      if (storeDoc.exists) {
        final data = storeDoc.data()!;
        final store = StoreModel.fromJson(data);
        final businessAddress = data['businessAddress'] as String? ?? '';
        final village = data['village'] as String? ?? '';
        
        if (businessAddress.isNotEmpty) {
          if (mounted) {
            setState(() {
              _addresses = [
                StoreAddress(
                  id: '1',
                  houseNumber: businessAddress,
                  area: village,
                  landmark: '',
                  city: store.city,
                  state: store.state,
                  pincode: store.pincode,
                  isPrimary: true,
                )
              ];
            });
          }
        } else {
          if (mounted) setState(() => _addresses = []);
        }
      }
    } catch (e) {
      debugPrint("Error loading address: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCityStateFromPincode(String pincode) async {
    setState(() {
      _isFetchingPincode = true;
      _pincodeError = null;
    });

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty && data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          
          String rawCity = postOffice['Block'] ?? postOffice['Region'] ?? postOffice['District'] ?? '';
          if (rawCity.endsWith(' City')) rawCity = rawCity.replaceAll(' City', '');
          
          setState(() {
            _cityController.text = rawCity;
            _stateController.text = postOffice['State'] ?? '';
            _pincodeError = null;
            _isApiFallback = false;
          });
        } else {
          setState(() {
            _pincodeError = "Invalid Pincode";
            _cityController.clear();
            _stateController.clear();
            _isApiFallback = true;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isApiFallback = true);
    } finally {
      if (mounted) {
        setState(() => _isFetchingPincode = false);
      }
    }
  }

  void _openForm([StoreAddress? address]) {
    setState(() {
      _isFormMode = true;
      _editingAddress = address;
      _pincodeError = null;
      
      if (address != null) {
        _houseController.text = address.houseNumber;
        _areaController.text = address.area;
        _landmarkController.text = address.landmark;
        _cityController.text = address.city;
        _stateController.text = address.state;
        _pincodeController.text = address.pincode;
        _isApiFallback = false;
      } else {
        _houseController.clear();
        _areaController.clear();
        _landmarkController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        _isApiFallback = true;
      }
    });
  }

  Future<void> _closeForm() async {
    bool hasChanges = false;
    
    if (_editingAddress == null) {
      hasChanges = _houseController.text.isNotEmpty || 
                   _areaController.text.isNotEmpty || 
                   _landmarkController.text.isNotEmpty ||
                   _pincodeController.text.isNotEmpty ||
                   _cityController.text.isNotEmpty ||
                   _stateController.text.isNotEmpty;
    } else {
      hasChanges = _houseController.text.trim() != _editingAddress!.houseNumber ||
                   _areaController.text.trim() != _editingAddress!.area ||
                   _landmarkController.text.trim() != _editingAddress!.landmark ||
                   _pincodeController.text.trim() != _editingAddress!.pincode ||
                   _cityController.text.trim() != _editingAddress!.city ||
                   _stateController.text.trim() != _editingAddress!.state;
    }
    
    if (hasChanges) {
      final confirm = await _showConfirmDialog(
        title: 'Discard Changes?',
        content: 'You have unsaved changes. Are you sure you want to discard them?',
        actionText: 'Discard',
        cancelText: 'Keep Editing',
        isDestructive: true,
      );
      if (!confirm) return;
    }

    setState(() {
      _isFormMode = false;
      _editingAddress = null;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate() || _pincodeError != null) return;
    if (_storeId == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('stores').doc(_storeId).update({
        'businessAddress': _houseController.text.trim(),
        'village': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
      });
      await _loadStoreAddress();
      if (mounted) {
        setState(() => _isFormMode = false);
      }
    } catch (e) {
      debugPrint("Error saving address: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setPrimary(String id) {
    setState(() {
      _addresses = _addresses.map((a) {
        return a.copyWith(isPrimary: a.id == id);
      }).toList();
    });
  }

  Future<void> _deleteAddress(String id) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Location?',
      content: 'Are you sure you want to remove this pickup location?',
      actionText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );
    
    if (!confirm || _storeId == null) return;

    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance.collection('stores').doc(_storeId).update({
        'businessAddress': '',
        'village': '',
        'city': '',
        'state': '',
        'pincode': '',
      });
      await _loadStoreAddress();
    } catch (e) {
      debugPrint("Error deleting address: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog({
    required String title, 
    required String content, 
    required String actionText, 
    required String cancelText, 
    bool isDestructive = false
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(cancelText, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructive ? const Color(0xFFEF4444) : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Pickup Addresses',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_isFormMode) {
              _closeForm();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : AnimatedCrossFade(
        firstChild: _buildListView(),
        secondChild: _buildFormView(),
        crossFadeState: _isFormMode ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
      bottomNavigationBar: (!_isFormMode && _addresses.length < 5) ? _buildStickyAddButton() : null,
    );
  }

  Widget _buildStickyAddButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: OutlinedButton.icon(
        onPressed: _openForm,
        icon: const Icon(Icons.add, size: 20, color: AppColors.primary),
        label: const Text('Add New Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add up to 5 pickup locations. Our logistics partners will use your selected Primary Address to securely pick up and dispatch your fresh products to customers.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          if (_addresses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text("No pickup addresses added yet.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
              ),
            ),
            
          ..._addresses.map((address) => _buildAddressCard(address)),
          
          
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildAddressCard(StoreAddress address) {
    final fullAddress = [
      address.houseNumber,
      address.area,
      if (address.landmark.isNotEmpty) 'Landmark: ${address.landmark}',
      '${address.city}, ${address.state} - ${address.pincode}'
    ].join('\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: address.isPrimary ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: address.isPrimary ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: address.isPrimary ? 2 : 1.5,
        ),
        boxShadow: [
          if (address.isPrimary) BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _setPrimary(address.id),
                child: Container(
                  margin: const EdgeInsets.only(top: 2, right: 12),
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: address.isPrimary ? AppColors.primary : const Color(0xFFCBD5E1), width: 2),
                  ),
                  child: address.isPrimary 
                    ? Center(child: Container(height: 12, width: 12, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)))
                    : null,
                ),
              ),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Pickup Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        if (address.isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                            child: const Text('PRIMARY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullAddress,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!address.isPrimary || _addresses.length == 1) 
                TextButton.icon(
                  onPressed: () => _deleteAddress(address.id),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                  label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              const SizedBox(width: 24),
              TextButton.icon(
                onPressed: () => _openForm(address),
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                label: const Text('Edit', style: TextStyle(color: Color(0xFF64748B))),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  _editingAddress == null ? 'Add New Location' : 'Edit Location',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 24),
                
                PremiumTextField(
                  label: 'Flat, House no., Building, Company',
                  isRequired: true,
                  controller: _houseController,
                  hintText: 'e.g. Flat 201, Sunshine Apts',
                  validator: (val) => val == null || val.trim().isEmpty ? 'House/Building is required' : null,
                ),

                const SizedBox(height: 20),
                PremiumTextField(
                  label: 'Area, Street, Sector, Village',
                  isRequired: true,
                  controller: _areaController,
                  hintText: 'e.g. Main Road, Sector 4',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Area/Street is required' : null,
                ),

                const SizedBox(height: 20),
                PremiumTextField(
                  label: 'Landmark',
                  isRequired: false,
                  controller: _landmarkController,
                  hintText: 'e.g. Near Apollo Hospital',
                ),

                const SizedBox(height: 20),
                PremiumTextField(
                  label: 'Pincode',
                  isRequired: true,
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (val) => val == null || val.length != 6 ? 'Enter valid 6-digit PIN' : null,
                  hintText: '6-digit pincode',
                  errorText: _pincodeError,
                  suffixIcon: _isFetchingPincode 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                ),
                if (_isFetchingPincode)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 4),
                    child: Text('Fetching City & State...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),

                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PremiumTextField(
                            label: 'City',
                            isRequired: true,
                            controller: _cityController, 
                            hintText: 'City',
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isApiFallback
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: const TextSpan(
                                      text: 'State',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                                      children: [
                                        TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _indianStates.contains(_stateController.text) ? _stateController.text : null,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                    ),
                                    hint: const Text('Select State', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                                    items: _indianStates.map((state) {
                                      return DropdownMenuItem(value: state, child: Text(state, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _stateController.text = val);
                                    },
                                    validator: (val) => val == null || val.isEmpty ? "Required" : null,
                                  )
                                ],
                              )
                            : PremiumTextField(
                                label: 'State',
                                isRequired: true,
                                controller: _stateController, 
                                hintText: 'State',
                                readOnly: true,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
                
              ],
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _closeForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isFetchingPincode ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                    ),
                    child: const Text('Save Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
