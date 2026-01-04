import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:flutter/rendering.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/users_provider.dart';

/// Dialog to create login account for employee
class CreateLoginAccountDialog extends ConsumerStatefulWidget {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String employeeRole;
  final Function(User) onAccountCreated;

  const CreateLoginAccountDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeeRole,
    required this.onAccountCreated,
  });

  @override
  ConsumerState<CreateLoginAccountDialog> createState() =>
      _CreateLoginAccountDialogState();
}

class _CreateLoginAccountDialogState
    extends ConsumerState<CreateLoginAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  User? _createdUser;
  bool _showQRCode = false;
  bool _qrCodeDownloaded = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.employeeEmail);
    _passwordController = TextEditingController(text: _generatePassword());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Generate a random password
  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email already exists
      final existingUser = ref
          .read(usersProvider.notifier)
          .findUserByEmail(_emailController.text.trim());

      if (existingUser != null) {
        SnackBarHelper.showError(
          context,
          'Email already exists. Please use a different email.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create user account
      final user = ref
          .read(usersProvider.notifier)
          .addUser(
            id: widget.employeeId,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: widget.employeeName,
            role: widget.employeeRole,
            employeeId: widget.employeeId,
          );

      setState(() {
        _createdUser = user;
        _showQRCode = true;
        _isLoading = false;
      });

      widget.onAccountCreated(user);
      SnackBarHelper.showSuccess(context, 'Login account created successfully');
    } catch (e) {
      SnackBarHelper.showError(context, 'Error: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _regeneratePassword() {
    setState(() {
      _passwordController.text = _generatePassword();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    SnackBarHelper.showSuccess(context, 'Copied to clipboard');
  }

  Future<void> _downloadQRCode() async {
    if (_createdUser == null || _qrCodeDownloaded) return;

    try {
      // For Windows, we'll just copy the QR data and show a message
      // In a full implementation, you'd save the image to a file
      Clipboard.setData(ClipboardData(text: _createdUser!.qrCode ?? ''));

      // Mark as downloaded
      ref.read(usersProvider.notifier).markQRCodeDownloaded(_createdUser!.id);

      setState(() {
        _qrCodeDownloaded = true;
      });

      SnackBarHelper.showSuccess(
        context,
        'QR code data copied! This is your only download.',
      );
    } catch (e) {
      SnackBarHelper.showError(context, 'Failed to download QR code');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showQRCode && _createdUser != null) {
      return _buildQRCodeView();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Login Account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Set up credentials for employee login',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Employee Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employeeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.employeeRole,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              CustomTextField(
                label: 'Email *',
                controller: _emailController,
                hint: 'Enter login email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              CustomTextField(
                label: 'Password *',
                controller: _passwordController,
                hint: 'Auto-generated password',
                enabled: false,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _regeneratePassword,
                      tooltip: 'Generate new password',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () =>
                          _copyToClipboard(_passwordController.text),
                      tooltip: 'Copy password',
                    ),
                  ],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Password info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A secure password has been generated. Employee can use email & password or scan QR code to login.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    text: 'Create Account',
                    onPressed: _isLoading ? null : _createAccount,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCodeView() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Account Created Successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR code or use credentials to login',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Password change warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'User must change password on first login',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: QrImageView(
                data: _createdUser!.qrCode ?? '',
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Credentials Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildCredentialRow(
                    'Email',
                    _createdUser!.email,
                    Icons.email_outlined,
                  ),
                  const Divider(height: 24),
                  _buildCredentialRow(
                    'Password',
                    _passwordController.text,
                    Icons.lock_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download QR warning if not downloaded yet
            if (!_qrCodeDownloaded)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can only download the QR code once!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_qrCodeDownloaded) const SizedBox(height: 16),

            // Action Buttons
            Column(
              children: [
                // Download QR Code Button
                if (!_qrCodeDownloaded)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _downloadQRCode,
                      icon: const Icon(Icons.download),
                      label: const Text('Download QR Code (One Time Only)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (!_qrCodeDownloaded) const SizedBox(height: 12),

                // Bottom action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final credentials =
                              'Email: ${_createdUser!.email}\nPassword: ${_passwordController.text}';
                          _copyToClipboard(credentials);
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Credentials'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Done',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(value),
          tooltip: 'Copy',
        ),
      ],
    );
  }
}
