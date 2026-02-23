// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _usernameFocused = false;
  bool _passwordFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() {
      setState(() => _usernameFocused = _usernameFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      CommonToast.showError(context, 'Please enter your username and password.');
      return;
    }

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      // TODO: API call — POST /api/v1/auth/admin/login/
      final result = await AuthService.adminLogin(username, password);

      await StorageService.saveAuthData(
        accessToken:  result.accessToken,
        refreshToken: result.refreshToken,
        username:     result.username,
        name:         result.name,
        role:         result.role,
      );

      if (mounted) context.go('/game-selection');
    } on AuthException catch (e) {
      if (mounted) CommonToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.loginBgTop,
              AppColors.loginBgMid,
              AppColors.loginBgBottom,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            _buildDecorativeCircles(),
            // Main content
            SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          _buildLogo(),
                          const SizedBox(height: 24),
                          _buildAppTitle(),
                          const SizedBox(height: 48),
                          _buildUsernameField(),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                          const SizedBox(height: 28),
                          _buildLoginButton(),
                          const SizedBox(height: 20),
                          _buildForgotPassword(),
                          const Spacer(),
                          _buildFooter(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // Top-right large circle
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              ),
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
        // Bottom-left large circle
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
              color: Colors.white.withOpacity(0.03),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer translucent ring
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        // Inner white glowing circle
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.18),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        // Gradient rounded square with icon
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E9AEC), Color(0xFF1565A0)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B7ACC).withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.layers_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildAppTitle() {
    return Column(
      children: [
        const Text('FLOW ADMIN', style: AppTextStyles.loginAppName),
        const SizedBox(height: 6),
        const Text('MANAGEMENT CONSOLE', style: AppTextStyles.loginTagline),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required IconData prefixIcon,
    required String placeholder,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isFocused ? AppColors.inputBgFocused : AppColors.inputBg,
            border: Border.all(
              color: isFocused
                  ? Colors.white.withOpacity(0.6)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onEditingComplete: onEditingComplete,
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  prefixIcon,
                  color: isFocused
                      ? AppColors.primaryBlue
                      : AppColors.inputPlaceholder,
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: suffixIcon,
              hintText: placeholder,
              hintStyle: AppTextStyles.inputPlaceholder,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return _buildInputField(
      label: 'USER NAME',
      controller: _usernameController,
      focusNode: _usernameFocus,
      isFocused: _usernameFocused,
      prefixIcon: Icons.person_outline_rounded,
      placeholder: 'Enter your username',
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return _buildInputField(
      label: 'PASSWORD',
      controller: _passwordController,
      focusNode: _passwordFocus,
      isFocused: _passwordFocused,
      prefixIcon: Icons.lock_outline_rounded,
      placeholder: 'Enter your password',
      obscureText: !_passwordVisible,
      textInputAction: TextInputAction.done,
      onEditingComplete: _onLogin,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          icon: Icon(
            _passwordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.inputPlaceholder,
            size: 20,
          ),
          onPressed: () {
            setState(() => _passwordVisible = !_passwordVisible);
          },
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isLoading ? null : _onLogin,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _isLoading
                  ? [AppColors.loginButtonStart.withOpacity(0.6), AppColors.loginButtonEnd.withOpacity(0.6)]
                  : [AppColors.loginButtonStart, AppColors.loginButtonEnd],
            ),
            boxShadow: _isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Container(
            width: double.infinity,
            height: 52,
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('LOGIN', style: AppTextStyles.loginButton),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        // TODO: Navigate to forgot password
      },
      child: const Text(
        'Forgot your password?',
        style: AppTextStyles.forgotPassword,
      ),
    );
  }

  Widget _buildFooter() {
    return const Text('Flow Admin v1.0', style: AppTextStyles.loginFooter);
  }
}
