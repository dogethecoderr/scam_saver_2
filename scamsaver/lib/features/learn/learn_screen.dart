import 'package:flutter/material.dart';

class Flashcard {
  final String title;
  final String content;
  final List<String> tips;

  const Flashcard({
    required this.title,
    required this.content,
    required this.tips,
  });
}

final List<Flashcard> _flashcards = [
  const Flashcard(
    title: 'Urgency Tactics',
    content: 'Scammers create false urgency to pressure you into making quick decisions without thinking.',
    tips: [
      'Take your time - legitimate offers won\'t disappear',
      'Never make payments under pressure',
      'Verify through official channels',
    ],
  ),
  const Flashcard(
    title: 'Phishing Links',
    content: 'Fake links that look legitimate but steal your login credentials or personal information.',
    tips: [
      'Hover to check the actual URL',
      'Don\'t click links in unsolicited emails',
      'Type URLs directly when possible',
    ],
  ),
  const Flashcard(
    title: 'Prize Scams',
    content: 'You\'ve "won" something but need to pay fees or provide personal information first.',
    tips: [
      'You can\'t win a lottery you didn\'t enter',
      'Never pay to claim a prize',
      'Legitimate prizes don\'t require upfront fees',
    ],
  ),
  const Flashcard(
    title: 'Tech Support Scams',
    content: 'Fake tech support claiming your computer has a virus and offering to "fix" it for a fee.',
    tips: [
      'Microsoft/Apple never calls you unsolicited',
      'Don\'t give remote access to strangers',
      'Use official support channels only',
    ],
  ),
  const Flashcard(
    title: 'Romance Scams',
    content: 'Scammers build fake relationships online to eventually ask for money.',
    tips: [
      'Never send money to someone you haven\'t met',
      'Be wary of rapid declarations of love',
      'Search their photos - they may be stolen',
    ],
  ),
  const Flashcard(
    title: 'Cryptocurrency Scams',
    content: 'Fake investment opportunities promising guaranteed returns in crypto.',
    tips: [
      'Guaranteed returns are always fake',
      'Never share your private keys',
      'Research before investing',
    ],
  ),
];

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _currentIndex = 0;

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _flashcards.length;
    });
  }

  void _previousCard() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _flashcards.length) % _flashcards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _flashcards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Swipe through scam awareness flashcards to learn how to protect yourself.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Card counter
              Center(
                child: Text(
                  '${_currentIndex + 1} / ${_flashcards.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Flashcard
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity! > 0) {
                      _previousCard();
                    } else if (details.primaryVelocity! < 0) {
                      _nextCard();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.school,
                          size: 32,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.content,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.6,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'How to protect yourself:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...card.tips.map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _previousCard,
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    onPressed: _nextCard,
                    icon: const Icon(Icons.arrow_forward),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Swipe left or right to navigate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
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
