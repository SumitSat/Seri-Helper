import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/localization.dart';
import '../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single FAQ entry
// ─────────────────────────────────────────────────────────────────────────────
class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry({required this.question, required this.answer});
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_FaqEntry> entries;
  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.entries,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ Screen
// ─────────────────────────────────────────────────────────────────────────────
class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  int _selectedCategory = 0;

  static const List<_FaqCategory> _categories = [
    _FaqCategory(
      title: 'Mulberry & Leaf',
      icon: Icons.energy_savings_leaf_outlined,
      color: AppTheme.optimalLight,
      entries: [
        _FaqEntry(
          question: 'What does "Shoot Age (in days)" mean?',
          answer:
              'Mulberry plants are regularly pruned to encourage fresh branch growth. Shoot Age is the number of days since that last pruning.\n\n'
              '• Young shoots (e.g. 30 days): Very high moisture and protein, but low leaf weight/biomass.\n'
              '• Older shoots (e.g. 70 days): Thick, heavy leaves rich in carbohydrates but lower moisture.\n\n'
              'The app uses this age to accurately calculate the true nutritional value of the leaf you scanned. The optimal window is 55–65 days post-pruning.',
        ),
        _FaqEntry(
          question: 'What is "Leaf Position" and what do P2–P4 or P8+ mean?',
          answer:
              'The "P" stands for Position — counting leaves from the top tip of the branch downwards.\n\n'
              '• P1–P4 (Top/Tender): Youngest, softest leaves. High moisture and protein. Only suitable for baby "chawki" worms (1st–2nd instar).\n'
              '• P5–P7 (Middle): Medium mature leaves suitable for 3rd–4th instar worms.\n'
              '• P8+ (Basal): Older, thicker, carbohydrate-rich leaves. Required for mature 5th instar worms before they spin cocoons.\n\n'
              'Feeding tough P8 leaves to baby worms causes starvation. The app checks this to calculate your Foliage Quality Index (FQI).',
        ),
        _FaqEntry(
          question: 'Why does the AI model give a confidence percentage?',
          answer:
              'The leaf scanner uses an EfficientNetB0 deep learning model trained to classify: Disease Free leaves, Leaf Rust, Leaf Spot, and Powdery Mildew.\n\n'
              'Confidence is how certain the model is about its classification (0–100%). A high-confidence "Healthy" result gives grade Excellent. A result below 80% confidence gives grade Medium, meaning you should inspect the leaf manually before feeding it to young larvae.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Silkworm & Yield',
      icon: Icons.bug_report_outlined,
      color: AppTheme.warning,
      entries: [
        _FaqEntry(
          question: 'What does "DFLs" stand for? (e.g. 60 kg / 100 DFLs)',
          answer:
              'DFL stands for Disease Free Layings.\n\n'
              'In sericulture, farmers buy egg clusters, not individual silkworms. One "laying" is the group of eggs (400–500) laid by one female moth. "Disease Free" means the supplier has microscopically tested the mother moth for deadly diseases like Pébrine.\n\n'
              '"60 kg / 100 DFLs" is the universal industry efficiency metric — it means: for every 100 egg clusters reared, you harvested 60 kilograms of raw silk cocoons.',
        ),
        _FaqEntry(
          question: 'Why does yield change when I move the Temperature & Humidity sliders?',
          answer:
              'Silkworms are cold-blooded insects extremely sensitive to micro-climate. The Yield Engine uses a Climate Conditions Index (CCI):\n\n'
              '• Temperature sweet spot: 24°C – 26°C. Above 30°C causes heat stress, reduces appetite, and makes worms vulnerable to Grasserie virus. Below 18°C slows development critically.\n'
              '• Humidity sweet spot: 75% – 85%. Too dry (<65%) causes mulberry leaves to wilt before worms can eat them. Too wet (>94%) triggers Muscardine fungal outbreaks.\n\n'
              'The sliders let you simulate "what if" scenarios — seeing exactly how many kilograms you lose by not controlling your rearing house climate.',
        ),
        _FaqEntry(
          question: 'What is the "Config Batch" button?',
          answer:
              'Config Batch collects key parameters about your current silkworm batch before yield prediction can run:\n\n'
              '• Silkworm Breed: CSR Bivoltine yields 4.68× more than unimproved multivoltine strains.\n'
              '• Hygiene & Disinfection: Proper bed disinfection (Formalin/Labex) prevents 15–47% crop loss.\n'
              '• Fertilization Method: Combined foliar + basal NPK spray adds +52.8% cocoon yield.\n'
              '• DFL Source, Ventilation, Feeding Frequency.\n\n'
              'These generate your BM-Factor (Breed & Management Multiplier), which heavily influences the final cocoon weight calculation.',
        ),
        _FaqEntry(
          question: 'Why does the breed choice matter so much?',
          answer:
              'Silkworm breed is the single largest genetic lever for yield. Research (PMC 2020) documented that domestic CSR Bivoltine hybrids produce a cocoon shell weight 4.68× higher than unimproved wild strains under identical rearing conditions.\n\n'
              'CSR breeds also produce longer, finer filaments, meaning better quality raw silk and higher market prices per kilogram. Pure multivoltine breeds are hardier across seasons but significantly lower in output.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Soil & Scanning',
      icon: Icons.landscape_outlined,
      color: AppTheme.earthBrown,
      entries: [
        _FaqEntry(
          question: 'Why does the app say "Data not available" for some soil nutrients?',
          answer:
              'When the AI scans your Soil Health Card, it extracts exactly what is printed on the card. If your testing laboratory did not test for a specific micronutrient (like Zinc, Boron, or Moisture), the AI correctly registers it as missing.\n\n'
              'The app handles missing data safely by using a conservative neutral score for absent nutrients, rather than penalizing your farm with a "0" — which would unfairly reduce your yield prediction.',
        ),
        _FaqEntry(
          question: 'What is Electrical Conductivity (EC) and why does it matter?',
          answer:
              'EC (measured in dS/m) indicates the total salt concentration in your soil. Mulberry roots are highly sensitive to soil salinity.\n\n'
              '• EC < 0.5 dS/m: Ideal. No salt stress.\n'
              '• EC 0.5–1.0 dS/m: Borderline. Monitor carefully.\n'
              '• EC > 1.0 dS/m: Damaging. Salt stress causes root burn and severely reduces nitrogen uptake, weakening leaf protein quality.\n\n'
              'Many Soil Health Cards include EC testing. If yours does, the app will automatically extract and score it.',
        ),
        _FaqEntry(
          question: 'What is Organic Carbon (OC) and why is the 0.75% threshold important?',
          answer:
              'Organic Carbon (%) is the ultimate long-term fertility indicator of your soil. It drives water retention, microbial activity, and slow-release nutrient availability.\n\n'
              '• OC ≥ 0.75%: Healthy soil. Good water retention and microbial life.\n'
              '• OC 0.50–0.75%: Moderate. Consider organic amendments (compost, FYM).\n'
              '• OC < 0.50%: Critically low. Immediate attention required — yield will decline over multiple seasons even if NPK appears adequate.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Troubleshooting',
      icon: Icons.help_outline_rounded,
      color: AppTheme.troublePurple,
      entries: [
        _FaqEntry(
          question: 'The Dashboard says "Awaiting Data" — what do I do?',
          answer:
              'The V2 Yield Forecast requires three complete data points to unlock:\n\n'
              '1. Config Batch: Tap the green button at the top of the dashboard and fill out the rearing conditions.\n'
              '2. Leaf Scan: Go to the Leaf tab, take a photo, and save the result with leaf context.\n'
              '3. Soil Scan: Go to the Soil tab, photograph your Soil Health Card, and confirm the extracted values.\n\n'
              'The tracker at the top shows which steps are complete (green) and which are pending (grey). Once all three are green, the prediction automatically appears.',
        ),
        _FaqEntry(
          question: 'The weather fetch button shows an error — what happened?',
          answer:
              'The app uses the wttr.in weather service (no API key required) to fetch your local temperature and humidity based on GPS coordinates.\n\n'
              'Common causes of failure:\n'
              '• Location permission not granted to the app. Go to Settings → Apps → Seri-Helper → Permissions → Location.\n'
              '• No internet connection at time of fetch.\n'
              '• GPS signal is weak indoors.\n\n'
              'You can always set temperature and humidity manually using the sliders on the dashboard — they work offline.',
        ),
        _FaqEntry(
          question: 'Why does the leaf scan work offline but soil scan needs internet?',
          answer:
              'The leaf classification model (EfficientNetB0 via TFLite) runs entirely on your device — no internet required. It processes the image using your phone\'s processor (4 CPU threads).\n\n'
              'The soil card scanner uses the Groq LLaMA-4 Vision cloud API to read and interpret printed text from photographs. This requires an internet connection for the OCR extraction. The result is saved on-device once extracted, so you only need internet at scan time.',
        ),
      ],
    ),
  ];

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
              // ── HEADER ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local.locale == 'en' ? 'Help & Guide' : 'मदत आणि मार्गदर्शन',
                          style: AppTheme.headline2(context),
                        ),
                        Text(
                          local.locale == 'en'
                              ? 'Science behind every metric'
                              : 'प्रत्येक घटकाचे शास्त्र',
                          style: AppTheme.bodyMedium(context),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.translate_rounded, color: AppTheme.leafAccent),
                          onPressed: () => context.read<LocaleProvider>().toggleLocale(),
                          tooltip: local.locale == 'en' ? 'मराठी' : 'English',
                        ),
                        const Icon(Icons.menu_book_rounded, color: AppTheme.leafAccent, size: 28),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── CATEGORY FILTER TABS ────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final bool selected = _selectedCategory == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? cat.color.withOpacity(0.20)
                              : AppTheme.glassWhite,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: selected ? cat.color : AppTheme.glassBorder,
                            width: selected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon,
                                size: 14,
                                color: selected ? cat.color : AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              cat.title,
                              style: TextStyle(
                                color: selected ? cat.color : AppTheme.textMuted,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── FAQ LIST ────────────────────────────────────────────
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ListView.builder(
                    key: ValueKey(_selectedCategory),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _categories[_selectedCategory].entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Section header
                        final cat = _categories[_selectedCategory];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            borderColor: cat.color.withOpacity(0.4),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cat.color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(cat.icon, color: cat.color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cat.title,
                                          style: AppTheme.headline3(context)
                                              .copyWith(fontSize: 16, color: cat.color)),
                                      Text(
                                        '${cat.entries.length} questions',
                                        style: AppTheme.labelSmall(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final entry = _categories[_selectedCategory].entries[index - 1];
                      return _FaqCard(entry: entry, accentColor: _categories[_selectedCategory].color);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated expandable FAQ card
// ─────────────────────────────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final _FaqEntry entry;
  final Color accentColor;
  const _FaqCard({required this.entry, required this.accentColor});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderColor: _isOpen ? widget.accentColor.withOpacity(0.4) : AppTheme.glassBorder,
        child: Column(
          children: [
            // Question row — always visible
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('Q',
                            style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.entry.question,
                        style: AppTheme.bodyLarge(context).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isOpen ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _isOpen ? widget.accentColor : AppTheme.textMuted,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Answer — animated expand/collapse
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  Container(height: 1, color: AppTheme.glassBorder, margin: const EdgeInsets.symmetric(horizontal: 18)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.glassWhite,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text('A',
                                style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.entry.answer,
                            style: AppTheme.bodyMedium(context).copyWith(
                              height: 1.65,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
