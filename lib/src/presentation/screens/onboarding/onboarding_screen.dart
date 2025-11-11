import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iot/src/presentation/screens/login_screen.dart';
import 'package:iot/src/core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _checkingStatus = true;
  Timer? _autoPageTimer;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  @override
  void dispose() {
    _autoPageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPageTimer() {
    _autoPageTimer?.cancel();
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        // Stop auto-advance when reaching the last page; do NOT loop back
        timer.cancel();
      }
    });
  }

  void _stopAutoPageTimer() {
    _autoPageTimer?.cancel();
  }

  /// Verifica si el usuario ya completó el onboarding
  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;

    if (onboardingCompleted && mounted) {
      _navigateToLogin();
    } else {
      setState(() => _checkingStatus = false);
      _startAutoPageTimer();
    }
  }

  /// Guarda el estado y redirige al login
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingCompleted', true);
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'icon': Icons.eco,
      'title': 'Monitoreo\nInteligente',
      'subtitle': 'Tu cultivo bajo control',
      'description': 'Sistemas IoT que miden clima y condiciones ambientales 24/7',
      'buttonText': 'Siguiente',
      'image': 'lib/src/assets/iot-agricultur.png',
      'features': ['Temperatura', 'Humedad', 'Radiación Solar'],
      'color': AppTheme.secondary,
    },
    {
      'icon': Icons.sensors,
      'title': 'Tecnología\nAvanzada',
      'subtitle': 'Sensores de precisión',
      'description': 'Estaciones ESP32 con transmisión en tiempo real',
      'buttonText': 'Continuar',
      'image': 'lib/src/assets/esp32.png',
      'features': ['Tiempo Real', 'Precisión', 'Bajo Consumo'],
      'color': AppTheme.info,
    },
    {
      'icon': Icons.analytics,
      'title': 'Análisis\nProfundo',
      'subtitle': 'Decisiones basadas en datos',
      'description': 'Gráficas interactivas y comparaciones detalladas',
      'buttonText': 'Empezar',
      'image': 'lib/src/assets/dashboard-analyti.png',
      'features': ['Gráficas', 'Comparaciones', 'Reportes'],
      'color': AppTheme.accent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras se verifica SharedPreferences
    if (_checkingStatus) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              // If we reached the last page, stop auto-advance so it doesn't loop.
              if (page == _onboardingData.length - 1) {
                _stopAutoPageTimer();
              } else {
                // Restart timer when user manually changes page (unless last page)
                _startAutoPageTimer();
              }
            },
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return OnboardingPage(
                icon: data['icon'],
                title: data['title']!,
                subtitle: data['subtitle']!,
                description: data['description']!,
                buttonText: data['buttonText']!,
                image: data['image']!,
                features: List<String>.from(data['features']),
                color: data['color'],
                currentPage: _currentPage,
                totalPages: _onboardingData.length,
                onNext: () {
                  _stopAutoPageTimer(); // Stop auto-advance when user interacts
                  if (_currentPage < _onboardingData.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _completeOnboarding();
                  }
                },
                onSkip: _completeOnboarding,
                onPageTap: (page) {
                  _stopAutoPageTimer(); // Stop auto-advance when user interacts
                  _pageController.animateToPage(
                    page,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final String image;
  final List<String> features;
  final Color color;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Function(int) onPageTap;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.image,
    required this.features,
    required this.color,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    required this.onPageTap,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Start animations with staggered delays
    _startAnimations();
  }
  
  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 768;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: isLargeScreen
                  ? _buildLargeScreenLayout(context)
                  : _buildSmallScreenLayout(context),
            ),
            SafeArea(
              top: false,
              child: _buildBottomSection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Content
        Expanded(
          child: _buildContentSection(context),
        ),
        const SizedBox(width: 32),
        // Right side - Image
        Expanded(
          child: _buildImageSection(context),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom - 
                    140, // Space for bottom section
        ),
        child: Column(
          children: [
            // Image at top for mobile
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: _buildImageSection(context),
            ),
            const SizedBox(height: 24),
            // Content below for mobile
            _buildContentSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon with colored background
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(
                widget.icon,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Main title with better typography
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: widget.color.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 20),
          
          // Description with better spacing
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 24),
          
          // Feature chips
          Flexible(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.features.map((feature) {
                return AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - _fadeController.value) * 20),
                      child: Opacity(
                        opacity: _fadeController.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Main image - fill available space for better presentation on varied screen sizes
              SizedBox.expand(
                child: Image.asset(
                  widget.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withValues(alpha: 0.3),
                            widget.color.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    );
                  },
                ),
              ),
              // Border highlight
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      )),
      child: Column(
        children: [
          // Skip button at top (only show if not last page)
          if (widget.currentPage < widget.totalPages - 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          
          // Page indicators and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page indicators
              Row(
                children: List.generate(
                  widget.totalPages,
                  (index) => GestureDetector(
                    onTap: () => widget.onPageTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 10,
                      width: index == widget.currentPage ? 40 : 10,
                      decoration: BoxDecoration(
                        gradient: index == widget.currentPage
                            ? LinearGradient(
                                colors: [Colors.white, widget.color],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: index == widget.currentPage
                            ? null
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: index == widget.currentPage
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Next button with gradient and animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.primaryBlue,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
