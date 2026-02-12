import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextFormFieldWidget extends StatefulWidget {
  final TextEditingController controller;
  final bool isPasswordField;
  final String text;
  final VoidCallback? onPressed;
  final Widget? suffixIcon;
  final int maxLines;
  final TextInputType keyboardType;
  const CustomTextFormFieldWidget({
    required this.controller,
    required this.isPasswordField,
    required this.text,
    this.onPressed,
    this.suffixIcon,
    this.maxLines = 1,
    this.keyboardType = .text,
    super.key,
  });

  @override
  State<CustomTextFormFieldWidget> createState() =>
      _CustomTextFormFieldWidgetState();
}

class _CustomTextFormFieldWidgetState extends State<CustomTextFormFieldWidget> {
  bool canSeePassword = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      style: TextStyle(color: Colors.grey),
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (widget.isPasswordField) {
            return "Enter Password";
          } else {
            return "Enter Propper Details";
          }
        }
        return null;
      },
      controller: widget.controller,
      textAlign: .start,
      obscureText: widget.isPasswordField ? !canSeePassword : false,
      decoration: InputDecoration(
        label: Text(
          widget.text,
          style: GoogleFonts.josefinSans(color: Colors.grey),
        ),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        suffixIcon: IconButton(
          onPressed:
              widget.onPressed ??
              () {
                if (!widget.isPasswordField) {
                  widget.controller.clear();
                } else {
                  setState(() {
                    canSeePassword = !canSeePassword;
                  });
                }
              },
          icon:
              widget.suffixIcon ??
              Icon(
                widget.isPasswordField
                    ? canSeePassword
                          ? Icons.lock_open
                          : Icons.lock
                    : Icons.clear,
              ),
        ),
      ),
    );
  }
}
