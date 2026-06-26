import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
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
    String dUnit = 'Days';
    if (dTime.isNotEmpty) {
      final parts = dTime.split(' ');
      if (parts.isNotEmpty) dQty = parts[0];
      if (parts.length > 1) dUnit = parts[1];
    }
    _dispatchTimeQtyCtrl = TextEditingController(text: dQty);
    
    // Parse existing Shelf Life
    String sTime = _product.shelfLife;
    String sQty = '';
    String sUnit = 'Months';
    if (sTime.isNotEmpty) {
      final parts = sTime.split(' ');
      if (parts.isNotEmpty) sQty = parts[0];
      if (parts.length > 1) sUnit = parts[1];
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
    // If there is anything lingering in the ingredients input, add it
    if (_ingredientInputCtrl.text.trim().isNotEmpty) {
      _ingredients.add(_ingredientInputCtrl.text.trim());
      _ingredientInputCtrl.clear();
    }

    setState(() => _isSaving = true);
    
    String finalDispatchTime = '${_dispatchTimeQtyCtrl.text.trim()} $_dispatchTimeUnit'.trim();
    if (_dispatchTimeQtyCtrl.text.trim().isEmpty) finalDispatchTime = '';
    
    String finalShelfLife = '${_shelfLifeQtyCtrl.text.trim()} $_shelfLifeUnit'.trim();
    if (_shelfLifeQtyCtrl.text.trim().isEmpty) finalShelfLife = '';

    try {
      final provider = context.read<ProductProvider>();
      await provider.updateDraftContent(
        widget.product,
        {
          'storageInstructions': _storageCtrl.text.trim(),
          'ingredients': _ingredients,
          'dispatchTime': finalDispatchTime,
          'shelfLife': finalShelfLife,
        },
        clearRequiredFix: 'others',
      );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasUnsavedChanges = false;
        });
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13));
  }

  InputDecoration _premiumInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grey400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: const Color(0xFFF8F9FA),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop()),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Others', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Additional product information', style: TextStyle(color: AppColors.grey500, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Ingredients"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ingredientInputCtrl,
                onChanged: (_) => _markDirty(),
                decoration: _premiumInputDecoration("e.g., Raw Mango, Mustard Seeds").copyWith(
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
                onFieldSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _ingredients.add(val.trim());
                      _ingredientInputCtrl.clear();
                      _hasUnsavedChanges = true;
                    });
                  }
                },
              ),
              if (_ingredients.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _ingredients.map((item) => Chip(
                    label: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() {
                      _ingredients.remove(item);
                      _hasUnsavedChanges = true;
                    }),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  )).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Dispatch Time"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _dispatchTimeQtyCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _markDirty(),
                          decoration: _premiumInputDecoration("e.g. 2").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _dispatchTimeUnit,
                          decoration: _premiumInputDecoration("").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16)),
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
                  const SizedBox(height: 24),
                  _buildLabel("Shelf Life"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _shelfLifeQtyCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _markDirty(),
                          decoration: _premiumInputDecoration("e.g. 3").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _shelfLifeUnit,
                          decoration: _premiumInputDecoration("").copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16)),
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
              
              const SizedBox(height: 24),
              _buildLabel("Storage Instructions"),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storageCtrl,
                maxLines: 2,
                onChanged: (_) => _markDirty(),
                decoration: _premiumInputDecoration("Keep in a cool and dry place. Use clean spoon."),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_product.status == 'Draft' ? 'Save & Submit Review' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.grey500, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Your changes will be reviewed before going live.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
