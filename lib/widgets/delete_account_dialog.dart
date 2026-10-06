import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Confirms account deletion in one step: the user enters their password and
/// taps Delete. Errors (like a wrong password) show inline so the user can
/// fix them without starting over. Pops `true` once deletion succeeds.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.email,
    required this.onDelete,
  });

  final String? email;

  /// Confirms the password and deletes the account. Returns an error message
  /// to show, or null when the account was deleted.
  final Future<String?> Function(String password) onDelete;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild so the Delete button enables once a password is typed.
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_busy && _passwordController.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onDelete(_passwordController.text);
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;

    return PopScope(
      // Don't let a back gesture interrupt a deletion in progress.
      canPop: !_busy,
      child: AlertDialog(
        title: const Text('Delete your account?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your VitaMind account, your mood, '
                'symptom, journal, and reminder data, and this profile’s data '
                'on this device. This can’t be undone.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                autofocus: true,
                enabled: !_busy,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: email == null
                      ? 'Enter your password to confirm.'
                      : 'Enter the password for $email.',
                  helperMaxLines: 2,
                  errorText: _error,
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      semanticsLabel: 'Deleting account',
                    ),
                  )
                : const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
