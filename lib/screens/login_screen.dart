import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/language_selector_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context);

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || authProvider.isSubmitting) {
      return;
    }

    setState(() {
      _authError = null;
    });

    try {
      await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _authError = _localizedAuthError(l10n, error.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _authError = _localizedAuthError(l10n, null);
      });
    }
  }

  String _localizedAuthError(AppLocalizations l10n, String? apiMessage) {
    if (apiMessage == null || apiMessage.trim().isEmpty) {
      return l10n.authUnavailableMessage;
    }

    if (l10n.isArabic) {
      return l10n.authApiSettingsMessage;
    }

    return apiMessage;
  }

  void _showCreateAccountMessage() {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.createAccountApiNextStep),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isMockMode = ApiConfig.useMockAuth || !ApiConfig.hasConfiguredBaseUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSelectorButton(
                          iconColor: Color.fromARGB(255, 110, 101, 168),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.local_hospital,
                        size: 80,
                        color: Color.fromARGB(255, 37, 101, 146),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CareTrack',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 37, 101, 146),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mobileNursingAssistant,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF7A7A7A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.loginDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      if (isMockMode) ...[
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.demoAuthModeNotice,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          hintText: l10n.emailHint,
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) {
                            return l10n.enterEmail;
                          }
                          if (!email.contains('@') || !email.contains('.')) {
                            return l10n.validEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return l10n.enterPassword;
                          }
                          if ((value ?? '').length < 6) {
                            return l10n.shortPassword;
                          }
                          return null;
                        },
                      ),
                      if (_authError != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _authError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: authProvider.isSubmitting ? null : () {},
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 110, 101, 168),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: authProvider.isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              37,
                              101,
                              146,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: authProvider.isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.signingIn,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  l10n.login,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: authProvider.isSubmitting
                            ? null
                            : _showCreateAccountMessage,
                        child: Text(
                          l10n.createAccount,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 110, 101, 168),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
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
