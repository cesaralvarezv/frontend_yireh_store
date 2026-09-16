import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/auth_controller.dart';
import '../../repositories/auth_repository.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive.dart';
import '../../utils/validators.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_tab_selector.dart';
import '../../widgets/custom_divider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  late final AuthController _controller;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AuthController(
      repository: AuthRepositoryImpl(service: ApiAuthService()),
    );
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.register(
      _nameController.text.trim(),
      _phoneController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cuenta creada para ${_nameController.text.trim()}!'),
        ),
      );
      // Navega a login después de registro exitoso
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginView()),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Error al registrarse'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
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
                          // Logo escalable — nunca desborda en móviles 320px o 480h
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
                          // Tabs con Flexible para pantallas muy angostas
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AuthTabSelector(
                              selected: AuthTab.register,
                              onLoginTap: _goToLogin,
                              onRegisterTap: () {},
                            ),
                          ),
                          SizedBox(height: Responsive.sectionSpacing(context, 22)),
                          CustomTextField(
                            label: 'Nombre Completo',
                            controller: _nameController,
                            validator: Validators.name,
                            keyboardType: TextInputType.name,
                            autofillHint: AutofillHints.name,
                            focusNode: _nameFocus,
                            nextFocus: _phoneFocus,
                          ),
                          SizedBox(height: gap),
                          CustomTextField(
                            label: 'No. Celular',
                            controller: _phoneController,
                            validator: Validators.phone,
                            keyboardType: TextInputType.phone,
                            autofillHint: AutofillHints.telephoneNumber,
                            focusNode: _phoneFocus,
                            nextFocus: _emailFocus,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\s-]'),
                              ),
                            ],
                          ),
                          SizedBox(height: gap),
                          CustomTextField(
                            label: 'Correo Electrónico',
                            controller: _emailController,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHint: AutofillHints.email,
                            focusNode: _emailFocus,
                            nextFocus: _passwordFocus,
                          ),
                          SizedBox(height: gap),
                          PasswordTextField(
                            controller: _passwordController,
                            validator: Validators.password,
                            focusNode: _passwordFocus,
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          SizedBox(height: Responsive.sectionSpacing(context, 24)),
                          PrimaryButton(
                            label: 'Registrarse',
                            isLoading: _controller.isLoading,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 12),
                          // Espacio extra para que el último campo no quede bajo el teclado
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
