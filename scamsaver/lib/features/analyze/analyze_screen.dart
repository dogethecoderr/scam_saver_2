import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/risk_badge.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/services/claude_service.dart';

final analyzeProvider = StateNotifierProvider.autoDispose<AnalyzeNotifier, AnalyzeState>(
  (ref) => AnalyzeNotifier(),
);

class AnalyzeState {
  final bool isLoading;
  final AnalysisResult? result;
  final String? error;

  const AnalyzeState({
    this.isLoading = false,
    this.result,
    this.error,
  });
}

class AnalyzeNotifier extends StateNotifier<AnalyzeState> {
  AnalyzeNotifier() : super(const AnalyzeState());

  final _claudeService = ClaudeService();

  Future<void> analyze(String text) async {
    if (text.trim().isEmpty) return;

    state = const AnalyzeState(isLoading: true);

    try {
      final result = await _claudeService.analyzeText(text);
      state = AnalyzeState(result: result);
    } catch (e) {
      state = AnalyzeState(error: e.toString());
    }
  }

  void clear() => state = const AnalyzeState();
}

class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyzeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Text'),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Analyzing...',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paste a suspicious message below and our AI will analyze it for scam indicators.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  flex: state.result == null ? 2 : 1,
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: 'Paste message here...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
                if (state.result != null) ...[
                  const SizedBox(height: 20),
                  _buildResultCard(state.result!),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Error: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                          .read(analyzeProvider.notifier)
                          .analyze(_textController.text),
                  child: const Text('Analyze'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(AnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRiskColor(result.riskLevel).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiskBadge(riskLevel: result.riskLevel),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => ref.read(analyzeProvider.notifier).clear(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.explanation,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          if (result.redFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Red Flags:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...result.redFlags.map(
              (flag) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        flag,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF22C55E);
      case RiskLevel.medium:
        return const Color(0xFFF59E0B);
      case RiskLevel.high:
        return const Color(0xFFEF4444);
      case RiskLevel.critical:
        return const Color(0xFF991B1B);
      case RiskLevel.unknown:
        return Colors.grey;
    }
  }
}
