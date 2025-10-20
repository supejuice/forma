import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';

@RoutePage()
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top text
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: Text(
                'Welcome to Forma!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          // Center image with fade-in and circle crop
          Center(
            child: ClipOval(
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/placeholder.png', // You should add a placeholder image in assets
                image: 'https://images.pexels.com/photos/5965658/pexels-photo-5965658.jpeg',
                width: 360,
                height: 360,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 800),
              ),
            ),
          ),
          // Bottom button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}