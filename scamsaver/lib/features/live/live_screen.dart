import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/widgets/risk_badge.dart';
import '../../shared/services/claude_service.dart';

final liveProvider = StateNotifierProvider.autoDispose<LiveNotifier, LiveState>(
  (ref) => LiveNotifier(),
);

class LiveState {
  final bool isMonitoring;
  final String status;
  final List<LiveResult> results;
  final String? currentTranscript;

  const LiveState({
    this.isMonitoring = false,
    this.status = 'Tap to start monitoring',
    this.results = const [],
    this.currentTranscript,
  });
}

class LiveResult {
  final DateTime timestamp;
  final AnalysisResult analysis;
  final String transcript;

  LiveResult({
    required this.timestamp,
    required this.analysis,
    required this.transcript,
  });
}

class LiveNotifier extends StateNotifier<LiveState> {
  LiveNotifier() : super(const LiveState());

  final _recorder = FlutterSoundRecorder();
  final _whisperService = WhisperService();
  final _claudeService = ClaudeService();
  Timer? _chunkTimer;
  String? _currentRecordingPath;
  int _chunkIndex = 0;

  Future<void> startMonitoring() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = const LiveState(status: 'Microphone permission denied');
      return;
    }

    await _recorder.openRecorder();

    final dir = await getTemporaryDirectory();
    _currentRecordingPath = '${dir.path}/live_chunk.m4a';

    state = const LiveState(isMonitoring: true, status: 'Monitoring...');

    // Start continuous recording
    await _recorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacMP4,
    );

    // Process chunks every 5 seconds
    _chunkTimer = Timer.periodic(const Duration(seconds: 5), (_) => _processChunk());
  }

  Future<void> _processChunk() async {
    if (_currentRecordingPath == null) return;

    try {
      // Stop and restart to get a complete chunk
      await _recorder.stopRecorder();

      final file = File(_currentRecordingPath!);
      if (await file.exists() && await file.length() > 1000) {
        // Transcribe chunk
        final transcript = await _whisperService.transcribeAudio(file);

        if (transcript.trim().isNotEmpty) {
          // Analyze
          final analysis = await _claudeService.analyzeText(transcript);

          // Add result
          final newResult = LiveResult(
            timestamp: DateTime.now(),
            analysis: analysis,
            transcript: transcript,
          );

          state = LiveState(
            isMonitoring: true,
            status: 'Monitoring...',
            results: [newResult, ...state.results].take(10).toList(),
            currentTranscript: transcript,
          );
        }
      }

      // Restart recording for next chunk
      _chunkIndex++;
      final newPath = '${(await getTemporaryDirectory()).path}/live_chunk_$_chunkIndex.m4a';
      _currentRecordingPath = newPath;

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
      );
    } catch (e) {
      // Continue monitoring even if one chunk fails
    }
  }

  Future<void> stopMonitoring() async {
    _chunkTimer?.cancel();
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    state = const LiveState(status: 'Monitoring stopped');
  }

  void clear() => state = const LiveState();

  @override
  void dispose() {
    _chunkTimer?.cancel();
    _recorder.closeRecorder();
    super.dispose();
  }
}

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Monitor'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Real-time call monitoring. Audio is processed in 5-second chunks and analyzed for scam indicators.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              // Monitor button
              Center(
                child: GestureDetector(
                  onTap: state.isMonitoring
                      ? () => ref.read(liveProvider.notifier).stopMonitoring()
                      : () => ref.read(liveProvider.notifier).startMonitoring(),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isMonitoring
                          ? Colors.red.withValues(alpha: 0.2)
                          : const Color(0xFF6366F1).withValues(alpha: 0.2),
                      border: Border.all(
                        color: state.isMonitoring ? Colors.red : const Color(0xFF6366F1),
                        width: 4,
                      ),
                      boxShadow: state.isMonitoring
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          state.isMonitoring ? Icons.stop : Icons.mic,
                          size: 48,
                          color: state.isMonitoring ? Colors.red : const Color(0xFF6366F1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isMonitoring ? 'STOP' : 'START',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: state.isMonitoring ? Colors.red : const Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: state.isMonitoring
                      ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                      : const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: state.isMonitoring
                        ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.isMonitoring) ...[
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      state.status,
                      style: TextStyle(
                        color: state.isMonitoring
                            ? const Color(0xFF22C55E)
                            : Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.currentTranscript != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.currentTranscript!,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Results list
              if (state.results.isNotEmpty) ...[
                Row(
                  children: [
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ref.read(liveProvider.notifier).clear(),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final result = state.results[index];
                      return _buildResultItem(result);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(LiveResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRiskColor(result.analysis.riskLevel).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          RiskBadge(riskLevel: result.analysis.riskLevel, showLabel: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.transcript,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.timestamp.hour}:${result.timestamp.minute.toString().padLeft(2, '0')}:${result.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
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
