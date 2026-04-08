import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../shared/widgets/risk_badge.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/services/claude_service.dart';

final screenshotProvider = StateNotifierProvider.autoDispose<ScreenshotNotifier, ScreenshotState>(
  (ref) => ScreenshotNotifier(),
);

class ScreenshotState {
  final bool isLoading;
  final File? image;
  final String? extractedText;
  final AnalysisResult? result;
  final String? error;

  const ScreenshotState({
    this.isLoading = false,
    this.image,
    this.extractedText,
    this.result,
    this.error,
  });
}

class ScreenshotNotifier extends StateNotifier<ScreenshotState> {
  ScreenshotNotifier() : super(const ScreenshotState());

  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer();
  final _claudeService = ClaudeService();

  Future<void> pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    state = ScreenshotState(image: File(picked.path), isLoading: true);

    try {
      // OCR the image
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text;

      if (text.trim().isEmpty) {
        state = ScreenshotState(
          image: File(picked.path),
          error: 'No text found in image',
        );
        return;
      }

      // Analyze with Claude
      final result = await _claudeService.analyzeText(text);
      state = ScreenshotState(
        image: File(picked.path),
        extractedText: text,
        result: result,
      );
    } catch (e) {
      state = ScreenshotState(
        image: File(picked.path),
        error: e.toString(),
      );
    }
  }

  void clear() => state = const ScreenshotState();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}

class ScreenshotScreen extends ConsumerWidget {
  const ScreenshotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshot Scan'),
      ),
      body: LoadingOverlay(
        isLoading: state.isLoading,
        message: 'Analyzing...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload a screenshot of a suspicious message. We\'ll extract the text and analyze it for scam indicators.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                if (state.image == null) ...[
                  _buildImagePicker(context, ref),
                ] else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      state.image!,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.extractedText != null) ...[
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
                            'Extracted Text:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.extractedText!,
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
                          onPressed: () => ref.read(screenshotProvider.notifier).clear(),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showPickerDialog(context, ref),
                          child: const Text('New Image'),
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

  Widget _buildImagePicker(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showPickerDialog(context, ref),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to upload screenshot',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gallery or Camera',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
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
                'Select Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(screenshotProvider.notifier).pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(screenshotProvider.notifier).pickImage(ImageSource.camera);
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
