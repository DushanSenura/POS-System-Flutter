import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../shared/widgets/custom_buttons.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../../scanner/services/barcode_scanner_service.dart';
import '../widgets/change_password_dialog.dart';

/// Login screen widget
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Verify credentials with users provider
      final user = ref
          .read(usersProvider.notifier)
          .findUserByEmail(_emailController.text.trim());

      final isValid = ref
          .read(usersProvider.notifier)
          .verifyCredentials(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (isValid && user != null) {
        // Check if user must change password
        if (user.mustChangePassword) {
          if (mounted) {
            _showChangePasswordDialog(user.id);
          }
          return;
        }

        await ref
            .read(authProvider.notifier)
            .login(_emailController.text, _passwordController.text, user: user);

        final authState = ref.read(authProvider);
        if (authState.hasValue && authState.value != null) {
          if (mounted) {
            // Navigate to home screen
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, 'Invalid email or password');
        }
      }
    }
  }

  void _showChangePasswordDialog(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangePasswordDialog(
        userId: userId,
        onPasswordChanged: () {
          // After password change, proceed with login
          _handleLogin();
        },
      ),
    );
  }

  void _handleQRLogin() async {
    try {
      final qrCode = await BarcodeScannerService.showScannerDialog(context);

      if (qrCode != null && mounted) {
        // Verify QR code with users provider
        final user = ref.read(usersProvider.notifier).verifyQRCode(qrCode);

        if (user != null) {
          // Check if user must change password
          if (user.mustChangePassword) {
            if (mounted) {
              _showChangePasswordDialog(user.id);
            }
            return;
          }

          await ref
              .read(authProvider.notifier)
              .login(user.email, '', user: user); // Login with user data

          if (mounted) {
            SnackBarHelper.showSuccess(context, 'Login successful');
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          if (mounted) {
            SnackBarHelper.showError(
              context,
              'Invalid QR code. Please try again.',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'QR scan failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 600;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isLargeScreen ? 48 : 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icon
                        Icon(
                          Icons.point_of_sale_rounded,
                          size: isLargeScreen ? 80 : 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'POS Management',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 16 : 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Email Field
                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                const Text(
                                  'Remember Me',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // Handle forgot password
                                SnackBarHelper.showInfo(
                                  context,
                                  'Forgot password feature coming soon',
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        PrimaryButton(
                          text: 'Sign In',
                          onPressed: isLoading ? null : _handleLogin,
                          isLoading: isLoading,
                          height: 52,
                        ),
                        const SizedBox(height: 16),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // QR Code Login Button
                        OutlinedButton.icon(
                          onPressed: isLoading ? null : _handleQRLogin,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Login with QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Demo Credentials
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
