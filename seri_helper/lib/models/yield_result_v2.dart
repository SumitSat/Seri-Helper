/// YieldResultV2 holds the complete output of the V2 yield calculation engine.
/// It stores not just the final yield number but every intermediate sub-index
/// score so the UI can display a transparent, research-grade breakdown to farmers.
class YieldResultV2 {
  // ── INTERMEDIATE INDICES (0.0–1.0) ────────────────────────────────

  /// Foliage Quality Index — combines AI health score, leaf position,
  /// shoot age, moisture proxy, and disease flag.
  /// Formula weight in final yield: 38.2% (Miyashita 1986 / CSRTI Mysore).
  final double fqi;

  /// Climate Compliance Index — combines temperature score, humidity score,
  /// ventilation quality, and season score.
  /// Formula weight: 37.0%.
  final double cci;

  /// Soil & Nutrition Index — combines NPK score, pH score,
  /// fertilization method, and organic carbon.
  /// Formula weight: 24.8%.
  final double shi;

  /// Disease Risk Penalty — multiplicative factor (0.53–1.0).
  /// Derived from season, humidity, DFL source, and pesticide risk proxies.
  final double dPenalty;

  /// Breed & Management Factor — multiplicative factor (0.70–1.0).
  /// Derived from silkworm breed, hygiene protocol, and feeding frequency.
  final double bmFactor;

  // ── FQI SUB-SCORES ─────────────────────────────────────────────────
  final double fqiAiHealthScore;
  final double fqiLeafPositionScore;
  final double fqiLeafAgeScore;
  final double fqiMoistureProxy;
  final double fqiDiseaseFlagScore;

  // ── CCI SUB-SCORES ─────────────────────────────────────────────────
  final double cciTempScore;
  final double cciHumidScore;
  final double cciVentScore;
  final double cciSeasonScore;

  // ── SHI SUB-SCORES ─────────────────────────────────────────────────
  final double shiNpkScore;
  final double shiPhScore;
  final double shiFertilizationScore;
  final double shiOrganicCarbonScore;

  // ── DISEASE PENALTY BREAKDOWN ──────────────────────────────────────
  final double dGrasserieRisk;
  final double dFlacherieRisk;
  final double dMuscardineRisk;
  final double dPebrineRisk;
  final double dPesticideFlag;

  // ── BM FACTOR BREAKDOWN ────────────────────────────────────────────
  final double bmBreedScore;
  final double bmHygieneScore;
  final double bmFeedingScore;
  final double bmSeasonBreedScore;

  // ── FINAL YIELD OUTPUT ─────────────────────────────────────────────

  /// The final cocoon yield in kg per 100 DFLs (Disease-Free Layings).
  /// Base: 65 kg/100 DFLs for ideal CSR bivoltine under perfect conditions.
  final double yieldKgPer100DFLs;

  /// Low estimate of the yield range (±8% confidence band).
  double get yieldLow  => yieldKgPer100DFLs * 0.92;

  /// High estimate of the yield range (±8% confidence band).
  double get yieldHigh => yieldKgPer100DFLs * 1.08;

  /// The weighted base score before applying D_penalty and BM_factor.
  double get baseScore =>
      (0.382 * fqi) + (0.370 * cci) + (0.248 * shi);

  /// Overall efficiency percentage (0–100%).
  double get overallEfficiencyPercent => baseScore * 100;

  /// The single biggest limiting factor (the lowest sub-index name).
  String get limitingFactor {
    final scores = <String, double>{
      'Foliage Quality': fqi,
      'Climate Conditions': cci,
      'Soil Nutrition': shi,
      'Disease Risk': dPenalty,
      'Breed & Management': bmFactor,
    };
    return scores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// Human-readable primary recommendation based on the limiting factor.
  String get primaryRecommendation {
    switch (limitingFactor) {
      case 'Foliage Quality':
        return 'Harvest top-shoot leaves (positions +2 to +4) in the 55–65 day window to improve leaf quality.';
      case 'Climate Conditions':
        return 'Adjust rearing room temperature to 24–26°C and humidity to 75–85% for optimal silkworm performance.';
      case 'Soil Nutrition':
        return 'Apply foliar NPK spray (19:19:19 at 6g/L) in addition to basal fertilisation. This alone can boost yield by 52.8% (BSTRI 2022).';
      case 'Disease Risk':
        return 'Apply Labex or Sericillin bed disinfectant at every moult. Ensure DFLs are from a government-certified centre.';
      case 'Breed & Management':
        return 'Upgrade to CSR bivoltine hybrid DFLs and increase feeding frequency to 4 times/day during the 5th instar.';
      default:
        return 'Maintain current conditions. Monitor leaf quality and climate daily.';
    }
  }

  const YieldResultV2({
    required this.fqi,
    required this.cci,
    required this.shi,
    required this.dPenalty,
    required this.bmFactor,
    required this.fqiAiHealthScore,
    required this.fqiLeafPositionScore,
    required this.fqiLeafAgeScore,
    required this.fqiMoistureProxy,
    required this.fqiDiseaseFlagScore,
    required this.cciTempScore,
    required this.cciHumidScore,
    required this.cciVentScore,
    required this.cciSeasonScore,
    required this.shiNpkScore,
    required this.shiPhScore,
    required this.shiFertilizationScore,
    required this.shiOrganicCarbonScore,
    required this.dGrasserieRisk,
    required this.dFlacherieRisk,
    required this.dMuscardineRisk,
    required this.dPebrineRisk,
    required this.dPesticideFlag,
    required this.bmBreedScore,
    required this.bmHygieneScore,
    required this.bmFeedingScore,
    required this.bmSeasonBreedScore,
    required this.yieldKgPer100DFLs,
  });

  /// Converts to a Firestore-compatible map for persistence.
  Map<String, dynamic> toMap() => {
    'fqi': fqi, 'cci': cci, 'shi': shi,
    'dPenalty': dPenalty, 'bmFactor': bmFactor,
    'yieldKgPer100DFLs': yieldKgPer100DFLs,
    'yieldLow': yieldLow, 'yieldHigh': yieldHigh,
    'overallEfficiencyPercent': overallEfficiencyPercent,
    'limitingFactor': limitingFactor,
    // Sub-scores
    'fqi_ai': fqiAiHealthScore, 'fqi_pos': fqiLeafPositionScore,
    'fqi_age': fqiLeafAgeScore, 'fqi_moist': fqiMoistureProxy,
    'fqi_dis': fqiDiseaseFlagScore,
    'cci_temp': cciTempScore, 'cci_humid': cciHumidScore,
    'cci_vent': cciVentScore, 'cci_season': cciSeasonScore,
    'shi_npk': shiNpkScore, 'shi_ph': shiPhScore,
    'shi_fert': shiFertilizationScore, 'shi_oc': shiOrganicCarbonScore,
  };
}
