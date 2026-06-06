import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seri_helper/models/models.dart';

/// YieldEngineV2 is the research-grade V2 yield calculation service.
///
/// It replaces the original YieldService (V1) which used a simplified
/// 3-factor Miyashita 1986 formula. V2 implements 5 factors and 18
/// sub-parameters drawn from the full sericulture literature gap analysis.
///
/// Final Formula:
///   Yield = 65 × [0.382×FQI + 0.370×CCI + 0.248×SHI] × D_penalty × BM_factor
///
/// References:
///   Miyashita 1986 / CSRTI Mysore — base 3-factor skeleton + weights
///   Vegetos/Springer 2024 — leaf position effect
///   BSTRI Bangladesh — foliar NPK +52.8% yield vs control
///   Springer 2025 — monsoon Grasserie/Flacherie correlation
///   PMC 2020 — breed × shell weight 4.68× differential
///   Pharma Innovation Journal 2022 — disinfection 1:5 cost-benefit
class YieldEngineV2 {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double _baseYield = 65.0; // kg/100 DFLs — bivoltine hybrid max

  // ══════════════════════════════════════════════════════════════════════════
  // PUBLIC ENTRY POINT
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculates the full V2 yield prediction.
  ///
  /// [foliarResult]  — from TFLiteService.classifyImage()
  /// [harvest]       — from the Leaf Context bottom sheet
  /// [soil]          — from GeminiService.parseSoilHealthCard()
  /// [rearing]       — from the Batch Configuration screen
  /// [temperatureC]  — current rearing room temperature in °C
  /// [humidityPct]   — current rearing room humidity (0–100)
  YieldResultV2 calculate({
    required FoliarHealthResult foliarResult,
    required HarvestContext harvest,
    required SoilData soil,
    required RearingContext rearing,
    required double temperatureC,
    required double humidityPct,
  }) {
    // ── STEP 1: COMPUTE FQI SUB-SCORES ─────────────────────────────
    final double fqiAiHealth    = foliarResult.aiHealthScore;
    final double fqiPosition    = harvest.leafPositionScore;
    final double fqiAge         = harvest.leafAgeScore;
    final double fqiMoisture    = foliarResult.moistureProxy;
    final double fqiDisease     = foliarResult.diseaseFlagScore;

    // FQI = w1·AI + w2·Position + w3·Age + w4·Moisture + w5·DiseaseFlag
    // Weights: 0.35 + 0.20 + 0.20 + 0.15 + 0.10 = 1.00
    final double fqi = _clamp(
      (0.35 * fqiAiHealth) +
      (0.20 * fqiPosition) +
      (0.20 * fqiAge)      +
      (0.15 * fqiMoisture) +
      (0.10 * fqiDisease),
    );

    // ── STEP 2: COMPUTE CCI SUB-SCORES ─────────────────────────────
    final double cciTemp   = _temperatureScore(temperatureC);
    final double cciHumid  = _humidityScore(humidityPct);
    final double cciVent   = _ventilationScore(rearing.ventilation);
    final double cciSeason = _seasonScore(rearing.season);

    // CCI = w1·Temp + w2·Humid + w3·Vent + w4·Season
    // Weights: 0.40 + 0.30 + 0.15 + 0.15 = 1.00
    final double cci = _clamp(
      (0.40 * cciTemp)   +
      (0.30 * cciHumid)  +
      (0.15 * cciVent)   +
      (0.15 * cciSeason),
    );

    // ── STEP 3: COMPUTE SHI SUB-SCORES ─────────────────────────────
    final double shiNpk   = soil.npkScore;
    final double shiPh    = soil.phScore;
    final double shiFert  = _fertilizationScore(rearing.fertilizationMethod);
    final double shiOC    = soil.organicCarbonScore;

    // SHI = w1·NPK + w2·pH + w3·Fertilization + w4·OrganicCarbon
    // Weights: 0.40 + 0.25 + 0.25 + 0.10 = 1.00
    final double shi = _clamp(
      (0.40 * shiNpk)  +
      (0.25 * shiPh)   +
      (0.25 * shiFert) +
      (0.10 * shiOC),
    );

    // ── STEP 4: COMPUTE DISEASE PENALTY ────────────────────────────
    // All risks are derived from environmental proxies (no worm camera needed).
    // Research: Springer 2025 — Grasserie/Flacherie correlated with season + RH.
    final double dGrasserie  = _grasserieRisk(rearing.season, humidityPct);
    final double dFlacherie  = _flacherieRisk(rearing.season, humidityPct);
    final double dMuscardine = _muscardineRisk(rearing.season);
    final double dPebrine    = _pebrineRisk(rearing.dflSource);
    final double dPesticide  = rearing.pesticideRisk == PesticideRisk.present ? 0.5 : 0.0;

    // D_penalty = 1 – (Grasserie×0.30 + Flacherie×0.25 + Muscardine×0.15 + Pebrine×0.20 + Pesticide×0.10)
    double rawDPenalty = 1.0 - (
      (dGrasserie  * 0.30) +
      (dFlacherie  * 0.25) +
      (dMuscardine * 0.15) +
      (dPebrine    * 0.20) +
      (dPesticide  * 0.10)
    );
    // Clamp to minimum of 0.53 — even worst-case conditions, some cocoons survive.
    final double dPenalty = rawDPenalty.clamp(0.53, 1.0);

    // ── STEP 5: COMPUTE BREED & MANAGEMENT FACTOR ──────────────────
    final double bmBreed      = _breedScore(rearing.breed);
    final double bmHygiene    = _hygieneScore(rearing.hygieneLevel);
    final double bmFeeding    = rearing.feedingScore;
    final double bmSeasonBreed = _seasonBreedScore(rearing.breed, rearing.season);

    // BM_factor = w1·Breed + w2·Hygiene + w3·Feeding + w4·SeasonBreed
    // Weights: 0.35 + 0.30 + 0.25 + 0.10 = 1.00
    final double bmFactor = _clamp(
      (0.35 * bmBreed)       +
      (0.30 * bmHygiene)     +
      (0.25 * bmFeeding)     +
      (0.10 * bmSeasonBreed),
      min: 0.70,
    );

    // ── STEP 6: FINAL YIELD AGGREGATION ────────────────────────────
    // Yield = Base × [0.382×FQI + 0.370×CCI + 0.248×SHI] × D_penalty × BM_factor
    final double weightedBase = (0.382 * fqi) + (0.370 * cci) + (0.248 * shi);
    final double yield = _baseYield * weightedBase * dPenalty * bmFactor;

    return YieldResultV2(
      // Index scores
      fqi: fqi, cci: cci, shi: shi,
      dPenalty: dPenalty, bmFactor: bmFactor,
      // FQI breakdown
      fqiAiHealthScore: fqiAiHealth,
      fqiLeafPositionScore: fqiPosition,
      fqiLeafAgeScore: fqiAge,
      fqiMoistureProxy: fqiMoisture,
      fqiDiseaseFlagScore: fqiDisease,
      // CCI breakdown
      cciTempScore: cciTemp,
      cciHumidScore: cciHumid,
      cciVentScore: cciVent,
      cciSeasonScore: cciSeason,
      // SHI breakdown
      shiNpkScore: shiNpk,
      shiPhScore: shiPh,
      shiFertilizationScore: shiFert,
      shiOrganicCarbonScore: shiOC,
      // Disease breakdown
      dGrasserieRisk: dGrasserie,
      dFlacherieRisk: dFlacherie,
      dMuscardineRisk: dMuscardine,
      dPebrineRisk: dPebrine,
      dPesticideFlag: dPesticide,
      // BM breakdown
      bmBreedScore: bmBreed,
      bmHygieneScore: bmHygiene,
      bmFeedingScore: bmFeeding,
      bmSeasonBreedScore: bmSeasonBreed,
      // Final output
      yieldKgPer100DFLs: yield,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FIREBASE PERSISTENCE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> saveReportToFirebase({
    required YieldResultV2 result,
    required RearingContext rearing,
    required SoilData soil,
  }) async {
    try {
      await _firestore.collection('yield_reports_v2').add({
        ...result.toMap(),
        ...rearing.toMap(),
        ...soil.toMap(),
        'modelVersion': 'V2',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('[YieldEngineV2] Report saved to Firestore.');
    } catch (e) {
      print('[YieldEngineV2] Firebase sync failed: $e');
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE SCORING HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Clamps a value to [min, max]. Default range is [0.0, 1.0].
  double _clamp(double val, {double min = 0.0, double max = 1.0}) =>
      val.clamp(min, max);

  // ── TEMPERATURE SCORE ──────────────────────────────────────────────
  // Research: Rehman et al. 2000 — 30°C reduces shell weight 24–28%.
  // Research: Uttarakhand study — 24°C + 80% RH → >88% larval survival.
  double _temperatureScore(double temp) {
    if (temp >= 24.0 && temp <= 26.0) return 1.00; // Optimal rearing range
    if (temp >= 22.0 && temp <  24.0) return 0.90; // Slightly cool but acceptable
    if (temp >  26.0 && temp <= 28.0) return 0.85; // Warmer — slightly stressful
    if (temp >  28.0 && temp <= 30.0) return 0.65; // Significant heat stress
    if (temp >  30.0 && temp <= 32.0) return 0.45; // Severe heat — silk gland affected
    if (temp >= 18.0 && temp <  22.0) return 0.60; // Cold — slow development
    return 0.25; // Extreme: >32°C or <18°C
  }

  // ── HUMIDITY SCORE ─────────────────────────────────────────────────
  // Research: Rehman et al. 2000 — 94% RH improves cocoon weight 13–20%.
  // Research: Kumar et al. 2021 — low RH dries leaves → poor ingestion.
  double _humidityScore(double rh) {
    if (rh >= 75.0 && rh <= 85.0) return 1.00; // Optimal band
    if (rh >= 85.0 && rh <= 90.0) return 0.80; // High — disease risk starts
    if (rh >= 70.0 && rh <  75.0) return 0.80; // Slightly low — leaf wilting risk
    if (rh >  90.0 && rh <= 94.0) return 0.65; // Very high — Grasserie/Muscardine risk
    if (rh >= 65.0 && rh <  70.0) return 0.60; // Dry — reduced leaf palatability
    if (rh >  94.0)                return 0.45; // Extremely humid — disease onset
    return 0.35; // < 65% — severe drought stress on leaves
  }

  // ── VENTILATION SCORE ──────────────────────────────────────────────
  double _ventilationScore(VentilationQuality v) {
    switch (v) {
      case VentilationQuality.good:     return 1.00;
      case VentilationQuality.moderate: return 0.75;
      case VentilationQuality.poor:     return 0.50;
    }
  }

  // ── SEASON SCORE ───────────────────────────────────────────────────
  // Research: J. Insect Science — leaf intake lowest in summer, highest winter.
  // Research: Springer 2025 — monsoon = peak disease pressure.
  double _seasonScore(RearingSeason s) {
    switch (s) {
      case RearingSeason.spring:  return 1.00;
      case RearingSeason.winter:  return 0.85;
      case RearingSeason.monsoon: return 0.70;
      case RearingSeason.summer:  return 0.65;
    }
  }

  // ── FERTILIZATION SCORE ────────────────────────────────────────────
  // Research: BSTRI Bangladesh — foliar + basal = +52.8% cocoon yield vs. control.
  double _fertilizationScore(FertilizationMethod f) {
    switch (f) {
      case FertilizationMethod.foliarPlusBasal: return 1.00;
      case FertilizationMethod.basalOnly:       return 0.70;
      case FertilizationMethod.none:            return 0.40;
    }
  }

  // ── BREED SCORE ────────────────────────────────────────────────────
  // Research: PMC 2020 — domestic bivoltine shell weight 4.68× wild strains.
  double _breedScore(SilkwormBreed b) {
    switch (b) {
      case SilkwormBreed.bivoltineCSR:       return 1.00;
      case SilkwormBreed.multivoltineCross:  return 0.85;
      case SilkwormBreed.pureMultivoltine:   return 0.70;
    }
  }

  // ── HYGIENE SCORE ──────────────────────────────────────────────────
  // Research: Pharma Innovation Journal 2022 — Sanjeevini 1:5 cost-benefit.
  double _hygieneScore(HygieneLevel h) {
    switch (h) {
      case HygieneLevel.full:    return 1.00;
      case HygieneLevel.partial: return 0.75;
      case HygieneLevel.none:    return 0.40;
    }
  }

  // ── SEASON–BREED MISMATCH ──────────────────────────────────────────
  // Research: Oxford Academic 2011 — bivoltine breeds heat-sensitive in summer.
  double _seasonBreedScore(SilkwormBreed b, RearingSeason s) {
    if (b == SilkwormBreed.bivoltineCSR && s == RearingSeason.summer) {
      return 0.75; // Bivoltine in summer — thermally stressed
    }
    if (b == SilkwormBreed.pureMultivoltine) {
      return 0.90; // Multivoltine is hardy in any season
    }
    return 1.00;
  }

  // ── DISEASE RISK PROXIES ───────────────────────────────────────────
  // Computed entirely from environmental inputs — no camera on worms needed.
  // Research: Springer 2025 — strong correlation of Grasserie with RH + season.

  double _grasserieRisk(RearingSeason season, double rh) {
    // Base risk by season (Shravani/monsoon crop = 8.37% incidence)
    double base = switch (season) {
      RearingSeason.monsoon => 0.30,
      RearingSeason.summer  => 0.15,
      RearingSeason.winter  => 0.08,
      RearingSeason.spring  => 0.05,
    };
    // RH > 85% adds significant risk
    if (rh > 90) base = (base + 0.20).clamp(0.0, 0.80);
    else if (rh > 85) base = (base + 0.10).clamp(0.0, 0.80);
    return base;
  }

  double _flacherieRisk(RearingSeason season, double rh) {
    // Flacherie is the most prevalent disease (47.9% share — Savanurmath, Bangalore)
    double base = switch (season) {
      RearingSeason.monsoon => 0.35,
      RearingSeason.summer  => 0.20,
      RearingSeason.winter  => 0.10,
      RearingSeason.spring  => 0.07,
    };
    if (rh > 90) base = (base + 0.15).clamp(0.0, 0.80);
    return base;
  }

  double _muscardineRisk(RearingSeason season) {
    // Highest in Falguni (cool/damp) crop — Springer 2025
    return switch (season) {
      RearingSeason.winter  => 0.15,
      RearingSeason.monsoon => 0.10,
      RearingSeason.spring  => 0.05,
      RearingSeason.summer  => 0.03,
    };
  }

  double _pebrineRisk(DflSource source) {
    // Research: PMC 2023 — Nosema crop failure 36%; pebrine "can wipe out industry".
    return switch (source) {
      DflSource.governmentCertified => 0.05,
      DflSource.uncertified         => 0.40,
    };
  }
}
