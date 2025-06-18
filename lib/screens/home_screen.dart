import 'package:flutter/material.dart';
import 'package:gymsgg_app/screens/login_screen.dart';
import 'package:gymsgg_app/screens/sign_up_screen.dart';
import 'package:gymsgg_app/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.foundColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveContent(constraints);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(BoxConstraints constraints) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // Detectar tipo de dispositivo
    final isWear = size.width < 300 && size.height < 400;
    final isTablet = size.width > 600;
    final isLandscape = orientation == Orientation.landscape;

    if (isWear) {
      return _buildWearContent(size);
    } else if (isTablet && isLandscape) {
      return _buildTabletLandscapeContent(size);
    } else {
      return _buildMainContent(size, isTablet);
    }
  }

  // Contenido para smartwatch/dispositivos muy pequeños
  Widget _buildWearContent(Size size) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo más pequeño para wear
            Container(
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cardColor.withOpacity(0.3),
                border: Border.all(
                  color: AppTheme.accentColor.withOpacity(0.3),
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.08),

            // Botones compactos para wear
            _buildWearButton(
              icon: Icons.person_outline,
              text: 'Login',
              size: size,
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  ),
            ),
            SizedBox(height: size.height * 0.04),
            _buildWearButton(
              icon: Icons.person_add_outlined,
              text: 'Registro',
              size: size,
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  ),
              isOutlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWearButton({
    required IconData icon,
    required String text,
    required Size size,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Container(
      width: size.width * 0.8,
      height: size.height * 0.12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.height * 0.06),
        gradient:
            isOutlined
                ? null
                : const LinearGradient(
                  colors: [AppTheme.accentColor, Color(0xFFFFA500)],
                ),
        border:
            isOutlined
                ? Border.all(color: AppTheme.accentColor, width: 1)
                : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.height * 0.06),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? AppTheme.accentColor : AppTheme.primaryColor,
              size: size.width * 0.08,
            ),
            SizedBox(width: size.width * 0.02),
            Text(
              text,
              style: TextStyle(
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.w600,
                color:
                    isOutlined ? AppTheme.accentColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Contenido para tablet en landscape
  Widget _buildTabletLandscapeContent(Size size) {
    return SafeArea(
      child: Row(
        children: [
          // Panel izquierdo con logo
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBackButton(),
                  const Spacer(),
                  _buildLogo(size, true), // isTablet = true
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Panel derecho con botones
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(size.width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Bienvenido a GymsGG',
                    style: TextStyle(
                      fontSize: size.width * 0.025,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: size.height * 0.1),
                  _buildActionButtons(size, true), // isTablet = true
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contenido principal (móvil y tablet portrait)
  Widget _buildMainContent(Size size, bool isTablet) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(_getResponsivePadding(size)),
        child: Column(
          children: [
            _buildBackButton(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(size, isTablet),
                      SizedBox(height: _getResponsiveSpacing(size, 80)),
                      _buildActionButtons(size, isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppTheme.iconColor,
          size: _getResponsiveIconSize(MediaQuery.of(context).size, 24),
        ),
      ),
    );
  }

  Widget _buildLogo(Size size, bool isTablet) {
    final logoSize = _getResponsiveLogoSize(size);
    final padding = logoSize * 0.167; // Proporción mantenida

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardColor.withOpacity(0.3),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.2),
            blurRadius: isTablet ? 30 : 20,
            spreadRadius: isTablet ? 8 : 5,
          ),
        ],
      ),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Size size, bool isTablet) {
    return Column(
      children: [
        _buildCustomButton(
          icon: Icons.person_outline,
          text: 'Iniciar sesión',
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              ),
          size: size,
          isTablet: isTablet,
        ),
        SizedBox(height: _getResponsiveSpacing(size, 20)),
        _buildCustomButton(
          icon: Icons.person_add_outlined,
          text: 'Crear cuenta',
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              ),
          size: size,
          isTablet: isTablet,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _buildCustomButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required Size size,
    required bool isTablet,
    bool isOutlined = false,
  }) {
    final buttonHeight = _getResponsiveButtonHeight(size);
    final fontSize = _getResponsiveFontSize(size, 18);
    final iconSize = _getResponsiveIconSize(size, 24);

    return Container(
      width: isTablet ? size.width * 0.4 : double.infinity,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(buttonHeight / 2),
        gradient:
            isOutlined
                ? null
                : const LinearGradient(
                  colors: [AppTheme.accentColor, Color(0xFFFFA500)],
                ),
        border:
            isOutlined
                ? Border.all(color: AppTheme.accentColor, width: 2)
                : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isOutlined ? AppTheme.accentColor : AppTheme.primaryColor,
              size: iconSize,
            ),
            SizedBox(width: _getResponsiveSpacing(size, 12)),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color:
                    isOutlined ? AppTheme.accentColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funciones helper para responsividad
  double _getResponsivePadding(Size size) {
    if (size.width > 900) return 60.0; // Desktop/Tablet grande
    if (size.width > 600) return 40.0; // Tablet
    if (size.width > 400) return 32.0; // Móvil grande
    return 20.0; // Móvil pequeño
  }

  double _getResponsiveSpacing(Size size, double baseSpacing) {
    if (size.width > 900) return baseSpacing * 1.5;
    if (size.width > 600) return baseSpacing * 1.2;
    if (size.width > 400) return baseSpacing;
    return baseSpacing * 0.8;
  }

  double _getResponsiveLogoSize(Size size) {
    if (size.width > 900) return 160.0;
    if (size.width > 600) return 140.0;
    if (size.width > 400) return 120.0;
    return 100.0;
  }

  double _getResponsiveButtonHeight(Size size) {
    if (size.width > 900) return 70.0;
    if (size.width > 600) return 65.0;
    if (size.width > 400) return 60.0;
    return 50.0;
  }

  double _getResponsiveFontSize(Size size, double baseFontSize) {
    if (size.width > 900) return baseFontSize * 1.3;
    if (size.width > 600) return baseFontSize * 1.1;
    if (size.width > 400) return baseFontSize;
    return baseFontSize * 0.9;
  }

  double _getResponsiveIconSize(Size size, double baseIconSize) {
    if (size.width > 900) return baseIconSize * 1.3;
    if (size.width > 600) return baseIconSize * 1.1;
    if (size.width > 400) return baseIconSize;
    return baseIconSize * 0.9;
  }
}
