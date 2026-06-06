import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/localization.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/score_gauge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _getLocalizedBreed(AppLocalizations local, String breedName) {
    return switch (breedName) {
      'bivoltineCSR' => local.locale == 'mr' ? 'सीएसआर बायव्होल्टाइन' : 'CSR Bivoltine',
      'multivoltineCross' => local.locale == 'mr' ? 'मल्टीव्होल्टाइन क्रॉस' : 'Multivoltine ×',
      'pureMultivoltine' => local.locale == 'mr' ? 'शुद्ध मल्टिव्होल्टाइन' : 'Pure Multivoltine',
      _ => breedName,
    };
  }

  String _getLocalizedSeason(AppLocalizations local, String seasonName) {
    return switch (seasonName) {
      'spring' => local.locale == 'mr' ? '🌸 वसंत (Spring)' : '🌸 Spring',
      'summer' => local.locale == 'mr' ? '☀️ उन्हाळा (Summer)' : '☀️ Summer',
      'monsoon' => local.locale == 'mr' ? '🌧 पावसाळा (Monsoon)' : '🌧 Monsoon',
      'winter' => local.locale == 'mr' ? '❄️ हिवाळा (Winter)' : '❄️ Winter',
      _ => seasonName,
    };
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(local.translate('batch_history'), style: AppTheme.headline2(context)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.translate_rounded, color: AppTheme.leafAccent),
                          onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                          tooltip: local.locale == 'en' ? 'मराठी' : 'English',
                        ),
                        const Icon(Icons.history_rounded, color: AppTheme.leafAccent, size: 28),
                      ],
                    ),
                  ],
                ),
              ),

              // Firestore list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('yield_reports_v2').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.leafAccent));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          local.locale == 'en' ? 'Error loading history: ${snapshot.error}' : 'इतिहास उघडण्यात चूक झाली: ${snapshot.error}',
                          style: TextStyle(color: AppTheme.criticalLight),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 80, color: AppTheme.textMuted.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(
                                local.locale == 'en' ? 'No Reports Yet' : 'अद्याप कोणताही अहवाल नाही',
                                style: AppTheme.headline3(context),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                local.translate('empty_history'),
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final double expectedYield = (data['yieldKgPer100DFLs'] as num?)?.toDouble() ?? 0.0;
                        final double efficiency = (data['overallEfficiencyPercent'] as num?)?.toDouble() ?? 0.0;
                        final String limitingFactor = data['limitingFactor'] ?? 'None';
                        final String breed = data['breed'] ?? 'unknown';
                        final String season = data['season'] ?? 'unknown';

                        final double fqi = (data['fqi'] as num?)?.toDouble() ?? 0.0;
                        final double cci = (data['cci'] as num?)?.toDouble() ?? 0.0;
                        final double shi = (data['shi'] as num?)?.toDouble() ?? 0.0;
                        final double dPenalty = (data['dPenalty'] as num?)?.toDouble() ?? 1.0;
                        final double bmFactor = (data['bmFactor'] as num?)?.toDouble() ?? 1.0;

                        final Timestamp? ts = data['timestamp'] as Timestamp?;
                        final DateTime date = ts != null ? ts.toDate() : DateTime.now();

                        final Color statusColor = expectedYield >= 50
                            ? AppTheme.optimalLight
                            : expectedYield >= 35
                                ? AppTheme.warning
                                : AppTheme.criticalLight;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          // Premium Expandable GlassCard
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Icon(
                                    expectedYield >= 50
                                        ? Icons.trending_up_rounded
                                        : expectedYield >= 35
                                            ? Icons.trending_flat_rounded
                                            : Icons.trending_down_rounded,
                                    color: statusColor,
                                  ),
                                ),
                                title: Text(
                                  '${expectedYield.toStringAsFixed(1)} ${local.locale == 'en' ? 'kg' : 'किग्रॅ'}',
                                  style: AppTheme.headline3(context).copyWith(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  _formatDate(date),
                                  style: AppTheme.labelSmall(context),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    border: Border.all(color: statusColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    '${efficiency.toStringAsFixed(0)}%',
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                children: [
                                  const Divider(color: AppTheme.glassBorder, height: 20),
                                  
                                  // Details Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${local.translate('breed')} ${_getLocalizedBreed(local, breed)}',
                                        style: AppTheme.bodyMedium(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        _getLocalizedSeason(local, season),
                                        style: AppTheme.bodyMedium(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // 5-Factor values
                                  _buildFactorRow(context, local.translate('foliage_quality'), fqi),
                                  _buildFactorRow(context, local.translate('climate_comp'), cci),
                                  _buildFactorRow(context, local.translate('soil_nutri'), shi),
                                  _buildFactorRow(context, local.translate('disease_risk'), dPenalty, true),
                                  _buildFactorRow(context, local.translate('mgmt_multiplier'), bmFactor, true),
                                  const SizedBox(height: 16),

                                  // Bottleneck advice
                                  if (limitingFactor != 'None') ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${local.translate('primary_bottleneck')}${_getLocalizedLimitingFactor(local, limitingFactor)}',
                                                style: AppTheme.bodyLarge(context).copyWith(
                                                  color: AppTheme.warning,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _getLocalizedRecommendation(local, limitingFactor),
                                            style: AppTheme.bodyMedium(context).copyWith(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactorRow(BuildContext context, String label, double score, [bool isMultiplier = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTheme.labelSmall(context).copyWith(color: AppTheme.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: MiniScoreBar(score: isMultiplier ? score.clamp(0.0, 1.0) : score),
          ),
          const SizedBox(width: 12),
          Text(
            isMultiplier ? '${score.toStringAsFixed(2)}x' : '${(score * 100).toStringAsFixed(0)}%',
            style: AppTheme.bodyLarge(context).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
