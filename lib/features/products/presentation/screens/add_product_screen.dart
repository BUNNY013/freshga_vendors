import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _shortDescription = '';
  String _description = '';
  double _price = 0;
  double _discountPrice = 0;
  String _weight = '';
  String _shelfLife = '';
  String _ingredients = '';
  String _category = 'Main Course';
  String _subCategory = '';
  String _tags = '';
  int _stock = 0;
  String _status = 'Published';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading ? null : () => _submit(provider),
                child: provider.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.errorMessage != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.red.withOpacity(0.1),
                      child: Text(provider.errorMessage!, style: const TextStyle(color: Colors.red)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              _buildImageUploadSection(),
              const SizedBox(height: 32),
              _buildBasicInfoSection(),
              const SizedBox(height: 32),
              _buildPricingSection(),
              const SizedBox(height: 32),
              _buildDetailsSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(ProductProvider provider) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final product = ProductModel(
        productId: '', // assigned in provider
        storeId: '', // assigned in provider
        name: _name,
        shortDescription: _shortDescription,
        description: _description,
        price: _price,
        discountPrice: _discountPrice,
        weight: _weight,
        shelfLife: _shelfLife,
        ingredients: _ingredients.split(',').map((e) => e.trim()).toList(),
        category: _category,
        subCategory: _subCategory,
        tags: _tags.split(',').map((e) => e.trim()).toList(),
        stock: _stock,
        images: [], // handled in provider
        status: _status,
        likesCount: 0,
        createdAt: '',
        updatedAt: '',
      );

      final success = await provider.addProduct(product);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  Widget _buildImageUploadSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Product Images", style: AppTextStyles.h2),
            const SizedBox(height: 8),
            const Text("Upload appetizing photos of your homemade product.", style: AppTextStyles.bodyText),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index == provider.selectedImages.length) {
                    return GestureDetector(
                      onTap: provider.pickImages,
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColors.primary),
                            SizedBox(height: 8),
                            Text("Add Photos", style: TextStyle(color: AppColors.primary, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(provider.selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 24,
                        child: GestureDetector(
                          onTap: () => provider.removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Basic Info", style: AppTextStyles.h2),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: "Product Name", hintText: "e.g., Spicy Mango Pickle"),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          onSaved: (val) => _name = val ?? '',
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: "Short Description", hintText: "A brief catchy description"),
          onSaved: (val) => _shortDescription = val ?? '',
        ),
        const SizedBox(height: 16),
        TextFormField(
          maxLines: 4,
          decoration: const InputDecoration(labelText: "Full Description", hintText: "Tell the story of this product..."),
          onSaved: (val) => _description = val ?? '',
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pricing & Inventory", style: AppTextStyles.h2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Price (₹)", prefixText: "₹ "),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _price = double.tryParse(val ?? '0') ?? 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Discount Price (Optional)", prefixText: "₹ "),
                onSaved: (val) => _discountPrice = double.tryParse(val ?? '0') ?? 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock Available", hintText: "0"),
                onSaved: (val) => _stock = int.tryParse(val ?? '0') ?? 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(value: 'Published', child: Text("Published")),
                  DropdownMenuItem(value: 'Draft', child: Text("Draft")),
                  DropdownMenuItem(value: 'Hidden', child: Text("Hidden")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _status = val);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Product Details", style: AppTextStyles.h2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: "Weight/Quantity", hintText: "e.g., 500g"),
                onSaved: (val) => _weight = val ?? '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: "Shelf Life", hintText: "e.g., 6 Months"),
                onSaved: (val) => _shelfLife = val ?? '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: "Ingredients (Comma separated)"),
          onSaved: (val) => _ingredients = val ?? '',
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(labelText: "Tags (Comma separated)"),
          onSaved: (val) => _tags = val ?? '',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _category,
          decoration: const InputDecoration(labelText: "Category"),
          items: const [
            DropdownMenuItem(value: 'Main Course', child: Text("Main Course")),
            DropdownMenuItem(value: 'Desserts', child: Text("Desserts")),
            DropdownMenuItem(value: 'Pickles', child: Text("Pickles")),
            DropdownMenuItem(value: 'Snacks', child: Text("Snacks")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _category = val);
            }
          },
        ),
      ],
    );
  }
}
