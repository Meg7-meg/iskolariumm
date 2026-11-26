import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/supabase_client_provider.dart';
import 'auth_palette.dart';

// ============================================================
// ISKOLARIUM AUTHENTICATION SCREENS
// ============================================================

class LoginScreen extends StatefulWidget {
  final String role;
  final WidgetBuilder destinationBuilder;

  const LoginScreen({
    super.key,
    required this.role,
    required this.destinationBuilder,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _keepSignedIn = true;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignUpScreen(role: widget.role)),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _formError = null;
    });

    try {
      await AuthService.signInWithRole(
        email: email,
        password: password,
        expectedRole: widget.role,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: widget.destinationBuilder),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      final message =
          error.message.toLowerCase().contains('invalid login credentials')
          ? 'Incorrect email or password. Try again or reset your password.'
          : error.message;
      setState(() => _formError = message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = formatSupabaseError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _showSocialMessage(String provider) async {
    final oauthProvider = provider == 'Apple'
        ? OAuthProvider.apple
        : OAuthProvider.google;
    try {
      await supabase.auth.signInWithOAuth(oauthProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(formatSupabaseError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScreenFrame(
      title: 'Welcome back',
      subtitle: 'Sign in to your ${widget.role} workspace.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('School email'),
            const SizedBox(height: 6),
            _buildInput(
              controller: _emailController,
              hint: 'you@school.edu',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              onChanged: (_) => _clearFormError(),
            ),
            const SizedBox(height: 14),
            _buildLabel('Password'),
            const SizedBox(height: 6),
            _buildInput(
              controller: _passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              validator: (value) => (value ?? '').isEmpty
                  ? 'Enter your password to continue.'
                  : null,
              onChanged: (_) => _clearFormError(),
              suffix: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthPalette.body,
                  size: 20,
                ),
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              _InlineError(message: _formError!),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _keepSignedIn,
                    onChanged: (value) {
                      setState(() => _keepSignedIn = value ?? false);
                    },
                    activeColor: AuthPalette.actionBlue,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Keep me signed in',
                    style: TextStyle(color: AuthPalette.body, fontSize: 12),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.actionBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryAuthButton(
              onPressed: _isLoading ? null : _handleLogin,
              loading: _isLoading,
              label: 'Sign in',
              loadingLabel: 'Signing in…',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: AuthPalette.inputBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      color: AuthPalette.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AuthPalette.inputBorder)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _socialButton(
                    label: 'Google',
                    icon: const _GoogleIcon(),
                    onPressed: () => _showSocialMessage('Google'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _socialButton(
                    label: 'Apple',
                    icon: const Icon(
                      LucideIcons.apple,
                      size: 20,
                      color: AuthPalette.heading,
                    ),
                    onPressed: () => _showSocialMessage('Apple'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'New here? ',
                    style: TextStyle(color: AuthPalette.body, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: _openSignUp,
                    style: TextButton.styleFrom(
                      foregroundColor: AuthPalette.actionBlue,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    return _validateAuthEmail(value);
  }

  void _clearFormError() {
    if (_formError != null) setState(() => _formError = null);
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AuthPalette.heading,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: AuthPalette.heading, fontSize: 14),
      decoration: _authInputDecoration(hint: hint, icon: icon, suffix: suffix),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AuthPalette.heading,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AuthPalette.inputBorder),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// Google logo placeholder
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4285F4),
      ),
    );
  }
}

InputDecoration _authInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: AuthPalette.actionBlue, size: 20),
    suffixIcon: suffix,
    hintText: hint,
    hintStyle: const TextStyle(color: AuthPalette.muted, fontSize: 13),
    filled: true,
    fillColor: AuthPalette.iceBlue,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AuthPalette.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AuthPalette.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AuthPalette.actionBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB42318)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
    ),
  );
}

String? _validateAuthEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your school email to continue.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'That doesn’t look like a valid email address.';
  }
  return null;
}

class SignUpScreen extends StatefulWidget {
  final String role;

