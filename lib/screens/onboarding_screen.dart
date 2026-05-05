// lib/screens/onboarding_screen.dart
// Onboarding modernizado con animaciones y contenido actualizado

import 'package:flutter/material.dart';
import 'package:structurescan_app/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> onboardingPages = [
    OnboardingData(
      imagePath: "assets/images/Análisis Estructural Inteligente.jpg",
      title: "Análisis Estructural Inteligente",
      description:
          "Evalúa el riesgo sísmico de tu edificación mediante un cuestionario guiado y tecnología de IA para detectar daños estructurales.",
    ),
    OnboardingData(
      imagePath: "assets/images/Detección con IA Avanzada.jpg",
      title: "Detección con IA Avanzada",
      description:
          "Nuestra inteligencia artificial identifica y analiza grietas, humedad y deformaciones con precisión profesional.",
    ),
    OnboardingData(
      imagePath: "assets/images/Conexión con Expertos.jpg",
      title: "Conexión con Expertos",
      description:
          "Conecta con ingenieros civiles certificados que revisarán tu caso y generarán informes técnicos detallados.",
    ),
    OnboardingData(
      imagePath: "assets/images/Decisiones Informadas.jpg",
      title: "Decisiones Informadas",
      description:
          "Recibe diagnósticos profesionales, recomendaciones de seguridad y prioriza acciones para proteger tu inversión.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kAzulPrincipalOscuro.withOpacity(0.05),
              kBlanco,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior con skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'StructureScan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kAzulPrincipalOscuro,
                      ),
                    ),
                    if (_currentPage != onboardingPages.length - 1)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        },
                        child: const Text(
                          'Saltar',
                          style: TextStyle(
                            color: kGrisMedio,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // PageView con contenido
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingPages.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      data: onboardingPages[index],
                      currentPage: index,
                      totalPages: onboardingPages.length,
                    );
                  },
                ),
              ),

              // Indicadores de página
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingPages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 8,
                      width: _currentPage == index ? 32 : 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? kAzulPrincipalOscuro
                            : kGrisMedio.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              // Botón de acción
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < onboardingPages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAzulPrincipalOscuro,
                      foregroundColor: kBlanco,
                      elevation: 5,
                      shadowColor: kAzulPrincipalOscuro.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == onboardingPages.length - 1
                          ? 'Comenzar'
                          : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String imagePath;
  final String title;
  final String description;

  OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingPage extends StatefulWidget {
  final OnboardingData data;
  final int currentPage;
  final int totalPages;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.35; // 35% de la altura de la pantalla

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Imagen animada
          ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kAzulPrincipalOscuro.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.data.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              size: 50, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.05), // Espaciado dinámico

          // Título animado
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26, // Ligeramente más pequeño para evitar overflow
                  fontWeight: FontWeight.bold,
                  color: kAzulPrincipalOscuro,
                  height: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.03), // Espaciado dinámico

          // Descripción animada
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.data.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15, // Ligeramente más pequeño
                  color: kGrisOscuro,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}