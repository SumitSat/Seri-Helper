import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/tflite_service.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../theme/localization.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/score_gauge.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  final TFLiteService _tflite = TFLiteService();
  final ImagePicker   _picker = ImagePicker();

  File? _image;
  FoliarHealthResult? _result;
  bool _isLoading = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _tflite.initialize();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() { _image = File(picked.path); _isLoading = true; _result = null; });

    try {
      final result = await _tflite.classifyImage(_image!);
      HapticFeedback.mediumImpact();
      setState(() { _result = result; _isLoading = false; });
      // Auto-show leaf context sheet
      if (mounted) _showLeafContextSheet();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e'), backgroundColor: AppTheme.critical),
        );
      }
    }
  }

  void _showLeafContextSheet() {
    LeafPosition  pos     = LeafPosition.mixed;
    MulberryVariety variety = MulberryVariety.unknown;
    double        age     = 55.0;
    bool          isolated = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: AppTheme.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
            border: const Border(top: BorderSide(color: AppTheme.glassBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Refine Prediction', style: AppTheme.headline2(ctx)),
              Text('These 3 quick answers improve accuracy by up to 20%',
                  style: AppTheme.bodyMedium(ctx)),
              const SizedBox(height: 20),

              // Leaf Position
              Text('LEAF POSITION ON SHOOT', style: AppTheme.labelCaps(ctx)),
              const SizedBox(height: 8),
              ChipSelector<LeafPosition>(
                options: LeafPosition.values, selected: pos,
                label: (p) => switch(p) {
                  LeafPosition.top   => '🌱 Top (P2–P4)',
                  LeafPosition.mixed => '🍃 Mixed',
                  LeafPosition.basal => '🍂 Basal (P8+)',
                },
                onSelected: (p) => setSheet(() => pos = p),
              ),
              const SizedBox(height: 16),

              // Shoot Age
              Text('SHOOT AGE: ${age.round()} DAYS', style: AppTheme.labelCaps(ctx)),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (lCtx, constraints) {
                  // Clamp badge position so it never clips off the right edge
                  final double trackWidth = constraints.maxWidth - 40;
                  final double rawLeft = (age - 30) / 50 * trackWidth + 20;
                  final double clampedLeft = rawLeft.clamp(20.0, constraints.maxWidth - 80);
                  return Stack(
                    children: [
                      Slider(value: age, min: 30, max: 80, divisions: 50,
                          onChanged: (v) => setSheet(() => age = v)),
                      Positioned(
                        left: clampedLeft,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (age >= 55 && age <= 65) ? AppTheme.optimalLight : AppTheme.warning,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (age >= 55 && age <= 65) ? '✓ Optimal' : '⚠ Suboptimal',
                            style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Mulberry Variety
              Text('MULBERRY VARIETY', style: AppTheme.labelCaps(ctx)),
              const SizedBox(height: 8),
              ChipSelector<MulberryVariety>(
                options: MulberryVariety.values, selected: variety,
                label: (v) => switch(v) {
                  MulberryVariety.v1      => 'V1',
                  MulberryVariety.s13     => 'S13',
                  MulberryVariety.s36     => 'S36',
                  MulberryVariety.local   => 'Local',
                  MulberryVariety.unknown => 'Unknown',
                },
                onSelected: (v) => setSheet(() => variety = v),
              ),
              const SizedBox(height: 16),

              // Pesticide isolation toggle
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.warning_amber_outlined, color: AppTheme.warning, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Field Isolated from Pesticides?', style: AppTheme.bodyLarge(ctx).copyWith(fontSize: 14)),
                    Text('Adjacent pesticide use = major batch loss risk', style: AppTheme.bodyMedium(ctx).copyWith(fontSize: 11)),
                  ])),
                  Switch(value: isolated, onChanged: (v) => setSheet(() => isolated = v),
                      activeColor: AppTheme.leafAccent),
                ]),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final harvest = HarvestContext(
                      leafPosition: pos, shootAgeDays: age.round(),
                      variety: variety, isFieldIsolated: isolated,
                    );
                    if (_result != null) {
                      context.read<LeafScanProvider>().update(
                        foliar: _result!, harvest: harvest,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('SAVE & ADD TO PREDICTION'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  Text(local.translate('leaf_scanner_title'), style: AppTheme.headline2(context)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate_rounded, color: AppTheme.leafAccent),
                        onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                        tooltip: local.locale == 'en' ? 'मराठी' : 'English',
                      ),
                      const Icon(Icons.energy_savings_leaf, color: AppTheme.leafAccent, size: 28),
                    ],
                  ),
                ]),
                Text(local.translate('leaf_scanner_sub'), style: AppTheme.bodyMedium(context)),
                const SizedBox(height: 20),

                // Image preview
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    child: SizedBox(
                      height: 300,
                      child: _image != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_image!, fit: BoxFit.cover),
                                if (_isLoading)
                                  Container(
                                    color: Colors.black54,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(animation: _pulseAnim, builder: (_, __) =>
                                          Opacity(opacity: _pulseAnim.value,
                                            child: const Icon(Icons.scanner, color: AppTheme.leafAccent, size: 60)),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(local.locale == 'en' ? 'Analysing leaf...' : 'पानाचे विश्लेषण करत आहे...', style: AppTheme.bodyLarge(context)),
                                        const SizedBox(height: 12),
                                        const SizedBox(width: 120, child: LinearProgressIndicator(
                                          color: AppTheme.leafAccent, backgroundColor: AppTheme.glassWhite)),
                                      ],
                                    ),
                                  ),
                              ],
                            )
                          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.energy_savings_leaf, size: 72, color: AppTheme.leafAccent.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(local.translate('capture_leaf'), style: AppTheme.bodyLarge(context)),
                              Text(local.translate('daylight_tip'), style: AppTheme.bodyMedium(context)),
                            ]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(children: [
                  Expanded(child: _ActionButton(
                    icon: Icons.camera_alt_rounded, label: local.translate('camera'),
                    gradient: AppTheme.leafGradient,
                    onTap: () => _pickImage(ImageSource.camera),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionButton(
                    icon: Icons.photo_library_rounded, label: local.translate('gallery'),
                    gradient: AppTheme.leafGradient,
                    onTap: () => _pickImage(ImageSource.gallery),
                  )),
                ]),
                const SizedBox(height: 28),

                // Result card
                if (_result != null && !_isLoading) _buildResultCard(context, local, _result!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, AppLocalizations local, FoliarHealthResult r) {
    final Color gradeColor = switch (r.grade) {
      LeafGrade.excellent => AppTheme.optimalLight,
      LeafGrade.medium    => AppTheme.warning,
      LeafGrade.poor      => AppTheme.criticalLight,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: local.translate('foliar_report')),

        // Hero: gauge + grade pill
        GlassCard(
          child: Row(
            children: [
              ScoreGauge(score: r.foliarHealthIndex, label: 'FHI', sublabel: local.locale == 'en' ? 'Score' : 'गुण', size: 120),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: gradeColor.withOpacity(0.5)),
                      ),
                      child: Text(_getLocalizedGradeLabel(local, r.grade),
                          style: TextStyle(color: gradeColor, fontWeight: FontWeight.w800,
                              letterSpacing: 1.2, fontSize: 14)),
                    ),
                    const SizedBox(height: 12),
                    Text(local.locale == 'en' ? r.rawLabel : _getLocalizedDiseaseLabel(r.rawLabel), style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(local.locale == 'en' 
                        ? '${(r.confidence * 100).toStringAsFixed(1)}% confidence'
                        : '${(r.confidence * 100).toStringAsFixed(1)}% विश्वासार्हता',
                        style: AppTheme.labelSmall(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3-column stat row
        GlassCard(
          child: Row(
            children: [
              _StatCell(label: local.translate('necrotic_area'), value: '${r.estimatedNecroticAreaPercent.toStringAsFixed(1)}%'),
              _divider(),
              _StatCell(label: local.translate('feed_suitability'), value: '${r.feedingSuitabilityPercent.toStringAsFixed(0)}%'),
              _divider(),
              _StatCell(label: local.translate('moisture_proxy'), value: '${(r.moistureProxy * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Description + recommendation
        GlassCard(
          borderColor: gradeColor.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getLocalizedDescription(local, r.grade, r.rawLabel), style: AppTheme.bodyMedium(context), textAlign: TextAlign.left),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(children: [
                  Icon(Icons.lightbulb_outline, color: gradeColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_getLocalizedRecommendation(local, r.grade),
                      style: AppTheme.bodyMedium(context).copyWith(color: gradeColor, fontWeight: FontWeight.w600))),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Provider status
        Consumer<LeafScanProvider>(builder: (_, p, __) =>
          p.hasData
            ? GlassCard(
                borderColor: AppTheme.optimalLight.withOpacity(0.4),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppTheme.optimalLight, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(local.translate('leaf_saved_alert'),
                        style: AppTheme.bodyMedium(context).copyWith(color: AppTheme.optimalLight)),
                  ),
                ]),
              )
            : const SizedBox.shrink(),
        ),
      ],
    );
  }

  String _getLocalizedGradeLabel(AppLocalizations local, LeafGrade grade) {
    return switch (grade) {
      LeafGrade.excellent => local.locale == 'mr' ? 'उत्कृष्ट' : 'EXCELLENT',
      LeafGrade.medium => local.locale == 'mr' ? 'मध्यम' : 'MEDIUM',
      LeafGrade.poor => local.locale == 'mr' ? 'खराब' : 'POOR',
    };
  }

  String _getLocalizedDiseaseLabel(String rawLabel) {
    final lower = rawLabel.toLowerCase();
    if (lower.contains('rust')) return 'तांबेरा रोग (Red Rust)';
    if (lower.contains('spot')) return 'टिपका रोग (Leaf Spot)';
    if (lower.contains('mildew')) return 'भुरी रोग (Powdery Mildew)';
    if (lower.contains('healthy') || lower.contains('disease free')) return 'रोगमुक्त पान';
    return rawLabel;
  }

  String _getLocalizedDescription(AppLocalizations local, LeafGrade grade, String rawLabel) {
    if (local.locale == 'mr') {
      return switch (grade) {
        LeafGrade.excellent => 'पान पूर्णपणे निरोगी आहे. रेशीम कीटकांच्या खाद्यासाठी प्रथिनांचे आणि पाण्याचे प्रमाण सर्वोत्तम आहे.',
        LeafGrade.medium => 'पान निरोगी दिसत आहे परंतु मॉडेलचा आत्मविश्वास मध्यम आहे. हलकी सुकलेली किंवा सुरुवातीच्या ताणाची शक्यता आहे.',
        LeafGrade.poor => 'रोग आढळला: ${_getLocalizedDiseaseLabel(rawLabel)}. ही पाने दिल्यास रोगाचा संसर्ग (ग्रॅसेरी/फ्लॅचेरी) होण्याचा धोका वाढतो.',
      };
    } else {
      return switch (grade) {
        LeafGrade.excellent => 'Leaf is fully healthy. Protein and moisture levels are optimal for silkworm feeding.',
        LeafGrade.medium => 'Leaf appears healthy but model confidence is moderate. Possible early-stage stress or slight wilting.',
        LeafGrade.poor => 'Pathogen detected: $rawLabel. Feeding these leaves risks disease transmission (Grasserie/Flacherie).',
      };
    }
  }

  String _getLocalizedRecommendation(AppLocalizations local, LeafGrade grade) {
    if (local.locale == 'mr') {
      return switch (grade) {
        LeafGrade.excellent => 'खाद्य देण्यासाठी सुरक्षित. उत्तम कोश वजनासाठी शेंड्याची पाने द्या.',
        LeafGrade.medium => 'फक्त ४ थ्या आणि ५ व्या अवस्थेतील कीटकांना द्या. लहान कीटकांना देण्यापूर्वी स्वतः खात्री करा.',
        LeafGrade.poor => 'तात्काळ फेकून द्या. औषध फवारणी करा आणि रेशीम कीटकांना हे खाद्य देऊ नका.',
      };
    } else {
      return switch (grade) {
        LeafGrade.excellent => 'Safe to feed. Prioritise top-shoot leaves for best cocoon shell weight.',
        LeafGrade.medium => 'Feed to 4th–5th instar worms only. Inspect manually before use with young larvae.',
        LeafGrade.poor => 'DISCARD immediately. Sanitise the harvested area with bleaching powder. Do not feed to silkworms.',
      };
    }
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppTheme.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 8));

  @override
  void dispose() { _tflite.dispose(); _pulseCtrl.dispose(); super.dispose(); }
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.glowShadow,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTheme.numericMed(context).copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.labelSmall(context), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
