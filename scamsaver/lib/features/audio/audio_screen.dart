import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/widgets/risk_badge.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/services/claude_service.dart';

final audioProvider = StateNotifierProvider.autoDispose<AudioNotifier, AudioState>(
  (ref) => AudioNotifier(),
);

class AudioState {
  final bool isLoading;
  final bool isRecording;
  final File? audioFile;
  final String? transcript;
  final AnalysisResult? result;
  final String? error;

  const AudioState({
    this.isLoading = false,
    this.isRecording = false,
    this.audioFile,
    this.transcript,
    this.result,
    this.error,
  });
}

class AudioNotifier extends StateNotifier<AudioState> {
  AudioNotifier() : super(const AudioState());

  final _recorder = FlutterSoundRecorder();
  final _whisperService = WhisperService();
  final _claudeService = ClaudeService();
  String? _recordingPath;

  Future<void> init() async {
    await _recorder.openRecorder();
  }

  Future<void> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    await _processAudio(file);
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = const AudioState(error: 'Microphone permission denied');
      return;
    }

    await init();

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/recording.m4a';

    await _recorder.startRecorder(
      toFile: _recordingPath,
      codec: Codec.aacMP4,
    );

    state = const AudioState(isRecording: true);
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();

    if (_recordingPath == null) return;

    final file = File(_recordingPath!);
    await _processAudio(file);
  }

  Future<void> _processAudio(File file) async {
    state = AudioState(audioFile: file, isLoading: true);

    try {
      // Transcribe with Whisper
      final transcript = await _whisperService.transcribeAudio(file);

      // Analyze with Claude
      final result = await _claudeService.analyzeText(transcript);

      state = AudioState(
        audioFile: file,
        transcript: transcript,
        result: result,
      );
    } catch (e) {
      state = AudioState(
        audioFile: file,
        error: e.toString(),
      );
    }
  }

  void clear() {
    _recorder.closeRecorder();
    state = const AudioState();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }
}

class AudioScreen extends ConsumerStatefulWidget {
  const AudioScreen({super.key});

  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(audioProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Check'),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Transcribing & Analyzing...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload an audio file or record directly. We\'ll transcribe it and analyze for scam indicators.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                if (state.audioFile == null) ...[
                  _buildRecordingControls(context, ref, state),
                ] else ...[
                  if (state.transcript != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transcript:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.transcript!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.result != null) _buildResultCard(state.result!),
                  if (state.error != null) _buildErrorCard(state.error!),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(audioProvider.notifier).clear(),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showPickerDialog(context, ref),
                          child: const Text('New Audio'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context, WidgetRef ref, AudioState state) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: state.isRecording
                ? Colors.red.withValues(alpha: 0.2)
                : const Color(0xFF6366F1).withValues(alpha: 0.2),
            border: Border.all(
              color: state.isRecording ? Colors.red : const Color(0xFF6366F1),
              width: 3,
            ),
          ),
          child: IconButton(
            onPressed: state.isRecording
                ? () => ref.read(audioProvider.notifier).stopRecording()
                : () => ref.read(audioProvider.notifier).startRecording(),
            icon: Icon(
              state.isRecording ? Icons.stop : Icons.mic,
              size: 48,
              color: state.isRecording ? Colors.red : const Color(0xFF6366F1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.isRecording ? 'Recording... Tap to stop' : 'Tap to record',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showPickerDialog(context, ref),
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Audio File'),
        ),
      ],
    );
  }

  void _showPickerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Audio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: const Text('Pick from Files'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(audioProvider.notifier).pickAudioFile();
                },
              ),
            ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiskBadge(riskLevel: result.riskLevel),
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
              ),
            ),
            const SizedBox(height: 8),
            ...result.redFlags.map(
              (flag) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning, size: 16, color: Colors.orange),
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

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Error: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
