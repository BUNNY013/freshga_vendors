import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/presentation/widgets/premium_text_field.dart';
import '../../../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class EditOptionalDetailsScreen extends StatefulWidget {
  final ProductModel product;
  const EditOptionalDetailsScreen({super.key, required this.product});
  @override
  State<EditOptionalDetailsScreen> createState() => _EditOptionalDetailsScreenState();
}

class _EditOptionalDetailsScreenState extends State<EditOptionalDetailsScreen> {
  late ProductModel _product;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  
  late TextEditingController _storageCtrl;
  
  // Ingredients state
  late TextEditingController _ingredientInputCtrl;
  List<String> _ingredients = [];

  // Dispatch Time state
  late TextEditingController _dispatchTimeQtyCtrl;
  String _dispatchTimeUnit = 'Days';

  // Shelf Life state
  late TextEditingController _shelfLifeQtyCtrl;
  String _shelfLifeUnit = 'Months';

  @override
  void initState() {
    super.initState();
    _product = widget.product.applyDraftUpdates();
    
    _storageCtrl = TextEditingController(text: _product.storageInstructions);
    _ingredientInputCtrl = TextEditingController();
    _ingredients = List.from(_product.ingredients);

    // Parse existing Dispatch Time
    String dTime = _product.dispatchTime;
    String dQty = '';
    if (dTime.isNotEmpty) {
      final parts = dTime.split(' ');
      if (parts.isNotEmpty) dQty = parts[0];
      if (parts.length > 1) {
        final parsedUnit = parts[1];
        if (['Hours', 'Days', 'Weeks'].contains(parsedUnit)) {
          _dispatchTimeUnit = parsedUnit;
        }
      }
    }
    _dispatchTimeQtyCtrl = TextEditingController(text: dQty);
    
    // Parse existing Shelf Life
    String sTime = _product.shelfLife;
    String sQty = '';
    if (sTime.isNotEmpty) {
      final parts = sTime.split(' ');
      if (parts.isNotEmpty) sQty = parts[0];
      if (parts.length > 1) {
        final parsedUnit = parts[1];
        if (['Days', 'Weeks', 'Months', 'Years'].contains(parsedUnit)) {
          _shelfLifeUnit = parsedUnit;
        }
      }
    }
    _shelfLifeQtyCtrl = TextEditingController(text: sQty);
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) setState(() => _hasUnsavedChanges = true);
  }

  @override
  void dispose() {
    _storageCtrl.dispose();
    _ingredientInputCtrl.dispose();
    _dispatchTimeQtyCtrl.dispose();
    _shelfLifeQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate mandatory fields
    if (_dispatchTimeQtyCtrl.text.trim().isEmpty || _shelfLifeQtyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispatch time and shelf life are required fields.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If there is anything lingering in the ingredients input, add it
    if (_ingredientInputCtrl.text.trim().isNotEmpty) {
      _ingredients.add(_ingredientInputCtrl.text.trim());
      _ingredientInputCtrl.clear();
    }

    setState(() => _isSaving = true);
    
    String finalDispatchTime = '${_dispatchTimeQtyCtrl.text.trim()} $_dispatchTimeUnit'.trim();
    String finalShelfLife = '${_shelfLifeQtyCtrl.text.trim()} $_shelfLifeUnit'.trim();

    try {
      final provider = context.read<ProductProvider>();
      final success = await provider.updateOperationalFields(
        widget.product.productId,
        {
          'storageInstructions': _storageCtrl.text.trim(),
          'ingredients': _ingredients,
          'dispatchTime': finalDispatchTime,
          'shelfLife': finalShelfLife,
        },
        clearRequiredFix: 'others',
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to save changes. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        setState(() {
          _hasUnsavedChanges = false;
        });
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155), fontSize: 13)),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14)),
        ],
      ],
    );
  }

  InputDecoration _premiumInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges || _isSaving,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue Editing', style: TextStyle(color: AppColors.primary))),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (discard == true && mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)), onPressed: () => context.pop()),
          title: const Text('Freshness & Handling', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: InkWell(
                  onTap: _isSaving ? null : _handleSubmit,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _hasUnsavedChanges ? AppColors.primary : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: _hasUnsavedChanges ? AppColors.primary : const Color(0xFFE2E8F0)),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Save',
                            style: TextStyle(
                              color: _hasUnsavedChanges ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.requiredFixes.contains('others') || widget.product.reviewFeedback?['others']?['status'] == 'needs_fix') ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE2E2), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reviewer Feedback • Action Required',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${widget.product.reviewFeedback?['others']?['feedback'] ?? (widget.product.adminFeedback.isNotEmpty ? widget.product.adminFeedback : 'Please update your optional product details.')}"',
                        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              // CARD 1: PREPARATION & SHELF LIFE
              _buildCard(
                icon: Icons.schedule,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                title: 'Preparation & Shelf Life',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Dispatch Time", isRequired: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PremiumTextField(
                            label: '',
                            controller: _dispatchTimeQtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _markDirty(),
                            hintText: "e.g. 2",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _dispatchTimeUnit,
                            decoration: _premiumInputDecoration(""),
                            isExpanded: true,
                            items: ['Hours', 'Days', 'Weeks'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _dispatchTimeUnit = val;
                                  _hasUnsavedChanges = true;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildLabel("Shelf Life", isRequired: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: PremiumTextField(
                            label: '',
                            controller: _shelfLifeQtyCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _markDirty(),
                            hintText: "e.g. 3",
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _shelfLifeUnit,
                            decoration: _premiumInputDecoration(""),
                            isExpanded: true,
                            items: ['Days', 'Weeks', 'Months', 'Years'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _shelfLifeUnit = val;
                                  _hasUnsavedChanges = true;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CARD 2: INGREDIENTS
              _buildCard(
                icon: Icons.eco_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                title: 'Ingredients',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumTextField(
                      label: '',
                      controller: _ingredientInputCtrl,
                      onChanged: (_) => _markDirty(),
                      hintText: "e.g., Raw Mango, Mustard Seeds",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.primary),
                        onPressed: () {
                          if (_ingredientInputCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              _ingredients.add(_ingredientInputCtrl.text.trim());
                              _ingredientInputCtrl.clear();
                              _hasUnsavedChanges = true;
                            });
                          }
                        },
                      ),
                    ),
                    if (_ingredients.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _ingredients.map((item) => Chip(
                          label: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                          deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                          onDeleted: () => setState(() {
                            _ingredients.remove(item);
                            _hasUnsavedChanges = true;
                          }),
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // CARD 3: STORAGE INSTRUCTIONS
              _buildCard(
                icon: Icons.ac_unit,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Storage & Care Instructions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumTextField(
                      label: '',
                      controller: _storageCtrl,
                      maxLines: 3,
                      onChanged: (_) => _markDirty(),
                      hintText: "e.g., Store in a cool, dry place away from direct sunlight. Always use a clean dry spoon.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
