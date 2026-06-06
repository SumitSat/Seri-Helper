/// SoilData is the expanded V2 model for soil health card data.
/// It is populated by the Groq LLM from a scanned Soil Health Card image.
///
/// V1 fields (always expected): nitrogen, phosphorus, potassium, pH, moisture.
/// V2 fields (extracted if available on card, otherwise null): EC, OC, Zn, Fe, B.
///
/// Research basis:
/// - N, P, K: BSTRI Bangladesh — foliar NPK spray +52.8% cocoon yield vs. control
/// - pH: Ideal range 6.5–6.8 for mulberry (CSRTI Mysore guidelines)
/// - OC: Ultimate indicator of long-term soil fertility
/// - EC: Mulberry roots highly sensitive to salinity (>1.0 dS/m is damaging)
/// - Micronutrients: PMC 2022 — Zn, Fe, Ca, Mn predict silk thread parameters
class SoilData {
  // ── V1 CORE PARAMETERS ────────────────────────────────────────────
  /// Nitrogen in kg/ha. Optimal for mulberry: ≥ 280 kg/ha/year.
  final double nitrogen;

  /// Phosphorus in kg/ha. Optimal: ≥ 60 kg/ha/year.
  final double phosphorus;

  /// Potassium in kg/ha. Optimal: ≥ 100 kg/ha/year.
  final double potassium;

  /// Soil pH. Optimal for mulberry: 6.5–6.8. Critical range: 5.5–7.5.
  final double pH;

  /// Soil moisture percentage. Available from some SHC cards.
  final double moisture;

  // ── V2 EXTENDED PARAMETERS (nullable — may not be on all cards) ──

  /// Electrical Conductivity in dS/m.
  /// Optimal: < 0.5 dS/m. Damaging: > 1.0 dS/m (salt stress).
  final double? electricalConductivity;

  /// Organic Carbon percentage.
  /// Optimal: ≥ 0.75%. Below 0.5% = low fertility, long-term yield risk.
  final double? organicCarbon;

  /// Zinc (Zn) in mg/kg. Critical threshold: < 0.6 mg/kg = deficient.
  final double? zinc;

  /// Iron (Fe) in mg/kg. Critical threshold: < 4.5 mg/kg = deficient.
  final double? iron;

  /// Boron (B) in mg/kg. Mulberry requires adequate B for leaf development.
  final double? boron;

  /// Sulfur (S) in mg/kg. Mulberry leaves require S for silk protein synthesis.
  final double? sulfur;

