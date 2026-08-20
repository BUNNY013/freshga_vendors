import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';

class BankUpdateSheet extends StatefulWidget {
  final String storeId;

  const BankUpdateSheet({Key? key, required this.storeId}) : super(key: key);

  @override
  State<BankUpdateSheet> createState() => _BankUpdateSheetState();
}

class _BankUpdateSheetState extends State<BankUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  
  bool _isLoading = false;
  String _lastFetchedIfsc = '';

  @override
  void initState() {
    super.initState();
    _ifscController.addListener(_onIfscChanged);
  }

  void _onIfscChanged() {
    final text = _ifscController.text.trim();
    if (text.length == 11) {
      if (_lastFetchedIfsc != text) {
        _lastFetchedIfsc = text;
        _fetchBankDetailsFromIFSC(text);
      }
    } else {
      if (_lastFetchedIfsc.isNotEmpty) {
        _lastFetchedIfsc = '';
        _bankNameController.text = ''; // Clear it if they start deleting the IFSC
      }
    }
  }

  Future<void> _fetchBankDetailsFromIFSC(String ifsc) async {
    try {
      final response = await http.get(Uri.parse('https://ifsc.razorpay.com/$ifsc'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _bankNameController.text = '${data['BANK']} (${data['BRANCH']})';
          });
        }
      }
    } catch (e) {
      debugPrint('IFSC fetch error: $e');
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('bankUpdateRequests').add({
        'userId': user.uid,
        'storeId': widget.storeId,
        'requestedBankDetails': {
          'bankName': _bankNameController.text.trim(),
          'accountHolderName': _accountHolderController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'ifscCode': _ifscController.text.trim().toUpperCase(),
        },
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank update request submitted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, 
        right: 24, 
        top: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Update Bank Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Submit your new bank details. This will require admin approval before becoming active.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              
              _buildTextField('IFSC Code', _ifscController, 'e.g. HDFC0001234', (val) => val!.isEmpty ? 'Required' : null, textCapitalization: TextCapitalization.characters, inputFormatters: [UpperCaseTextFormatter()]),
              const SizedBox(height: 16),
              _buildTextField('Bank Name', _bankNameController, 'e.g. HDFC Bank', (val) => val!.isEmpty ? 'Required' : null, isReadOnly: true),
              const SizedBox(height: 16),
              _buildTextField('Account Holder Name', _accountHolderController, 'As per bank records', (val) => val!.isEmpty ? 'Required' : null, textCapitalization: TextCapitalization.characters, inputFormatters: [UpperCaseTextFormatter()]),
              const SizedBox(height: 16),
              _buildTextField('Account Number', _accountNumberController, 'Enter account number', (val) => val!.isEmpty ? 'Required' : null, isNumber: true),
              const SizedBox(height: 16),
              _buildTextField(
                'Confirm Account Number', 
                _confirmAccountNumberController, 
                'Re-enter account number', 
                (val) {
                  if (val!.isEmpty) return 'Required';
                  if (val != _accountNumberController.text) return 'Account numbers do not match';
                  return null;
                }, 
                isNumber: true
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? () {} : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, String? Function(String?) validator, {bool isNumber = false, bool isReadOnly = false, TextCapitalization textCapitalization = TextCapitalization.none, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: validator,
          readOnly: isReadOnly,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters ?? (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
