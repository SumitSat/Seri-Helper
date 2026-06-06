import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import 'package:provider/provider.dart';
import '../widgets/shared_widgets.dart';

/// Batch Configuration Screen — collects the full RearingContext from the farmer
/// before any yield prediction is run. Uses premium card-based UI with ChipSelectors.
class BatchConfigScreen extends StatefulWidget {
  const BatchConfigScreen({Key? key}) : super(key: key);

  @override
  State<BatchConfigScreen> createState() => _BatchConfigScreenState();
}

class _BatchConfigScreenState extends State<BatchConfigScreen> {
  RearingSeason _season       = RearingSeason.spring;
  SilkwormBreed _breed        = SilkwormBreed.bivoltineCSR;
  HygieneLevel  _hygiene      = HygieneLevel.full;
  FertilizationMethod _fert   = FertilizationMethod.basalOnly;
  DflSource     _dflSource    = DflSource.governmentCertified;
  PesticideRisk _pesticide    = PesticideRisk.none;
  VentilationQuality _vent    = VentilationQuality.moderate;
  double _feedFreq            = 3;

  void _confirm() {
    final ctx = RearingContext(
      season: _season, breed: _breed, hygieneLevel: _hygiene,
      fertilizationMethod: _fert, dflSource: _dflSource,
      pesticideRisk: _pesticide, ventilation: _vent,
      feedingFrequencyPerDay: _feedFreq.round(),
    );
    context.read<RearingContextProvider>().update(ctx);
    // Capture messenger BEFORE pop so context is still valid in the widget tree
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('✅ Batch configured successfully'),
        backgroundColor: AppTheme.optimal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── HEADER ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: const BoxDecoration(
                  gradient: AppTheme.leafGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text('Configure Batch', style: AppTheme.headline2(context),
                              textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Set rearing conditions once per batch for accurate yield prediction',
                        style: AppTheme.bodyMedium(context), textAlign: TextAlign.center),
                  ],
                ),
              ),

              // ── FORM ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Season
                      _buildSection(
                        context,
                        icon: Icons.wb_sunny_outlined,
                        title: 'Rearing Season',
                        subtitle: 'Affects disease risk and leaf quality',
                        child: ChipSelector<RearingSeason>(
                          options: RearingSeason.values,
                          selected: _season,
                          label: (s) => _seasonLabel(s),
                          onSelected: (s) => setState(() => _season = s),
                        ),
                      ),

                      // Breed
                      _buildSection(
                        context,
                        icon: Icons.biotech_outlined,
                        title: 'Silkworm Breed',
                        subtitle: 'Biggest genetic lever for cocoon yield',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChipSelector<SilkwormBreed>(
                              options: SilkwormBreed.values,
                              selected: _breed,
                              label: (b) => _breedLabel(b),
                              onSelected: (b) => setState(() => _breed = b),
                            ),
                            const SizedBox(height: 8),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              borderRadius: AppTheme.radiusMd,
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 14, color: AppTheme.leafAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'CSR Bivoltine yields 4.68× more than wild strains (PMC 2020)',
                                      style: AppTheme.bodyMedium(context).copyWith(fontSize: 12, color: AppTheme.leafAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Hygiene
                      _buildSection(
                        context,
                        icon: Icons.clean_hands_outlined,
                        title: 'Hygiene Protocol',
                        subtitle: 'Disinfection prevents 15–47% crop loss',
                        child: ChipSelector<HygieneLevel>(
                          options: HygieneLevel.values,
                          selected: _hygiene,
                          label: (h) => _hygieneLabel(h),
                          onSelected: (h) => setState(() => _hygiene = h),
                        ),
                      ),

                      // Fertilization
                      _buildSection(
                        context,
                        icon: Icons.grass_outlined,
                        title: 'Fertilization Method',
                        subtitle: 'Foliar spray alone adds +52.8% yield (BSTRI)',
                        child: ChipSelector<FertilizationMethod>(
                          options: FertilizationMethod.values,
                          selected: _fert,
                          label: (f) => _fertLabel(f),
                          onSelected: (f) => setState(() => _fert = f),
                        ),
                      ),

                      // DFL Source
                      _buildSection(
                        context,
                        icon: Icons.verified_outlined,
                        title: 'DFL (Egg) Source',
                        subtitle: 'Uncertified eggs carry up to 36% Pebrine risk',
                        child: ChipSelector<DflSource>(
                          options: DflSource.values,
                          selected: _dflSource,
                          label: (d) => d == DflSource.governmentCertified ? 'Govt. Certified' : 'Uncertified',
                          onSelected: (d) => setState(() => _dflSource = d),
                          selectedColor: _dflSource == DflSource.uncertified ? AppTheme.warning : AppTheme.leafAccent,
                        ),
                      ),

                      // Pesticide Risk + Ventilation side by side
                      Row(
                        children: [
                          Expanded(
                            child: _buildSection(
                              context,
                              icon: Icons.warning_amber_outlined,
                              title: 'Pesticide Risk',
                              subtitle: 'Adjacent farm',
                              child: ChipSelector<PesticideRisk>(
                                options: PesticideRisk.values,
                                selected: _pesticide,
                                label: (p) => p == PesticideRisk.none ? 'None' : 'Present',
                                onSelected: (p) => setState(() => _pesticide = p),
                                selectedColor: _pesticide == PesticideRisk.present ? AppTheme.critical : AppTheme.leafAccent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSection(
                              context,
                              icon: Icons.air_outlined,
                              title: 'Ventilation',
                              subtitle: 'Rearing house',
                              child: ChipSelector<VentilationQuality>(
                                options: VentilationQuality.values,
                                selected: _vent,
                                label: (v) => _ventLabel(v),
                                onSelected: (v) => setState(() => _vent = v),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Feeding Frequency
                      _buildSection(
                        context,
                        icon: Icons.restaurant_outlined,
                        title: 'Feeding Frequency',
                        subtitle: 'Optimal: 4/day in 5th instar (FAO)',
                        child: Column(
                          children: [
                            Slider(
                              value: _feedFreq,
                              min: 1, max: 5, divisions: 4,
                              label: '${_feedFreq.round()}/day',
                              onChanged: (v) => setState(() => _feedFreq = v),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: ['1', '2', '3', '4', '5']
                                  .map((l) => Text(l, style: AppTheme.labelSmall(context)))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _feedFreq >= 4 ? '✅ Optimal frequency' : '⚠ Below optimal for 5th instar',
                              style: AppTheme.bodyMedium(context).copyWith(
                                color: _feedFreq >= 4 ? AppTheme.optimalLight : AppTheme.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Confirm Button
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('CONFIRM BATCH SETUP'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required IconData icon, required String title,
      required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: AppTheme.leafAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headline3(context).copyWith(fontSize: 15)),
                  Text(subtitle, style: AppTheme.bodyMedium(context).copyWith(fontSize: 12)),
                ],
              )),
            ]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // Label helpers
  String _seasonLabel(RearingSeason s) => switch (s) {
    RearingSeason.spring  => '🌸 Spring',
    RearingSeason.summer  => '☀️ Summer',
    RearingSeason.monsoon => '🌧 Monsoon',
    RearingSeason.winter  => '❄️ Winter',
  };
  String _breedLabel(SilkwormBreed b) => switch (b) {
    SilkwormBreed.bivoltineCSR      => 'CSR Bivoltine',
    SilkwormBreed.multivoltineCross => 'Multivoltine ×',
    SilkwormBreed.pureMultivoltine  => 'Pure Multivoltine',
  };
  String _hygieneLabel(HygieneLevel h) => switch (h) {
    HygieneLevel.full    => '✅ Full',
    HygieneLevel.partial => '⚠ Partial',
    HygieneLevel.none    => '❌ None',
  };
  String _fertLabel(FertilizationMethod f) => switch (f) {
    FertilizationMethod.foliarPlusBasal => 'Foliar + Basal',
    FertilizationMethod.basalOnly       => 'Basal Only',
    FertilizationMethod.none            => 'None',
  };
  String _ventLabel(VentilationQuality v) => switch (v) {
    VentilationQuality.good     => 'Good',
    VentilationQuality.moderate => 'Moderate',
    VentilationQuality.poor     => 'Poor',
  };
}
