import 'package:flutter/material.dart';

class VitaMindPrimaryButton extends StatelessWidget {
  const VitaMindPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final buttonIcon = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon ?? Icons.check);

    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: buttonIcon,
      label: Text(label),
    );
  }
}

class VitaMindSecondaryButton extends StatelessWidget {
  const VitaMindSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.chevron_right),
      label: Text(label),
    );
  }
}
