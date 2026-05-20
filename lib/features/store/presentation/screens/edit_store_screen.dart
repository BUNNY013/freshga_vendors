import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/store_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  StoreModel? _store;

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _instaController;
  String _dispatchTime = '24 hours';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _instaController = TextEditingController();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userModel = UserModel.fromJson(userDoc.data()!);

    if (userModel.storeId.isNotEmpty) {
      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(userModel.storeId).get();
      if (storeDoc.exists) {
        _store = StoreModel.fromJson(storeDoc.data()!);
        _nameController.text = _store!.storeName;
        _descController.text = _store!.description;
        _instaController.text = _store!.instagramLink;
        _dispatchTime = _store!.dispatchTime;
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate() || _store == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedStore = _store!.copyWith(
        storeName: _nameController.text,
        description: _descController.text,
        instagramLink: _instaController.text,
        dispatchTime: _dispatchTime,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_store!.storeId)
          .update(updatedStore.toJson());

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Store', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving || _isLoading ? null : _saveStore,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Store Info", style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Store Name"),
                      validator: (val) => val == null || val.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Brand Story"),
                    ),
                    const SizedBox(height: 32),
                    const Text("Settings", style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instaController,
                      decoration: const InputDecoration(labelText: "Instagram Link"),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _dispatchTime,
                      decoration: const InputDecoration(labelText: "Dispatch Time"),
                      items: const [
                        DropdownMenuItem(value: '24 hours', child: Text("Within 24 hours")),
                        DropdownMenuItem(value: '48 hours', child: Text("Within 48 hours")),
                        DropdownMenuItem(value: '3-4 days', child: Text("3-4 days")),
                        DropdownMenuItem(value: '1 week', child: Text("1 week")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _dispatchTime = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
