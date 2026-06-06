import 'package:seri_helper/models/models.dart';

/// The grade of a scanned mulberry leaf batch.
enum LeafGrade {
  excellent, // Healthy class with confidence ≥ 0.80
  medium,    // Healthy class with confidence 0.60–0.79
  poor,      // Any disease class OR healthy < 0.60
}

/// FoliarHealthResult is the rich output object produced by TFLiteService
/// after analyzing a leaf image. It replaces the old simple Map<String, dynamic>
/// with a strongly-typed object that contains all data needed by the V2 engine.
///
/// This object directly computes the AI-side inputs for the FQI formula:
///   FQI = (0.35 * aiHealthScore) + (0.20 * leafPositionScore) +
///         (0.20 * leafAgeScore)  + (0.15 * moistureProxy)     +
///         (0.10 * diseaseFlagInverse)
class FoliarHealthResult {
  /// The raw classification label from the TFLite model (e.g., "Healthy", "Red Rust").
  final String rawLabel;

  /// Raw confidence score from the model (0.0–1.0).
  final double confidence;

  /// The human-readable grade assigned by the Safety-First thresholding logic.
  final LeafGrade grade;

  /// The AI health score (0.0–1.0) — this is w1 in the FQI formula (weight: 0.35).
  /// Excellent → 1.0 | Medium → 0.65 | Poor → 0.25
  final double aiHealthScore;

  /// Disease flag inverse (0.0–1.0) — this is w5 in the FQI formula (weight: 0.10).
  /// Healthy → 1.0 | Spotted/partial disease → 0.40 | Severe disease → 0.10
  final double diseaseFlagScore;

  /// Moisture proxy (0.0–1.0) — inferred heuristically (w4 in FQI, weight: 0.15).
  /// High confidence healthy → 1.0 (leaf is fresh)
  /// Low confidence → score drops (possible wilting/discolouration)
  final double moistureProxy;

  /// Human-readable description for the result card UI.
  final String description;

  /// Actionable recommendation for the farmer.
  final String recommendation;

  const FoliarHealthResult({
    required this.rawLabel,
    required this.confidence,
    required this.grade,
    required this.aiHealthScore,
    required this.diseaseFlagScore,
    required this.moistureProxy,
    required this.description,
    required this.recommendation,
  });

  // ── DERIVED PROPERTIES FOR THE UI ────────────────────────────────

  /// A Foliar Health Index (FHI) out of 100 — shown prominently in the UI.
  /// This is computed purely from the AI analysis (before leaf position/age context).
  double get foliarHealthIndex =>
      ((aiHealthScore * 0.55) + (diseaseFlagScore * 0.25) + (moistureProxy * 0.20)) * 100;

  /// A label for the FHI score.
  String get fhiLabel {
    final fhi = foliarHealthIndex;
    if (fhi >= 80) return 'Excellent';
    if (fhi >= 60) return 'Good';
    if (fhi >= 40) return 'Moderate';
    return 'Poor';
  }

  /// Estimated necrotic/diseased area as a percentage (heuristic).
  /// For display purposes in the results screen.
  double get estimatedNecroticAreaPercent {
    if (grade == LeafGrade.excellent) return confidence < 0.9 ? 2.0 : 0.0;
    if (grade == LeafGrade.medium)    return (1.0 - confidence) * 25.0;
    return (1.0 - confidence) * 60.0 + 20.0;
  }

  /// Estimated feeding suitability as a percentage (for display).
  double get feedingSuitabilityPercent {
    if (grade == LeafGrade.excellent) return 100.0;
    if (grade == LeafGrade.medium)    return 70.0;
    return 15.0;
  }

  /// Grade label string for display.
  String get gradeLabel {
    switch (grade) {
      case LeafGrade.excellent: return 'Excellent';
      case LeafGrade.medium:    return 'Medium';
      case LeafGrade.poor:      return 'Poor';
    }
  }

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() => {
    'rawLabel':        rawLabel,
    'confidence':      confidence,
    'grade':           grade.name,
    'aiHealthScore':   aiHealthScore,
    'diseaseFlagScore':diseaseFlagScore,
    'moistureProxy':   moistureProxy,
    'foliarHealthIndex': foliarHealthIndex,
    'feedingSuitability': feedingSuitabilityPercent,
  };
}
