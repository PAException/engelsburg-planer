/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';

typedef Validator = String? Function(String value);

class PasswordTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final Validator? validator;

  const PasswordTextFormField({
    Key? key,
    required this.controller,
    this.validator,
  }) : super(key: key);

  @override
  PasswordTextFormFieldState createState() => PasswordTextFormFieldState();
}

class PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscured = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.visiblePassword,
      obscureText: _obscured,
      onChanged: (text) {
        if (_obscured == false) {
          setState(() => _obscured = true);
        }
      },
      validator: (value) {
        if (value == null || value.isBlank) {
          return context.l10n.noPasswordSpecified;
        }

        if (widget.validator != null) return widget.validator!(value);
        return null;
      },
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: context.l10n.password,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
          child: GestureDetector(
            onTap: () => setState(() => _obscured = !_obscured),
            child:
                Icon(_obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 24),
          ),
        ),
      ),
    );
  }
}
