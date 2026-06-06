import 'package:flutter/foundation.dart';
import 'package:seri_helper/models/models.dart';

/// Holds the active RearingContext for the current batch session.
/// Shared across all screens via Provider.
class RearingContextProvider extends ChangeNotifier {
  RearingContext _context = const RearingContext(
    season: RearingSeason.spring,
    breed: SilkwormBreed.bivoltineCSR,
    hygieneLevel: HygieneLevel.full,
    fertilizationMethod: FertilizationMethod.basalOnly,
    dflSource: DflSource.governmentCertified,
    pesticideRisk: PesticideRisk.none,
    ventilation: VentilationQuality.moderate,
    feedingFrequencyPerDay: 3,
  );

  RearingContext get context => _context;
  bool get isConfigured => _isConfigured;
  bool _isConfigured = false;

  void update(RearingContext ctx) {
    _context = ctx;
    _isConfigured = true;
    notifyListeners();
  }
}

/// Holds the latest leaf scan results (FoliarHealthResult + HarvestContext).
class LeafScanProvider extends ChangeNotifier {
  FoliarHealthResult? _foliarResult;
  HarvestContext? _harvestContext;

  FoliarHealthResult? get foliarResult => _foliarResult;
  HarvestContext? get harvestContext => _harvestContext;
  bool get hasData => _foliarResult != null && _harvestContext != null;

  void update({required FoliarHealthResult foliar, required HarvestContext harvest}) {
    _foliarResult = foliar;
    _harvestContext = harvest;
    notifyListeners();
  }

  void clearFoliar() {
    _foliarResult = null;
    _harvestContext = null;
    notifyListeners();
  }
}

/// Holds the latest SoilData extracted by GeminiService.
class SoilDataProvider extends ChangeNotifier {
  SoilData? _soilData;

  SoilData? get soilData => _soilData;
  bool get hasData => _soilData != null;

  void update(SoilData data) {
    _soilData = data;
    notifyListeners();
  }

  void clear() {
    _soilData = null;
    notifyListeners();
  }
}