  const SignUpScreen({super.key, required this.role});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final hasSession = await AuthService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        role: widget.role,
      );

      if (!mounted) return;

      final message = !hasSession
          ? 'Account created! Please verify your email, then sign in.'
          : 'Account created! You can now sign in.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(formatSupabaseError(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScreenFrame(
      title: 'Create your account',
      subtitle: 'Set up your ${widget.role} workspace in seconds.',
      onBack: () => Navigator.pop(context),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldLabel('Full name'),
            const SizedBox(height: 6),
            _textField(
              controller: _nameController,
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your name to continue.';
                }
                if (value.trim().length < 2) {
                  return 'Enter a name with at least 2 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('School email'),
            const SizedBox(height: 6),
            _textField(
              controller: _emailController,
              hint: 'you@school.edu',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: _validateAuthEmail,
            ),
            const SizedBox(height: 14),
            _fieldLabel('Create password'),
            const SizedBox(height: 6),
            _textField(
              controller: _passwordController,
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthPalette.body,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a password to continue.';
                }
                if (value.length < 8) {
                  return 'Use at least 8 characters for a stronger password.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _fieldLabel('Confirm password'),
            const SizedBox(height: 6),
            _textField(
              controller: _confirmPasswordController,
              hint: 'Re-enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              suffix: IconButton(
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthPalette.body,
                  size: 20,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password again.';
                }
                if (value != _passwordController.text) {
                  return 'Those passwords don’t match yet.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _PrimaryAuthButton(
              onPressed: _isLoading ? null : _handleCreateAccount,
              loading: _isLoading,
              label: 'Create account',
              loadingLabel: 'Creating account…',
            ),
            const SizedBox(height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AuthPalette.body, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AuthPalette.actionBlue,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AuthPalette.heading,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: AuthPalette.heading, fontSize: 14),
      decoration: _authInputDecoration(hint: hint, icon: icon, suffix: suffix),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitted = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetRequest() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.sendPasswordReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSubmitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(formatSupabaseError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScreenFrame(
      title: 'Reset your password',
      subtitle: 'Enter your school email and we’ll send a reset link.',
      onBack: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _isSubmitted ? _buildSuccess() : _buildForm(),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AuthPalette.actionBlue,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Back to sign in',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResetLabel('School email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetRequest(),
            style: const TextStyle(color: AuthPalette.heading, fontSize: 14),
            validator: _validateAuthEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _authInputDecoration(
              hint: 'you@school.edu',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryAuthButton(
            onPressed: _isLoading ? null : _handleResetRequest,
            loading: _isLoading,
            label: 'Send reset link',
            loadingLabel: 'Sending reset link…',
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AuthPalette.heading,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Check your inbox—we sent a reset link to your email.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthPalette.body,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _emailController.text.trim(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AuthPalette.actionBlue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isSubmitted = false;
              _emailController.clear();
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AuthPalette.actionBlue,
            side: const BorderSide(color: AuthPalette.inputBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Try another email'),
        ),
      ],
    );
  }

  Widget _buildResetLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AuthPalette.heading,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _AuthScreenFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final Widget child;

  const _AuthScreenFrame({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthPalette.heroStart,
        body: Container(
          color: AuthPalette.iceBlue,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final headerHeight = (constraints.maxHeight * 0.34)
                    .clamp(220.0, 300.0)
                    .toDouble();

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: AuthPalette.heroGradient,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                left: 12,
                                child: IconButton(
                                  tooltip: 'Back',
                                  onPressed: onBack,
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    48,
                                    24,
                                    16,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AuthPalette.onBlue,
                                          fontSize: 13.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A0B1D36),
                                      blurRadius: 24,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final String loadingLabel;

  const _PrimaryAuthButton({
    required this.onPressed,
    required this.loading,
    required this.label,
    required this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthPalette.actionBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(loadingLabel),
                ],
              )
            : Text(label),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 12,
          height: 1.35,
        ),
      ),
    );
  }
}
