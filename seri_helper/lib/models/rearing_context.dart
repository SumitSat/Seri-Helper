/// Represents the rearing season, which affects climate compliance,
/// disease risk probability, and leaf nutritional quality.
/// Research: Springer 2025 — monsoon = 8.37% Grasserie incidence.
enum RearingSeason {
  spring,   // Best: balanced T/RH, lowest disease risk. Score: 1.00
  winter,   // High leaf intake but slow development. Score: 0.85
  monsoon,  // Peak Grasserie + Flacherie pressure. Score: 0.70
  summer,   // Reduced leaf intake, heat-stressed bivoltines. Score: 0.65
}

/// The silkworm breed type, the single biggest genetic lever for yield.
/// Research: PMC 2020 — domestic bivoltine yields 4.68× more than wild strains.
enum SilkwormBreed {
  bivoltineCSR,       // CSR hybrids (PM×CSR2, PM×CSR4) — commercial India standard. Score: 1.00
  multivoltineCross,  // Multivoltine × Bivoltine cross — robust, moderate yield. Score: 0.85
  pureMultivoltine,   // Fully multivoltine — hardy, lower cocoon shell ratio. Score: 0.70
}

/// The hygiene and disinfection protocol used in the rearing house.
/// Research: Pharma Innovation Journal 2022 — 15–47% crop loss without disinfection.
enum HygieneLevel {
  full,     // Full CSRTI protocol: Formalin/Bleach powder/Labex applied at every moult. Score: 1.00
  partial,  // Some disinfectant used but not at every stage. Score: 0.75
  none,     // No disinfectant used — high disease risk. Score: 0.40
}

/// The fertilization method used on the mulberry field.
/// Research: BSTRI Bangladesh — foliar NPK spray = +52.8% cocoon yield vs. control.
enum FertilizationMethod {
  foliarPlusBasal, // Both foliar spray AND basal application — optimal. Score: 1.00
  basalOnly,       // Basal NPK applied but no foliar spray. Score: 0.70
  none,            // No fertilization applied. Score: 0.40
}

/// The DFL (Disease-Free Laying) source — critical for Pebrine risk.
/// Research: PMC 2023 — uncertified DFLs carry up to 36% crop-failure risk (Nosema).
enum DflSource {
  governmentCertified, // From KSDB/CSB certified centre. Risk: 0.05
  uncertified,         // From local/informal source. Risk: 0.40
}

/// Whether adjacent farms use pesticides that can drift onto mulberry.
/// Research: Agriculture Institute 2025 — "leading cause of unexpected batch losses".
enum PesticideRisk {
  none,   // No adjacent pesticide-using farms. Flag: 0.0
  present // Adjacent farm uses pesticides. Flag: 0.5
}

/// Ventilation quality of the rearing house.
/// Research: Kumar et al. 2021 — ammonia/CO2 build-up suppresses feeding.
enum VentilationQuality {
  good,     // Cross-ventilation, regular bed cleaning, no odour. Score: 1.00
  moderate, // Some airflow but not ideal. Score: 0.75
  poor,     // Stuffy, ammonia smell present. Score: 0.50
}

/// RearingContext is the master object holding all farmer-provided
/// management and environmental metadata for a single rearing batch.
/// This object feeds into CCI (Climate), SHI (Soil), D_penalty, and BM_factor
/// in the V2 yield calculation engine.
class RearingContext {
  final RearingSeason season;
  final SilkwormBreed breed;
  final HygieneLevel hygieneLevel;
  final FertilizationMethod fertilizationMethod;
  final DflSource dflSource;
  final PesticideRisk pesticideRisk;
  final VentilationQuality ventilation;

  /// How many times per day are silkworms fed (especially critical in 5th instar)?
  /// Research: FAO — 5th instar requires feeding every 3-4 hrs (3-4 times/day minimum).
  /// Score: 4+ per day = 1.0 | 3/day = 0.85 | 2/day = 0.65 | 1/day = 0.40
  final int feedingFrequencyPerDay;

  const RearingContext({
    required this.season,
    required this.breed,
    required this.hygieneLevel,
    required this.fertilizationMethod,
    required this.dflSource,
    required this.pesticideRisk,
    required this.ventilation,
    required this.feedingFrequencyPerDay,
  });

  /// Returns a score from 0.0 to 1.0 representing feeding frequency compliance.
  double get feedingScore {
    if (feedingFrequencyPerDay >= 4) return 1.00;
    if (feedingFrequencyPerDay == 3) return 0.85;
    if (feedingFrequencyPerDay == 2) return 0.65;
    return 0.40; // 1 or fewer times per day — severe underfeeding
  }

  /// Creates a RearingContext from a Firestore document map for V5 compatibility.
  factory RearingContext.fromMap(Map<String, dynamic> map) {
    return RearingContext(
      season: RearingSeason.values.byName(map['season'] ?? 'spring'),
      breed: SilkwormBreed.values.byName(map['breed'] ?? 'bivoltineCSR'),
      hygieneLevel: HygieneLevel.values.byName(map['hygieneLevel'] ?? 'partial'),
      fertilizationMethod: FertilizationMethod.values.byName(map['fertilizationMethod'] ?? 'basalOnly'),
      dflSource: DflSource.values.byName(map['dflSource'] ?? 'uncertified'),
      pesticideRisk: PesticideRisk.values.byName(map['pesticideRisk'] ?? 'none'),
      ventilation: VentilationQuality.values.byName(map['ventilation'] ?? 'moderate'),
      feedingFrequencyPerDay: map['feedingFrequencyPerDay'] ?? 3,
    );
  }

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() => {
    'season': season.name,
    'breed': breed.name,
    'hygieneLevel': hygieneLevel.name,
    'fertilizationMethod': fertilizationMethod.name,
    'dflSource': dflSource.name,
    'pesticideRisk': pesticideRisk.name,
    'ventilation': ventilation.name,
    'feedingFrequencyPerDay': feedingFrequencyPerDay,
  };
}