  const SoilData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.pH,
    required this.moisture,
    // V2 fields are optional
    this.electricalConductivity,
    this.organicCarbon,
    this.zinc,
    this.iron,
    this.boron,
    this.sulfur,
  });

  // ── SCORING METHODS ───────────────────────────────────────────────

  /// Computes the Nitrogen score (0.0–1.0).
  /// Optimal: ≥ 280 kg/ha. Adequate: ≥ 140 kg/ha.
  double get nitrogenScore {
    if (nitrogen >= 280) return 1.00;
    if (nitrogen >= 140) return 0.80;
    if (nitrogen >= 70)  return 0.55;
    return 0.30;
  }

  /// Computes the Phosphorus score (0.0–1.0).
  double get phosphorusScore {
    if (phosphorus >= 60) return 1.00;
    if (phosphorus >= 30) return 0.80;
    if (phosphorus >= 15) return 0.55;
    return 0.30;
  }

  /// Computes the Potassium score (0.0–1.0).
  double get potassiumScore {
    if (potassium >= 100) return 1.00;
    if (potassium >= 50)  return 0.80;
    if (potassium >= 25)  return 0.55;
    return 0.30;
  }

  /// Computes the combined NPK score (0.0–1.0) — weighted average.
  double get npkScore => (nitrogenScore * 0.5 + phosphorusScore * 0.25 + potassiumScore * 0.25);

  /// Computes the pH compliance score (0.0–1.0).
  /// Ideal: 6.5–6.8 | Acceptable: 6.0–7.2 | Damaging: <5.5 or >8.0
  double get phScore {
    if (pH >= 6.5 && pH <= 6.8) return 1.00;
    if (pH >= 6.0 && pH <= 7.2) return 0.85;
    if (pH >= 5.5 && pH <= 7.5) return 0.65;
    return 0.35;
  }

  /// Computes the Organic Carbon score (0.0–1.0). Returns 0.75 if unknown.
  double get organicCarbonScore {
    if (organicCarbon == null) return 0.75; // conservative default
    if (organicCarbon! >= 0.75) return 1.00;
    if (organicCarbon! >= 0.50) return 0.75;
    return 0.45; // critically low OC
  }

  /// Computes the EC (salinity) penalty (0.0–1.0). Returns 1.0 if unknown.
  double get ecScore {
    if (electricalConductivity == null) return 1.00; // assume fine if not on card
    if (electricalConductivity! < 0.5)  return 1.00; // ideal
    if (electricalConductivity! < 1.0)  return 0.80; // borderline
    if (electricalConductivity! < 2.0)  return 0.55; // damaging
    return 0.25; // severely saline
  }

  /// Returns a human-readable pH status label.
  String get phLabel {
    if (pH >= 6.5 && pH <= 6.8) return 'Optimal';
    if (pH < 6.5) return 'Acidic';
    return 'Alkaline';
  }

  /// Returns a human-readable EC status label.
  String get ecLabel {
    if (electricalConductivity == null) return 'Not available';
    if (electricalConductivity! < 0.5)  return 'Ideal';
    if (electricalConductivity! < 1.0)  return 'Borderline';
    return 'High — salinity risk';
  }

  // ── SERIALIZATION ─────────────────────────────────────────────────

  /// Creates a SoilData from the JSON map returned by the Groq LLM.
  factory SoilData.fromLlmJson(Map<String, dynamic> json) {
    return SoilData(
      nitrogen:               (json['nitrogen']             as num?)?.toDouble() ?? 0.0,
      phosphorus:             (json['phosphorus']           as num?)?.toDouble() ?? 0.0,
      potassium:              (json['potassium']            as num?)?.toDouble() ?? 0.0,
      pH:                     (json['pH']                   as num?)?.toDouble() ?? 7.0,
      moisture:               (json['moisture']             as num?)?.toDouble() ?? 0.0,
      electricalConductivity: (json['ec']                   as num?)?.toDouble(),
      organicCarbon:          (json['organicCarbon']        as num?)?.toDouble(),
      zinc:                   (json['zinc']                 as num?)?.toDouble(),
      iron:                   (json['iron']                 as num?)?.toDouble(),
      boron:                  (json['boron']                as num?)?.toDouble(),
      sulfur:                 (json['sulfur']               as num?)?.toDouble(),
    );
  }

  /// Creates a SoilData from a Firestore document map (backward compatible with V1).
  factory SoilData.fromFirestoreMap(Map<String, dynamic> map) {
    return SoilData(
      nitrogen:               (map['nitrogen']              as num?)?.toDouble() ?? 0.0,
      phosphorus:             (map['phosphorus']            as num?)?.toDouble() ?? 0.0,
      potassium:              (map['potassium']             as num?)?.toDouble() ?? 0.0,
      pH:                     (map['pH']                    as num?)?.toDouble() ?? 7.0,
      moisture:               (map['moisture']              as num?)?.toDouble() ?? 0.0,
      electricalConductivity: (map['electricalConductivity'] as num?)?.toDouble(),
      organicCarbon:          (map['organicCarbon']         as num?)?.toDouble(),
      zinc:                   (map['zinc']                  as num?)?.toDouble(),
      iron:                   (map['iron']                  as num?)?.toDouble(),
      boron:                  (map['boron']                 as num?)?.toDouble(),
      sulfur:                 (map['sulfur']                as num?)?.toDouble(),
    );
  }

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() => {
    'nitrogen':               nitrogen,
    'phosphorus':             phosphorus,
    'potassium':              potassium,
    'pH':                     pH,
    'moisture':               moisture,
    if (electricalConductivity != null) 'electricalConductivity': electricalConductivity,
    if (organicCarbon != null)          'organicCarbon':          organicCarbon,
    if (zinc != null)                   'zinc':                   zinc,
    if (iron != null)                   'iron':                   iron,
    if (boron != null)                  'boron':                  boron,
    if (sulfur != null)                 'sulfur':                 sulfur,
  };
}
