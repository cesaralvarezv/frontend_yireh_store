import 'dart:async';

import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../repositories/auth_repository.dart';
import '../../services/auth_service.dart';
import '../../services/credential_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_tab_selector.dart';
import '../../widgets/custom_divider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_view.dart';
import '../home/admin_panel_view.dart';
import 'register_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  late final AuthController _controller;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberCredentials = false;

  @override
  void initState() {
    super.initState();
    // DIP: controller depende de abstracción → ApiAuthService conecta a 172.20.1.4:8080
    _controller = AuthController(
      repository: AuthRepositoryImpl(service: ApiAuthService()),
    );
    _controller.addListener(_onControllerChanged);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final saved = await CredentialStorage.load();
      if (!mounted || saved == null) return;
      setState(() {
        _emailController.text = saved.email;
        _passwordController.text = saved.password;
        _rememberCredentials = true;
      });
    } catch (_) {
      // Si falla la lectura, el login sigue funcionando sin credenciales guardadas.
    }
  }

  void _onRememberChanged(bool? value) {
    final remember = value ?? false;
    setState(() => _rememberCredentials = remember);
    if (!remember) {
      unawaited(CredentialStorage.clear());
    }
  }

  Widget _buildRememberMe() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _rememberCredentials,
            onChanged: _onRememberChanged,
            activeColor: AppColors.primary,
            checkColor: Colors.white,
            side: const BorderSide(color: AppColors.fieldBorder, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onRememberChanged(!_rememberCredentials),
            child: const Text(
              'Recordar usuario y contraseña',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const Tooltip(
          message:
              'La contraseña se guarda en este dispositivo. Evita usarlo en equipos compartidos.',
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final success = await _controller.login(email, password);

    if (success) {
      if (_rememberCredentials) {
        await CredentialStorage.save(email: email, password: password);
      } else {
        await CredentialStorage.clear();
      }
    }

    if (!mounted) return;
    if (success) {
      final user = _controller.currentUser;
      if (user != null) {
        final targetView = user.isAdmin ? AdminPanelView(user: user) : HomeView(user: user);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => targetView),
          (_) => false,
        );
      }
    } else {
      final msg = _controller.errorMessage ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _goToRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hPad = Responsive.horizontalPadding(context);
    final topPad = Responsive.topPadding(context);
    final logoH = Responsive.logoHeight(context);
    final gap = Responsive.fieldSpacing(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: hPad,
                right: hPad,
                bottom: bottomInset + 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    minHeight: constraints.maxHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: topPad),
                          SizedBox(
                            width: double.infinity,
                            child: AppLogo(height: logoH),
                          ),
                          SizedBox(height: Responsive.sectionSpacing(context, 18)),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Bienvenido',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.welcome,
                            ),
                          ),
                          SizedBox(height: Responsive.sectionSpacing(context, 14)),
                          const CustomDivider(),
                          SizedBox(height: Responsive.sectionSpacing(context, 20)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AuthTabSelector(
                              selected: AuthTab.login,
                              onLoginTap: () {},
                              onRegisterTap: _goToRegister,
                            ),
                          ),
                          SizedBox(height: Responsive.sectionSpacing(context, 22)),
                          CustomTextField(
                            label: 'Correo Electrónico',
                            controller: _emailController,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHint: AutofillHints.email,
                            focusNode: _emailFocus,
                            nextFocus: _passwordFocus,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: gap),
                          PasswordTextField(
                            controller: _passwordController,
                            validator: Validators.password,
                            focusNode: _passwordFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          const SizedBox(height: 10),
                          _buildRememberMe(),
                          SizedBox(height: Responsive.sectionSpacing(context, 18)),
                          PrimaryButton(
                            label: 'Ingresar',
                            isLoading: _controller.isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 14),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Función de recuperar contraseña próximamente',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Olvidaste tu contraseña?',
                                style: AppTextStyles.link,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(height: bottomInset > 0 ? 12 : 0),
                        ],
                      ),
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
