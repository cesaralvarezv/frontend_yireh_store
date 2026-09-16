import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_logo.dart';
import '../views/home/home_view.dart';
import '../views/home/admin_panel_view.dart';
import 'auth/login_view.dart';

/// Splash / Loading screen — intenta restaurar sesión, si no va a Login.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();

    _initSession();
  }

  Future<void> _initSession() async {
    bool restored = false;
    AuthController? controller;
    try {
      controller = AuthController(
        repository: AuthRepositoryImpl(service: ApiAuthService()),
      );
      restored = await controller.restoreSession();
    } catch (_) {
      restored = false;
    }

    if (!mounted) return;

    // Espera minimo 2s para que se vea el splash
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    if (restored && controller?.currentUser != null) {
      final user = controller!.currentUser!;
      final targetView = user.isAdmin ? AdminPanelView(user: user) : HomeView(user: user);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => targetView),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, a, _) => const LoginView(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoH = Responsive.logoHeight(context) + 30;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: SizedBox(
                        width: double.infinity,
                        child: AppLogo(height: logoH),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
