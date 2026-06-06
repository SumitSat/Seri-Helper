import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/gemini_service.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/localization.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/score_gauge.dart';

class SoilScannerScreen extends StatefulWidget {
  const SoilScannerScreen({Key? key}) : super(key: key);

  @override
  State<SoilScannerScreen> createState() => _SoilScannerScreenState();
}

class _SoilScannerScreenState extends State<SoilScannerScreen> {
  final GeminiService _gemini = GeminiService();
  final ImagePicker   _picker = ImagePicker();

  File?     _image;
  SoilData? _soilData;
  bool      _isLoading = false;
  bool      _showExtended = false;

  // Manual edit controllers (human-in-the-loop)
  final _nCtrl  = TextEditingController();
  final _pCtrl  = TextEditingController();
  final _kCtrl  = TextEditingController();
  final _phCtrl = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() { _image = File(picked.path); _isLoading = true; _soilData = null; });

    try {
      final data = await _gemini.parseSoilHealthCard(_image!);
      HapticFeedback.mediumImpact();
      _nCtrl.text  = data.nitrogen == 0.0 ? '' : data.nitrogen.toString();
      _pCtrl.text  = data.phosphorus == 0.0 ? '' : data.phosphorus.toString();
      _kCtrl.text  = data.potassium == 0.0 ? '' : data.potassium.toString();
      _phCtrl.text = data.pH == 0.0 ? '' : data.pH.toString();

      setState(() { _soilData = data; _isLoading = false; });
      // Save to provider automatically
      if (mounted) context.read<SoilDataProvider>().update(data);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Extraction failed: $e'), backgroundColor: AppTheme.critical),
      );
    }
  }

  void _applyManualCorrections() {
    if (_soilData == null) return;
    final corrected = SoilData(
      nitrogen:               double.tryParse(_nCtrl.text)  ?? _soilData!.nitrogen,
      phosphorus:             double.tryParse(_pCtrl.text)  ?? _soilData!.phosphorus,
      potassium:              double.tryParse(_kCtrl.text)  ?? _soilData!.potassium,
      pH:                     double.tryParse(_phCtrl.text) ?? _soilData!.pH,
      moisture:               _soilData!.moisture,
      electricalConductivity: _soilData!.electricalConductivity,
      organicCarbon:          _soilData!.organicCarbon,
      zinc:                   _soilData!.zinc,
      iron:                   _soilData!.iron,
      boron:                  _soilData!.boron,
      sulfur:                 _soilData!.sulfur,
    );
    setState(() => _soilData = corrected);
    context.read<SoilDataProvider>().update(corrected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('✅ Soil Data Saved! Go to Dashboard tab to view Yield Forecast.'), backgroundColor: AppTheme.optimal,
          behavior: SnackBarBehavior.floating),
    );
  }

  String _formatParam(double value, AppLocalizations local) {
    if (value == 0.0) return local.locale == 'en' ? 'Data not available' : 'माहिती उपलब्ध नाही';
    return value.toStringAsFixed(1);
  }

  /// Same as _formatParam but accepts nullable doubles (for extended soil params).
  /// Returns 'Data not available' when null OR when value is exactly 0.0.
  String _formatExtParam(double? value, AppLocalizations local) {
    if (value == null || value == 0.0) {
      return local.locale == 'en' ? 'Data not available' : 'माहिती उपलब्ध नाही';
    }
    return value.toStringAsFixed(2);
  }

  bool _extParamHasData(double? value) => value != null && value != 0.0;

  double _soilSuitabilityScore(SoilData d) =>
      (d.npkScore * 0.40 + d.phScore * 0.30 + d.organicCarbonScore * 0.20 + d.ecScore * 0.10) * 100;

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(local.translate('soil_scanner_title'), style: AppTheme.headline2(context)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate_rounded, color: AppTheme.leafAccent),
                        onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                        tooltip: local.locale == 'en' ? 'मराठी' : 'English',
                      ),
                      const Icon(Icons.landscape_rounded, color: AppTheme.earthBrown, size: 28),
                    ],
                  ),
                ]),
                Text(local.translate('soil_scanner_sub'), style: AppTheme.bodyMedium(context)),
                const SizedBox(height: 20),

                // Image preview
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: SizedBox(
                      height: 240,
                      child: _image != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_image!, fit: BoxFit.cover),
                                if (_isLoading) Container(
                                  color: Colors.black54,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(color: AppTheme.leafAccent),
                                      const SizedBox(height: 16),
                                      Text(local.locale == 'en' ? 'AI reading soil card...' : 'एआय माती परीक्षण पत्रक वाचत आहे...', style: AppTheme.bodyLarge(context)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.document_scanner_rounded, size: 60, color: AppTheme.earthBrown.withOpacity(0.6)),
                              const SizedBox(height: 16),
                              Text(local.translate('scan_card'), style: AppTheme.bodyLarge(context)),
                              Text(local.translate('krishi_tip'), style: AppTheme.bodyMedium(context)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Scan buttons
                Row(children: [
                  Expanded(child: _ActionButton(
                    icon: Icons.camera_alt_rounded, label: local.translate('camera'),
                    gradient: AppTheme.soilGradient,
                    onTap: () => _pickImage(ImageSource.camera),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.image_rounded, label: local.translate('gallery'),
                    gradient: AppTheme.soilGradient,
                    onTap: () => _pickImage(ImageSource.gallery),
                  )),
                ]),
                const SizedBox(height: 28),

                if (_soilData != null) ..._buildResultSection(context, local, _soilData!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultSection(BuildContext context, AppLocalizations local, SoilData d) {
    final suitScore = _soilSuitabilityScore(d);

    return [
      SectionHeader(title: local.translate('foliar_report')),

      // Hero: suitability gauge + quick reco
      GlassCard(
        child: Row(
          children: [
            ScoreGauge(score: suitScore, label: local.locale == 'en' ? 'Soil\nFitness' : 'मातीची\nयोग्यता', size: 130),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(local.translate('suitability_score_label'), style: AppTheme.headline3(context).copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Text(_getLocalizedPhLabel(local, d.phLabel), style: AppTheme.bodyMedium(context).copyWith(
                    color: AppTheme.scoreColor(d.phScore), fontWeight: FontWeight.w700)),
                Text(local.locale == 'en' 
                    ? 'pH ${d.pH.toStringAsFixed(1)} — Optimal: 6.5–6.8'
                    : 'पीएच ${d.pH.toStringAsFixed(1)} — आदर्श: ६.५–६.८', style: AppTheme.bodyMedium(context).copyWith(fontSize: 12)),
                const SizedBox(height: 8),
                MiniScoreBar(score: d.npkScore, label: 'NPK'),
                const SizedBox(height: 6),
                MiniScoreBar(score: d.phScore, label: 'pH'),
              ]),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Radar chart
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(local.translate('nutrient_radar'), style: AppTheme.headline3(context).copyWith(fontSize: 15)),
            Text(local.translate('radar_subtitle'), style: AppTheme.bodyMedium(context)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                  gridBorderData: const BorderSide(color: AppTheme.glassBorder, width: 1),
                  radarBorderData: const BorderSide(color: AppTheme.glassBorder, width: 1.5),
                  titleTextStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 11,
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  getTitle: (index, _) {
                    final titles = ['N', 'P', 'K', 'pH', 'OC'];
                    return RadarChartTitle(text: titles[index]);
                  },
                  dataSets: [
                    // Optimal baseline
                    RadarDataSet(
                      fillColor: AppTheme.leafAccent.withOpacity(0.08),
                      borderColor: AppTheme.leafAccent.withOpacity(0.5),
                      entryRadius: 0,
                      dataEntries: const [
                        RadarEntry(value: 1.0),
                        RadarEntry(value: 1.0),
                        RadarEntry(value: 1.0),
                        RadarEntry(value: 1.0),
                        RadarEntry(value: 1.0),
                      ],
                    ),
                    // Actual
                    RadarDataSet(
                      fillColor: AppTheme.scoreColor(suitScore / 100).withOpacity(0.2),
                      borderColor: AppTheme.scoreColor(suitScore / 100),
                      entryRadius: 4,
                      borderWidth: 2,
                      dataEntries: [
                        RadarEntry(value: d.nitrogenScore),
                        RadarEntry(value: d.phosphorusScore),
                        RadarEntry(value: d.potassiumScore),
                        RadarEntry(value: d.phScore),
                        RadarEntry(value: d.organicCarbonScore),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Core parameters grid
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: local.translate('core_parameters')),
            ParamRow(label: local.locale == 'en' ? 'Nitrogen (N)' : 'नत्र (Nitrogen - N)', value: _formatParam(d.nitrogen, local), unit: d.nitrogen == 0.0 ? '' : 'kg/ha',
                score: d.nitrogenScore, icon: Icons.grass,
                tooltip: 'Optimal: ≥280 kg/ha/year. N is the most critical nutrient for mulberry leaf protein content (CSRTI Mysore).'),
            const Divider(color: AppTheme.glassBorder, height: 1),
            ParamRow(label: local.locale == 'en' ? 'Phosphorus (P)' : 'स्फुरद (Phosphorus - P)', value: _formatParam(d.phosphorus, local), unit: d.phosphorus == 0.0 ? '' : 'kg/ha',
                score: d.phosphorusScore, icon: Icons.grain,
                tooltip: 'Optimal: ≥60 kg/ha/year. P drives root development and leaf carbohydrate synthesis.'),
            const Divider(color: AppTheme.glassBorder, height: 1),
            ParamRow(label: local.locale == 'en' ? 'Potassium (K)' : 'पालाश (Potassium - K)', value: _formatParam(d.potassium, local), unit: d.potassium == 0.0 ? '' : 'kg/ha',
                score: d.potassiumScore, icon: Icons.blur_circular_outlined,
                tooltip: 'Optimal: ≥100 kg/ha/year. K regulates stomatal opening and water-use efficiency in mulberry.'),
            const Divider(color: AppTheme.glassBorder, height: 1),
            ParamRow(label: local.locale == 'en' ? 'pH Level' : 'सामू (pH) पातळी', value: _formatParam(d.pH, local), unit: '',
                score: d.phScore, icon: Icons.science_outlined,
                tooltip: 'Optimal: 6.5–6.8. Below 5.5 or above 8.0 causes severe nutrient lock-out for mulberry roots.'),
            const Divider(color: AppTheme.glassBorder, height: 1),
            ParamRow(label: local.locale == 'en' ? 'Moisture' : 'ओल (Moisture)', value: _formatParam(d.moisture, local), unit: d.moisture == 0.0 ? '' : '%',
                score: d.moisture > 0 ? (d.moisture / 30).clamp(0, 1) : 0.7,
                icon: Icons.water_drop_outlined),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Extended parameters (collapsible)
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _showExtended = !_showExtended),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Text(
                      local.translate('extended_parameters').toUpperCase(),
                      style: AppTheme.labelCaps(context).copyWith(color: AppTheme.textMuted),
                    ),
                    const Spacer(),
                    Icon(
                      _showExtended ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_showExtended) ...[
              if (d.electricalConductivity != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Electrical Conductivity' : 'विद्युत वाहकता (EC)',
                    value: _formatExtParam(d.electricalConductivity, local),
                    unit: _extParamHasData(d.electricalConductivity) ? 'dS/m' : '',
                    score: d.ecScore, icon: Icons.electric_bolt_outlined,
                    tooltip: 'Optimal: <0.5 dS/m. Above 1.0 = salt stress — mulberry roots highly sensitive (CSRTI).'),
              if (d.organicCarbon != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Organic Carbon' : 'सेंद्रिय कर्ब (OC)',
                    value: _formatExtParam(d.organicCarbon, local),
                    unit: _extParamHasData(d.organicCarbon) ? '%' : '',
                    score: d.organicCarbonScore, icon: Icons.eco_outlined,
                    tooltip: 'Optimal: ≥0.75%. Below 0.5% = long-term fertility risk. OC drives water retention and microbial life.'),
              if (d.zinc != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Zinc (Zn)' : 'जस्त (Zinc - Zn)',
                    value: _formatExtParam(d.zinc, local),
                    unit: _extParamHasData(d.zinc) ? 'mg/kg' : '',
                    score: _extParamHasData(d.zinc) ? (d.zinc! / 1.0).clamp(0, 1) : 0.3,
                    icon: Icons.circle_outlined,
                    tooltip: 'Critical threshold: <0.6 mg/kg = deficient. Zn affects silk thread quality (PMC 2022).'),
              if (d.iron != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Iron (Fe)' : 'लोह (Iron - Fe)',
                    value: _formatExtParam(d.iron, local),
                    unit: _extParamHasData(d.iron) ? 'mg/kg' : '',
                    score: _extParamHasData(d.iron) ? (d.iron! / 10.0).clamp(0, 1) : 0.3,
                    icon: Icons.circle_outlined,
                    tooltip: 'Critical: <4.5 mg/kg = deficient. Fe drives chlorophyll synthesis — low Fe = pale leaves with reduced protein.'),
              if (d.boron != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Boron (B)' : 'बोरॉन (Boron - B)',
                    value: _formatExtParam(d.boron, local),
                    unit: _extParamHasData(d.boron) ? 'mg/kg' : '',
                    score: _extParamHasData(d.boron) ? (d.boron! / 1.5).clamp(0, 1) : 0.3,
                    icon: Icons.circle_outlined),
              if (d.sulfur != null)
                ParamRow(
                    label: local.locale == 'en' ? 'Sulfur (S)' : 'गंधक (Sulfur - S)',
                    value: _formatExtParam(d.sulfur, local),
                    unit: _extParamHasData(d.sulfur) ? 'mg/kg' : '',
                    score: _extParamHasData(d.sulfur) ? (d.sulfur! / 15.0).clamp(0, 1) : 0.3,
                    icon: Icons.circle_outlined,
                    tooltip: 'Mulberry leaves require S for fibroin (silk protein) synthesis in silkworm silk glands.'),
              if (d.electricalConductivity == null && d.organicCarbon == null && d.zinc == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      local.locale == 'en' 
                          ? 'No extended parameters found on this card.\nEC, OC, and micronutrient sections were not present.'
                          : 'या पत्रकावर इतर घटक आढळले नाहीत.\nEC, OC आणि सूक्ष्म पोषक घटक विभाग उपलब्ध नव्हते.',
                      style: AppTheme.bodyMedium(context), textAlign: TextAlign.center),
                ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Manual correction form
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: local.translate('verify_correct_values')),
            Text(local.translate('correct_errors_sub'), style: AppTheme.bodyMedium(context)),
            const SizedBox(height: 12),
            _buildTextField(local.locale == 'en' ? 'N (kg/ha)' : 'नत्र - N (किग्रॅ/हेक्टर)', _nCtrl),
            _buildTextField(local.locale == 'en' ? 'P (kg/ha)' : 'स्फुरद - P (किग्रॅ/हेक्टर)', _pCtrl),
            _buildTextField(local.locale == 'en' ? 'K (kg/ha)' : 'पालाश - K (किग्रॅ/हेक्टर)', _kCtrl),
            _buildTextField(local.locale == 'en' ? 'pH' : 'सामू - pH', _phCtrl),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyManualCorrections,
                icon: const Icon(Icons.save_outlined),
                label: Text(local.translate('confirm_save_soil')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.earthBrown,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  String _getLocalizedPhLabel(AppLocalizations local, String phLabel) {
    if (local.locale == 'mr') {
      if (phLabel.contains('Highly Acidic')) return 'अति आम्लयुक्त (Highly Acidic)';
      if (phLabel.contains('Acidic')) return 'आम्लयुक्त (Acidic)';
      if (phLabel.contains('Slightly Acidic')) return 'अंशतः आम्लयुक्त (Slightly Acidic)';
      if (phLabel.contains('Optimal')) return 'आदर्श सामू (Optimal)';
      if (phLabel.contains('Slightly Alkaline')) return 'अंशतः अल्कलीयुक्त (Slightly Alkaline)';
      if (phLabel.contains('Alkaline')) return 'अल्कलीयुक्त (Alkaline)';
      if (phLabel.contains('Highly Alkaline')) return 'अति अल्कलीयुक्त (Highly Alkaline)';
    }
    return phLabel;
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.glassBorder),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppTheme.leafAccent),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          filled: true,
          fillColor: AppTheme.glassWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose(); _phCtrl.dispose();
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}
