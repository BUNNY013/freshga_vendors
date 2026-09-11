import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../../../core/presentation/widgets/premium_text_field.dart';

class SocialLinksScreen extends StatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  State<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final store = Provider.of<StoreProvider>(context, listen: false).store;
    if (store != null) {
      _instagramCtrl.text = store.instagramLink;
      _facebookCtrl.text = store.facebookLink;
      _youtubeCtrl.text = store.youtubeLink;
      _whatsappCtrl.text = store.whatsappNumber;
    }
  }

  @override
  void dispose() {
    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _youtubeCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLinks() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final provider = Provider.of<StoreProvider>(context, listen: false);
    
    await provider.updateSocialLinks(
      instagram: _instagramCtrl.text.trim(),
      facebook: _facebookCtrl.text.trim(),
      youtube: _youtubeCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Social links updated successfully"),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Social Links',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _saveLinks,
              child: const Text('Save', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumTextField(
                label: 'WhatsApp Number (Optional)',
                controller: _whatsappCtrl,
                hintText: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length != 10) {
                    return 'WhatsApp number must be exactly 10 digits';
                  }
                  return null;
                },
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/images/whatsapp_icon.png', width: 24, height: 24),
                ),
              ),
            const SizedBox(height: 24),
            PremiumTextField(
              label: 'Instagram (Optional)',
              controller: _instagramCtrl,
              hintText: 'Instagram URL',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset('assets/images/instagram_icon.png', width: 24, height: 24),
              ),
            ),
            const SizedBox(height: 24),
            PremiumTextField(
              label: 'Facebook (Optional)',
              controller: _facebookCtrl,
              hintText: 'Facebook URL',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image.asset('assets/images/facebook_icon.png', width: 24, height: 24),
              ),
            ),
            const SizedBox(height: 24),
              PremiumTextField(
                label: 'YouTube (Optional)',
                controller: _youtubeCtrl,
                hintText: 'YouTube Channel URL',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/images/youtube_icon.png', width: 24, height: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
