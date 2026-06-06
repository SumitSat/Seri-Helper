import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:seri_helper/models/models.dart';

/// TFLiteService handles on-device leaf disease classification.
/// It loads the quantized uint8 EfficientNetB0 model and produces
/// a rich [FoliarHealthResult] object for the V2 yield engine.
class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> initialize() async {
    final labelData = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelData.split('\n').where((s) => s.trim().isNotEmpty).toList();

    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset('assets/models/model.tflite', options: options);

    // Debug: log tensor types on startup to verify quantized uint8 format
    final inputTensor  = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    print('[TFLite] Input  → type: ${inputTensor.type}, shape: ${inputTensor.shape}');
    print('[TFLite] Output → type: ${outputTensor.type}, shape: ${outputTensor.shape}');
    print('[TFLite] Labels loaded: $_labels');
  }

  Future<FoliarHealthResult> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('TFLite model is not initialized. Call initialize() first.');
    }

    // ── IMAGE PREPROCESSING ──────────────────────────────────────────
    final imageBytes  = await imageFile.readAsBytes();
    img.Image? source = img.decodeImage(imageBytes);
    if (source == null) throw Exception('Failed to decode image file.');

    img.Image resized = img.copyResize(source, width: 224, height: 224);

    // Build [1, 224, 224, 3] uint8 input tensor for the quantized model
    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
        ),
      ),
    );

    // Output shape dynamic based on model tensor
    final outputTensor = _interpreter!.getOutputTensor(0);
    final numClasses = outputTensor.shape[1]; // e.g. 3
    var output = List.generate(1, (_) => List<int>.filled(numClasses, 0));

    // ── INFERENCE ────────────────────────────────────────────────────
    _interpreter!.run(input, output);
    final rawScores = output[0];

    // Find winning class (uint8 range 0–255)
    int maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < rawScores.length; i++) {
      if ((rawScores[i] as int) > maxScore) {
        maxScore = rawScores[i] as int;
        maxIndex = i;
      }
    }

    // Normalize confidence to 0.0–1.0
    final double confidence = maxScore / 255.0;
    final String rawLabel   = _labels![maxIndex];
    final bool isHealthy    = rawLabel.toLowerCase().contains('disease free') ||
                              rawLabel.toLowerCase().contains('healthy');

    // ── V2: COMPUTE RICH SCORES ──────────────────────────────────────

    // AI Health Score (w1 in FQI, weight 0.35)
    final double aiHealthScore;
    final LeafGrade grade;
    if (isHealthy) {
      if (confidence >= 0.80) {
        grade        = LeafGrade.excellent;
        aiHealthScore = 1.00;
      } else if (confidence >= 0.60) {
        grade        = LeafGrade.medium;
        aiHealthScore = 0.65;
      } else {
        grade        = LeafGrade.medium;
        aiHealthScore = 0.50;
      }
    } else {
      grade        = LeafGrade.poor;
      aiHealthScore = 0.25;
    }

    // Disease Flag Score (w5 in FQI, weight 0.10)
    // Healthy with high confidence → 1.0 | Diseased → drops with confidence
    final double diseaseFlagScore = isHealthy
        ? (confidence >= 0.80 ? 1.00 : 0.60)
        : 0.15;

    // Moisture Proxy (w4 in FQI, weight 0.15)
    // Heuristic: a high-confidence healthy classification implies a fresh,
    // non-wilted leaf. Low confidence → possible yellowing/wilting → lower score.
    final double moistureProxy = isHealthy
        ? (confidence >= 0.80 ? 1.00 : confidence >= 0.60 ? 0.75 : 0.55)
        : 0.40;

    // ── BUILD HUMAN-READABLE OUTPUT ──────────────────────────────────
    final String description;
    final String recommendation;

    switch (grade) {
      case LeafGrade.excellent:
        description    = 'Leaf is fully healthy. Protein and moisture levels are optimal for silkworm feeding.';
        recommendation = 'Safe to feed. Prioritise top-shoot leaves for best cocoon shell weight.';
        break;
      case LeafGrade.medium:
        description    = 'Leaf appears healthy but model confidence is moderate. Possible early-stage stress or slight wilting.';
        recommendation = 'Feed to 4th–5th instar worms only. Inspect manually before use with young larvae.';
        break;
      case LeafGrade.poor:
        description    = 'Pathogen detected: $rawLabel. Feeding these leaves risks disease transmission (Grasserie/Flacherie).';
        recommendation = 'DISCARD immediately. Sanitise the harvested area with bleaching powder. Do not feed to silkworms.';
        break;
    }

    return FoliarHealthResult(
      rawLabel:        rawLabel,
      confidence:      confidence,
      grade:           grade,
      aiHealthScore:   aiHealthScore,
      diseaseFlagScore: diseaseFlagScore,
      moistureProxy:   moistureProxy,
      description:     description,
      recommendation:  recommendation,
    );
  }

  void dispose() => _interpreter?.close();
}
