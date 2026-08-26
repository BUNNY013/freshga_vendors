import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';

class PremiumTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool isRequired;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final Function(String?)? onSaved;
  final Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final String? initialValue;
  final String? errorText;
  final String? helperText;

  const PremiumTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isRequired = false,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.onFieldSubmitted,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.contentPadding,
    this.initialValue,
    this.errorText,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                children: [
                  if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          initialValue: initialValue,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          onSaved: onSaved,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction: textInputAction,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          readOnly: readOnly,
          onTap: onTap,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            helperText: helperText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: prefixIcon,
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
            suffixIcon: suffixIcon,
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
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
