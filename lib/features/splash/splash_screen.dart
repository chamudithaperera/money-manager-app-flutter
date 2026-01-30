import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Splash screen with staged animations; calls [onComplete] when done.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _splashBackground = Color(0xFF0A0A0A);
  static const Color _splashBlue = Color(0xFF3B82F6);

  int _stage = 0;

  @override
  void initState() {
    super.initState();
    _runSequence();
  }

  void _runSequence() {
    Future.delayed(const Duration(milliseconds: 400), () => _setStage(1));
    Future.delayed(const Duration(milliseconds: 1000), () => _setStage(2));
    Future.delayed(const Duration(milliseconds: 1800), () => _setStage(3));
    Future.delayed(const Duration(milliseconds: 2800), () => _setStage(4));
    Future.delayed(const Duration(milliseconds: 4000), () => _setStage(5));
    Future.delayed(const Duration(milliseconds: 5000), widget.onComplete);
  }

  void _setStage(int value) {
    if (mounted) setState(() => _stage = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _stage >= 5 ? 0 : 1,
      child: ColoredBox(
        color: _splashBackground,
        child: Stack(
          fit: StackFit.expand,
          children: [_buildGlows(), _buildContent()],
        ),
      ),
    );
  }

  Widget _buildGlows() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -100,
          left: MediaQuery.sizeOf(context).width * 0.5 - 250,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1000),
            opacity: _stage >= 1 ? 1 : 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 1000),
              scale: _stage >= 1 ? 1 : 0.5,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: MediaQuery.sizeOf(context).width * 0.33 - 150,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 1000),
            opacity: _stage >= 2 ? 1 : 0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 1000),
              scale: _stage >= 2 ? 1 : 0.5,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _splashBlue.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: 24),
              _buildAppName(),
              const SizedBox(height: 32),
              _buildFeatureRow(),
              const SizedBox(height: 32),
              _buildTagline(),
              const SizedBox(height: 48),
              _buildLoadingDots(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final show = _stage >= 1;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: show ? 1 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 700),
        scale: show ? 1 : 0.75,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 700),
          offset: show ? Offset.zero : const Offset(0, 0.3),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF28C76F), Color(0xFF1E9B57)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: _splashBackground,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: _buildDecorativeDot(
                  color: const Color(0xFF34D399),
                  visible: _stage >= 2,
                  size: 16,
                ),
              ),
              Positioned(
                bottom: -4,
                left: -4,
                child: _buildDecorativeDot(
                  color: const Color(0xFF60A5FA),
                  visible: _stage >= 2,
                  size: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeDot({
    required Color color,
    required bool visible,
    required double size,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 500),
        scale: visible ? 1 : 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    final show = _stage >= 2;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: show ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: show ? Offset.zero : const Offset(0, 0.2),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.appTitle.copyWith(fontSize: 36),
            children: const [
              TextSpan(text: 'My Money '),
              TextSpan(
                text: 'Manager',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow() {
    final show = _stage >= 3;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: show ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: show ? Offset.zero : const Offset(0, 0.15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFeatureItem(
              icon: Icons.trending_up,
              label: 'Track',
              color: AppColors.primary,
              show: show,
            ),
            _buildArrow(show: show),
            _buildFeatureItem(
              icon: Icons.savings,
              label: 'Save',
              color: _splashBlue,
              show: show,
            ),
            _buildArrow(show: show),
            _buildFeatureItem(
              icon: Icons.account_balance_wallet,
              label: 'Grow',
              color: AppColors.primary,
              show: show,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool show,
  }) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 400),
      scale: show ? 1 : 0,
      curve: Curves.elasticOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow({required bool show}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: show ? 1 : 0,
        child: Icon(
          Icons.arrow_forward,
          size: 16,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    final show = _stage >= 4;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 700),
      opacity: show ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 700),
        offset: show ? Offset.zero : const Offset(0, 0.15),
        child: Text(
          'Your money, your future',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    final show = _stage >= 3;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: show ? 1 : 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _PulseDot(delay: i * 0.15)),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.delay});

  final double delay;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Transform.scale(
            scale: 0.7 + _animation.value * 0.6,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.3 + _animation.value * 0.7,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
