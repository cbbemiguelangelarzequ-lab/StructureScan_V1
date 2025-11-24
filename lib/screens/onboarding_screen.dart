// lib/screens/onboarding_screen.dart
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

  List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/onboarding_1.png",
      "title": "Inspecciones Estructurales Simples",
      "description": "Evalúa la resistencia sísmica de tus edificaciones con facilidad usando tu smartphone.",
    },
    {
      "image": "assets/images/onboarding_2.png",
      "title": "Detección Inteligente de Grietas",
      "description": "Nuestra IA avanzada identifica y analiza grietas para un diagnóstico preciso.",
    },
    {
      "image": "assets/images/onboarding_3.png",
      "title": "Informes Detallados y Recomendaciones",
      "description": "Genera reportes profesionales con un solo toque y recibe consejos de mejora.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrisClaro,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                imagePath: onboardingData[index]["image"]!,
                title: onboardingData[index]["title"]!,
                description: onboardingData[index]["description"]!,
              );
            },
          ),
          Positioned(
            bottom: 120.0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => buildDot(index, context),
              ),
            ),
          ),
          Positioned(
            bottom: 40.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentPage != onboardingData.length - 1
                    ? TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/auth');
                        },
                        child: Text(
                          'Saltar',
                          style: kLinkTextStyle.copyWith(color: kGrisOscuro),
                        ),
                      )
                    : const SizedBox.shrink(),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < onboardingData.length - 1) {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn);
                    } else {
                      Navigator.of(context).pushReplacementNamed('/auth');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzulPrincipalOscuro,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentPage == onboardingData.length - 1 ? 'Empezar' : 'Siguiente',
                    style: kButtonTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container buildDot(int index, BuildContext context) {
    return Container(
      height: 10,
      width: _currentPage == index ? 24 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        color: _currentPage == index ? kAzulSecundarioClaro : kGrisMedio,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: kTituloPantallaStyle.copyWith(color: kAzulPrincipalOscuro),
          ),
          const SizedBox(height: 15),
          Text(
            description,
            textAlign: TextAlign.center,
            style: kBodyTextStyle.copyWith(color: kGrisOscuro),
          ),
        ],
      ),
    );
  }
}