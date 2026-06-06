import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../services/yield_engine_v2.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../theme/localization.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/score_gauge.dart';
import 'batch_config_screen.dart';

class YieldDashboard extends StatefulWidget {
  const YieldDashboard({Key? key}) : super(key: key);

  @override
  State<YieldDashboard> createState() => _YieldDashboardState();
}

class _YieldDashboardState extends State<YieldDashboard> with TickerProviderStateMixin {
  final YieldEngineV2 _engine = YieldEngineV2();
  final WeatherService _weatherService = WeatherService();
  
  // Real-time climate inputs
  double _temp = 25.0;
  double _humidity = 80.0;
  
  bool _isSaving = false;
  bool _isFetchingWeather = false;

  void _openBatchConfig() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BatchConfigScreen()));
  }

  Future<void> _fetchWeather() async {
    setState(() => _isFetchingWeather = true);
    try {
      final data = await _weatherService.fetchLocalWeather();
      setState(() {
        _temp = data['temp']!;
        _humidity = data['humidity']!;
      });
      if (mounted) {
        final local = AppLocalizations.of(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.locale == 'en' ? '🌤 Weather updated successfully' : '🌤 हवामानाची माहिती अपडेट झाली'),
            backgroundColor: AppTheme.optimal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final local = AppLocalizations.of(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${local.translate('weather_error')}$e'),
            backgroundColor: AppTheme.critical,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingWeather = false);
    }
  }

  Future<void> _saveReport(YieldResultV2 result, RearingContext rearing, SoilData soil, LeafScanProvider leaf) async {
    setState(() => _isSaving = true);
    try {
      await _engine.saveReportToFirebase(
        result: result,
        rearing: rearing,
        soil: soil,
      );
      if (mounted) {
        final local = AppLocalizations.of(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(local.translate('confirm_save')),
            backgroundColor: AppTheme.optimal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.warning),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getLocalizedLimitingFactor(AppLocalizations local, String factor) {
    return switch (factor) {
      'Foliage Quality' => local.translate('foliage_quality'),
      'Climate Conditions' => local.translate('climate_comp'),
      'Soil Nutrition' => local.translate('soil_nutri'),
      'Disease Risk' => local.translate('disease_risk'),
      'Breed & Management' => local.translate('mgmt_multiplier'),
      _ => factor,
    };
  }

  String _getLocalizedRecommendation(AppLocalizations local, String factor) {
    return switch (factor) {
      'Foliage Quality' => local.translate('reco_foliage'),
      'Climate Conditions' => local.translate('reco_climate'),
      'Soil Nutrition' => local.translate('reco_soil'),
      'Disease Risk' => local.translate('reco_disease'),
      'Breed & Management' => local.translate('reco_breed'),
      _ => local.translate('reco_default'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    
    // Watch all 3 state providers
    final rearingProv = context.watch<RearingContextProvider>();
    final leafProv = context.watch<LeafScanProvider>();
    final soilProv = context.watch<SoilDataProvider>();

    // Calculate yield if all baseline data is present
    YieldResultV2? result;
    if (rearingProv.isConfigured && leafProv.hasData && soilProv.hasData) {
      result = _engine.calculate(
        rearing: rearingProv.context,
        harvest: leafProv.harvestContext!,
        foliarResult: leafProv.foliarResult!,
        soil: soilProv.soilData!,
        temperatureC: _temp,
        humidityPct: _humidity,
      );
    }

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
                  Text(local.translate('dashboard'), style: AppTheme.headline2(context)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.translate_rounded, color: AppTheme.leafAccent),
                        onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                        tooltip: local.locale == 'en' ? 'मराठी' : 'English',
                      ),
                      const Icon(Icons.dashboard_rounded, color: AppTheme.leafAccent, size: 28),
                    ],
                  ),
                ]),
                Text(local.translate('v2_subtitle'), style: AppTheme.bodyMedium(context)),
                const SizedBox(height: 24),

                // Data completeness tracker
                _buildCompletenessTracker(local, rearingProv.isConfigured, leafProv.hasData, soilProv.hasData),
                const SizedBox(height: 16),
                
                // Inline Config Batch Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBatchConfig,
                    icon: const Icon(Icons.settings),
                    label: Text(local.translate('config_batch_btn')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rearingProv.isConfigured ? AppTheme.glassWhite : AppTheme.leafAccent,
                      foregroundColor: rearingProv.isConfigured ? AppTheme.textSecondary : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                      elevation: rearingProv.isConfigured ? 0 : 4,
                      side: rearingProv.isConfigured ? const BorderSide(color: AppTheme.glassBorder) : BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Live Climate Inputs
                SectionHeader(
                  title: local.translate('real_time_climate'),
                  trailing: TextButton.icon(
                    onPressed: _isFetchingWeather ? null : _fetchWeather,
                    icon: _isFetchingWeather 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.leafAccent))
                        : const Icon(Icons.gps_fixed, size: 14, color: AppTheme.leafAccent),
                    label: Text(
                      local.translate('get_live_weather'),
                      style: const TextStyle(fontSize: 12, color: AppTheme.leafAccent),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: AppTheme.glassWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _buildClimateCard(local.translate('temp_slider'), _temp, '°C', 'Optimal: 24-26', (v) => setState(() => _temp = v), 15, 35)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildClimateCard(local.translate('humid_slider'), _humidity, '%', 'Optimal: 75-85', (v) => setState(() => _humidity = v), 40, 100)),
                  ],
                ),
                const SizedBox(height: 24),

                if (result != null) ...[
                  // Hero Yield Card
                  SectionHeader(title: local.translate('harvest_forecast')),
                  _buildHeroYieldCard(local, result),
                  const SizedBox(height: 12),

                  // Bottleneck Warning Card
                  if (result.limitingFactor != 'None')
                    GlassCard(
                      borderColor: AppTheme.critical.withOpacity(0.5),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${local.translate('primary_bottleneck')}${_getLocalizedLimitingFactor(local, result.limitingFactor)}', 
                                    style: AppTheme.headline3(context).copyWith(color: AppTheme.warning, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text(_getLocalizedRecommendation(local, result.limitingFactor), style: AppTheme.bodyMedium(context).copyWith(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // 5-Factor Breakdown
                  SectionHeader(title: local.translate('five_factor_breakdown')),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFactorCard(local.translate('foliage_quality'), result.fqi, 'FQI'),
                        _buildFactorCard(local.translate('climate_comp'), result.cci, 'CCI'),
                        _buildFactorCard(local.translate('soil_nutri'), result.shi, 'SHI'),
                        _buildFactorCard(local.translate('disease_risk'), result.dPenalty, 'D-Penalty', true), // higher = better multiplier
                        _buildFactorCard(local.translate('mgmt_multiplier'), result.bmFactor, 'BM-Factor'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : () => _saveReport(result!, rearingProv.context, soilProv.soilData!, leafProv),
                      icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                      label: Text(_isSaving ? local.translate('saving') : local.translate('save_to_history')),
                    ),
                  ),
                  const SizedBox(height: 60), // Space for FAB
                ] else ...[
                  // Missing data placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.query_stats, size: 60, color: AppTheme.textMuted.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(local.translate('awaiting_data'), style: AppTheme.headline3(context).copyWith(color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Text(local.translate('awaiting_data_sub'),
                              textAlign: TextAlign.center, style: AppTheme.bodyMedium(context)),
                        ],
                      ),
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletenessTracker(AppLocalizations local, bool config, bool leaf, bool soil) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TrackerStep(label: local.translate('config_batch_btn'), done: config, icon: Icons.settings),
          _TrackerLine(done: config && leaf),
          _TrackerStep(label: local.translate('leaf_scan'), done: leaf, icon: Icons.energy_savings_leaf),
          _TrackerLine(done: leaf && soil),
          _TrackerStep(label: local.translate('soil_scan'), done: soil, icon: Icons.landscape),
        ],
      ),
    );
  }

  Widget _buildClimateCard(String label, double val, String unit, String sub, Function(double) onChanged, double min, double max) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: AppTheme.labelCaps(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(val.toStringAsFixed(1), style: AppTheme.numericMed(context)),
              Text(unit, style: AppTheme.labelSmall(context)),
            ],
          ),
          Slider(
            value: val,
            min: min, max: max,
            onChanged: onChanged,
          ),
          Text(sub, style: AppTheme.labelSmall(context).copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildHeroYieldCard(AppLocalizations local, YieldResultV2 res) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.yieldGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(local.translate('expected_yield'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(res.yieldKgPer100DFLs.toStringAsFixed(1), style: AppTheme.numericHero(context)),
              const SizedBox(width: 8),
              Text(local.translate('kg_100_dfls'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Text('${local.translate('yield_range')}${res.yieldLow.toStringAsFixed(1)} - ${res.yieldHigh.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(local.translate('efficiency_base'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 4),
                    MiniScoreBar(score: res.baseScore),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Text('${(res.baseScore * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFactorCard(String title, double score, String code, [bool isMultiplier = false]) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(code, style: AppTheme.labelCaps(context).copyWith(color: AppTheme.leafAccent)),
            const SizedBox(height: 4),
            Text(title, style: AppTheme.bodyMedium(context).copyWith(fontSize: 12, height: 1.2)),
            const SizedBox(height: 8),
            Text(
              isMultiplier ? '${score.toStringAsFixed(2)}x' : '${(score * 100).toStringAsFixed(0)}%',
              style: AppTheme.headline3(context),
            ),
            const SizedBox(height: 4),
            MiniScoreBar(score: isMultiplier ? score.clamp(0.0, 1.0) : score),
          ],
        ),
      ),
    );
  }
}

class _TrackerStep extends StatelessWidget {
  final String label;
  final bool done;
  final IconData icon;
  const _TrackerStep({required this.label, required this.done, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: done ? AppTheme.optimal : AppTheme.glassWhite,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: done ? Colors.white : AppTheme.textMuted, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTheme.labelSmall(context).copyWith(color: done ? AppTheme.optimalLight : AppTheme.textMuted)),
      ],
    );
  }
}

class _TrackerLine extends StatelessWidget {
  final bool done;
  const _TrackerLine({required this.done});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: done ? AppTheme.optimal : AppTheme.glassWhite,
      ),
    );
  }
}
