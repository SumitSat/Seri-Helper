/// Represents the position on the mulberry shoot where leaves were harvested.
/// Research: Vegetos/Springer 2024 — top leaves yield highest cocoon shell weight.
enum LeafPosition {
  top,   // Positions +2 to +4 — highest protein & moisture. Score: 1.00
  mixed, // A mixture of positions — practical for most farms. Score: 0.85
  basal, // Positions +8 to +10 — lower protein, higher carb. Score: 0.65
}

/// Represents the mulberry variety/genotype being cultivated.
/// Research: PMC 2022 — local genotypes with higher protein yield better silk thread.
enum MulberryVariety {
  v1        , // V1 — high-yielding, commercial Karnataka standard. Score: 1.00
  s13       , // S13 — moderate yield, robust disease resistance. Score: 0.90
  s36       , // S36 — lower leaf yield but high moisture. Score: 0.85
  local     , // Local/unimproved variety — variable quality. Score: 0.70
  unknown   , // Farmer doesn't know — use conservative estimate. Score: 0.75
}

/// HarvestContext holds all metadata related to the mulberry leaf at the time
/// of harvesting. This object is created when a farmer initiates a leaf scan
/// and answers the "Leaf Context" bottom sheet questions.
///
/// It feeds directly into FQI (Foliage Quality Index) in the V2 yield engine.
class HarvestContext {
  /// Where on the shoot were these leaves plucked?
  final LeafPosition leafPosition;

  /// The age of the mulberry shoot at time of harvest, in days.
  /// Research: Sericologia 1997 — optimal window is 55–65 days for late-age worms.
  /// Score mapping: 55–65 days = 1.0 | 45–54 days = 0.85 | 66–75 days = 0.80
  ///                35–44 days = 0.60 | <35 or >75 days = 0.45
  final int shootAgeDays;

  /// The mulberry variety being cultivated.
  final MulberryVariety variety;

  /// Is the mulberry field isolated from adjacent pesticide-using crops?
  /// Research: Agriculture Institute 2025 — pesticide drift is a leading cause of batch loss.
  final bool isFieldIsolated;

  const HarvestContext({
    required this.leafPosition,
    required this.shootAgeDays,
    required this.variety,
    required this.isFieldIsolated,
  });

  /// Computes the leaf age score (0.0–1.0) based on the shoot age in days.
  /// Based on: Sericologia 1997 — maturity-quality window confirmed across 14 varieties.
  double get leafAgeScore {
    if (shootAgeDays >= 55 && shootAgeDays <= 65) return 1.00;
    if (shootAgeDays >= 45 && shootAgeDays < 55)  return 0.85;
    if (shootAgeDays > 65 && shootAgeDays <= 75)  return 0.80;
    if (shootAgeDays >= 35 && shootAgeDays < 45)  return 0.60;
    return 0.45; // Too young (<35 days) or too old (>75 days)
  }

  /// Computes the leaf position score (0.0–1.0).
  double get leafPositionScore {
    switch (leafPosition) {
      case LeafPosition.top:   return 1.00;
      case LeafPosition.mixed: return 0.85;
      case LeafPosition.basal: return 0.65;
    }
  }

  /// Computes the mulberry variety score (0.0–1.0).
  double get varietyScore {
    switch (variety) {
      case MulberryVariety.v1:      return 1.00;
      case MulberryVariety.s13:     return 0.90;
      case MulberryVariety.s36:     return 0.85;
      case MulberryVariety.unknown: return 0.75;
      case MulberryVariety.local:   return 0.70;
    }
  }

  /// A human-readable label for the shoot age quality.
  String get shootAgeLabel {
    if (shootAgeDays >= 55 && shootAgeDays <= 65) return 'Optimal window';
    if (shootAgeDays < 55) return 'Under-mature';
    return 'Over-mature';
  }

  /// Creates a HarvestContext from a Firestore document map.
  factory HarvestContext.fromMap(Map<String, dynamic> map) {
    return HarvestContext(
      leafPosition: LeafPosition.values.byName(map['leafPosition'] ?? 'mixed'),
      shootAgeDays: map['shootAgeDays'] ?? 55,
      variety: MulberryVariety.values.byName(map['variety'] ?? 'unknown'),
      isFieldIsolated: map['isFieldIsolated'] ?? false,
    );
  }

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() => {
    'leafPosition': leafPosition.name,
    'shootAgeDays': shootAgeDays,
    'variety': variety.name,
    'isFieldIsolated': isFieldIsolated,
  };
}
