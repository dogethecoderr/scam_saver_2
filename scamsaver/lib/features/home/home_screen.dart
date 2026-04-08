import 'package:flutter/material.dart';
import '../../shared/widgets/scam_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Logo and tagline
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ScamSaver',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-powered scam detection in your pocket',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Privacy note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      color: Color(0xFF22C55E),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your messages are never stored or shared.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose a feature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Feature cards
              const ScamCard(
                title: 'Analyze Text',
                description: 'Paste suspicious messages for instant AI analysis',
                icon: Icons.text_fields,
                route: '/analyze',
                color: Color(0xFF6366F1),
              ),
              const ScamCard(
                title: 'Screenshot Scan',
                description: 'Upload screenshots to extract and analyze text',
                icon: Icons.image,
                route: '/screenshot',
                color: Color(0xFF8B5CF6),
              ),
              const ScamCard(
                title: 'Audio Check',
                description: 'Upload or record audio to transcribe and analyze',
                icon: Icons.mic,
                route: '/audio',
                color: Color(0xFFEC4899),
              ),
              const ScamCard(
                title: 'Live Monitor',
                description: 'Real-time call monitoring with rolling analysis',
                icon: Icons.live_tv,
                route: '/live',
                color: Color(0xFFF59E0B),
              ),
              const ScamCard(
                title: 'Learn',
                description: 'Scam awareness flashcards and tips',
                icon: Icons.school,
                route: '/learn',
                color: Color(0xFF22C55E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
