import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/validators.dart';
import '../../routes/app_router.dart';
import '../../theme/app_colors.dart';
import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthProvider auth = context.read<AuthProvider>();
    final bool success = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please contact your administrator to reset your password.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final Size size = MediaQuery.sizeOf(context);
    final bool compact = size.height < 700;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: compact ? 24 : 48),
                        const Text(
                          AppConfig.companyName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppConfig.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 14,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: compact ? 28 : 44),
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sign in to continue to your CRM',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  key: const Key('login_email_field'),
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  validator: (String? value) =>
                                      Validators.email(value, required: true),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  key: const Key('login_password_field'),
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: Validators.password,
                                ),
                                if (auth.errorMessage != null) ...<Widget>[
                                  const SizedBox(height: 16),
                                  Container(
                                    key: const Key('login_error'),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.alpha(AppColors.danger, 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(Icons.error_outline,
                                            color: AppColors.danger, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: const TextStyle(
                                                color: AppColors.danger, fontSize: 13.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  key: const Key('login_button'),
                                  onPressed: auth.isBusy ? null : _submit,
                                  child: auth.isBusy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: AppColors.white,
                                            strokeWidth: 2.4,
                                          ),
                                        )
                                      : const Text('LOGIN'),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: auth.isBusy ? null : _forgotPassword,
                                  child: const Text('Forgot password?'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 32),
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
