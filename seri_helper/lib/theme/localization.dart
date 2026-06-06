import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// AppLocalizations handles dual-language support (English / Marathi)
/// for all screens, agronomical metrics, and warning screens in Seri-Helper.
class AppLocalizations {
  final String locale;

  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common UI
      'title': 'Seri-Helper',
      'dashboard': 'Dashboard',
      'leaf_scan': 'Leaf Scan',
      'soil_scan': 'Soil Scan',
      'history': 'History',
      'save_to_history': 'SAVE TO HISTORY',
      'saving': 'SAVING...',
      'confirm_save': '✅ Harvest Forecast Saved to History',
      
      // Dashboard Screen
      'v2_subtitle': 'V2 — 5-Factor Yield Prediction',
      'awaiting_data': 'Awaiting Data',
      'awaiting_data_sub': 'Complete Batch Setup, Leaf Scan, and Soil Scan to unlock the V2 Yield Forecast.',
      'real_time_climate': 'Real-time Climate',
      'harvest_forecast': 'Harvest Forecast',
      'expected_yield': 'EXPECTED COCOON YIELD',
      'kg_100_dfls': 'kg / 100 DFLs',
      'yield_range': 'Range: ',
      'efficiency_base': 'Efficiency Base',
      'primary_bottleneck': 'Primary Bottleneck: ',
      'five_factor_breakdown': '5-Factor Breakdown',
      'foliage_quality': 'Foliage Quality',
      'climate_comp': 'Climate Comp.',
      'soil_nutri': 'Soil & Nutri.',
      'disease_risk': 'Disease Risk',
      'mgmt_multiplier': 'Mgmt Multiplier',
      'config_batch_btn': 'Config Batch',
      'temp_slider': 'Temp',
      'humid_slider': 'Humid',
      'get_live_weather': 'Get Live Weather',
      'weather_error': 'Weather fetch failed: ',
      
      // Batch Config Screen
      'configure_batch': 'Configure Batch',
      'batch_config_sub': 'Set rearing conditions once per batch for accurate yield prediction',
      'rearing_season': 'Rearing Season',
      'season_sub': 'Affects disease risk and leaf quality',
      'silkworm_breed': 'Silkworm Breed',
      'breed_sub': 'Biggest genetic lever for cocoon yield',
      'hygiene_protocol': 'Hygiene Protocol',
      'hygiene_sub': 'Disinfection prevents 15–47% crop loss',
      'fertilization_method': 'Fertilization Method',
      'fert_sub': 'Foliar spray alone adds +52.8% yield (BSTRI)',
      'dfl_source': 'DFL (Egg) Source',
      'dfl_sub': 'Uncertified eggs carry up to 36% Pebrine risk',
      'pesticide_risk': 'Pesticide Risk',
      'adjacent_farm': 'Adjacent farm',
      'ventilation': 'Ventilation',
      'rearing_house': 'Rearing house',
      'feeding_frequency': 'Feeding Frequency',
      'feeding_sub': 'Optimal: 4/day in 5th instar (FAO)',
      'confirm_batch_setup': 'CONFIRM BATCH SETUP',
      'breed_info_tip': 'CSR Bivoltine yields 4.68× more than wild strains (PMC 2020)',
      'dfl_certified': 'Govt. Certified',
      'dfl_uncertified': 'Uncertified',
      'pesticide_none': 'None',
      'pesticide_present': 'Present',
      'feed_optimal': '✅ Optimal frequency',
      'feed_suboptimal': '⚠ Below optimal for 5th instar',
      
      // Leaf Scanner Screen
      'leaf_scanner_title': 'Leaf Scanner',
      'leaf_scanner_sub': 'V2 — Foliar Intelligence',
      'capture_leaf': 'Capture a mulberry leaf',
      'daylight_tip': 'Best results in daylight on a flat surface',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'foliar_report': 'Foliar Intelligence Report',
      'necrotic_area': 'Necrotic Area',
      'feed_suitability': 'Feed Suitability',
      'moisture_proxy': 'Moisture Proxy',
      'leaf_saved_alert': 'Leaf data saved — navigate to Dashboard to see yield prediction',
      
      // Soil Scanner Screen
      'soil_scanner_title': 'Soil Scanner',
      'soil_scanner_sub': 'V2 — Pedological Profile',
      'scan_card': 'Scan your Soil Health Card',
      'krishi_tip': 'Issued by Govt. of India — available from Krishi Vigyan Kendra',
      'soil_fitness': 'Soil\nFitness',
      'suitability_score_label': 'Mulberry Soil Suitability',
      'nutrient_radar': 'Nutrient Radar',
      'radar_subtitle': 'Actual vs. optimal mulberry baseline',
      'core_parameters': 'Core Parameters',
      'extended_parameters': 'Extended Parameters',
      'verify_correct_values': 'Verify & Correct Values',
      'correct_errors_sub': 'Correct any AI extraction errors before saving',
      'confirm_save_soil': 'CONFIRM & SAVE TO DASHBOARD',
      
      // History Screen
      'batch_history': 'Batch History',
      'past_forecasts': 'Past yield forecasts will appear here.',
      'empty_history': 'No records found. Complete a scan and save to view history.',
      'date': 'Date: ',
      'breed': 'Breed: ',
      'season': 'Season: ',
      
      // Bottleneck Recommendations
      'reco_foliage': 'Harvest top-shoot leaves (positions +2 to +4) in the 55–65 day window to improve leaf quality.',
      'reco_climate': 'Adjust rearing room temperature to 24–26°C and humidity to 75–85% for optimal silkworm performance.',
      'reco_soil': 'Apply foliar NPK spray (19:19:19 at 6g/L) in addition to basal fertilisation. This alone can boost yield by 52.8% (BSTRI 2022).',
      'reco_disease': 'Apply Labex or Sericillin bed disinfectant at every moult. Ensure DFLs are from a government-certified centre.',
      'reco_breed': 'Upgrade to CSR bivoltine hybrid DFLs and increase feeding frequency to 4 times/day during the 5th instar.',
      'reco_default': 'Maintain current conditions. Monitor leaf quality and climate daily.',
    },
    'mr': {
      // Common UI
      'title': 'रेशीम-मदतनीस',
      'dashboard': 'डॅशबोर्ड',
      'leaf_scan': 'पान तपासणी',
      'soil_scan': 'माती तपासणी',
      'history': 'इतिहास',
      'save_to_history': 'इतिहासात जतन करा',
      'saving': 'जतन करत आहे...',
      'confirm_save': '✅ उत्पादन अंदाज इतिहासात जतन केला आहे',
      
      // Dashboard Screen
      'v2_subtitle': 'आवृत्ती २ — ५-घटक उत्पादन अंदाज',
      'awaiting_data': 'माहितीची प्रतीक्षा आहे',
      'awaiting_data_sub': 'उत्पादन अंदाज पाहण्यासाठी बॅच सेटअप, पान आणि माती तपासणी पूर्ण करा.',
      'real_time_climate': 'सध्याचे हवामान',
      'harvest_forecast': 'कोश उत्पादन अंदाज',
      'expected_yield': 'अपेक्षित कोश उत्पादन',
      'kg_100_dfls': 'किग्रॅ / १०० अंडीपुंज (DFLs)',
      'yield_range': 'मर्यादा: ',
      'efficiency_base': 'क्षमता आधार',
      'primary_bottleneck': 'मुख्य अडथळा: ',
      'five_factor_breakdown': '५-घटक विश्लेषण',
      'foliage_quality': 'पानांची गुणवत्ता',
      'climate_comp': 'हवामान अनुकूलता',
      'soil_nutri': 'माती व पोषण',
      'disease_risk': 'रोगाचा धोका',
      'mgmt_multiplier': 'व्यवस्थापन गुणक',
      'config_batch_btn': 'बॅच सेट करा',
      'temp_slider': 'तापमान',
      'humid_slider': 'आर्द्रता',
      'get_live_weather': 'हवामान मिळवा',
      'weather_error': 'हवामान मिळवणे अयशस्वी: ',
      
      // Batch Config Screen
      'configure_batch': 'बॅच सेट करा',
      'batch_config_sub': 'अचूक उत्पादनासाठी बॅचची माहिती एकदा भरा',
      'rearing_season': 'हंगाम',
      'season_sub': 'हा रोगाचा धोका आणि पानांच्या गुणवत्तेवर परिणाम करतो',
      'silkworm_breed': 'रेशीम कीटक जात',
      'breed_sub': 'कोश उत्पादनासाठी सर्वात महत्त्वाचा घटक',
      'hygiene_protocol': 'स्वच्छता पद्धती',
      'hygiene_sub': 'औषध फवारणी १५-४७% नुकसान टाळते',
      'fertilization_method': 'खत व्यवस्थापन',
      'fert_sub': 'पानांवर फवारणी केल्याने ५२.८% उत्पादन वाढते (BSTRI)',
      'dfl_source': 'अंडीपुंज स्रोत',
      'dfl_sub': 'अप्रमाणित अंडीपुंजांमुळे पेब्रिन रोगाचा ३६% धोका असतो',
      'pesticide_risk': 'कीटकनाशकाचा धोका',
      'adjacent_farm': 'शेजारचे शेत',
      'ventilation': 'हवा खेळती राहणे',
      'rearing_house': 'रेशीम गृह',
      'feeding_frequency': 'खाद्य देण्याची वारंवारता',
      'feeding_sub': 'सर्वोत्तम: ५ व्या अवस्थेत ४ वेळा/दिवस (FAO)',
      'confirm_batch_setup': 'बॅच सेटअप पूर्ण करा',
      'breed_info_tip': 'सीएसआर बायव्होल्टाइन वन्य जातींपेक्षा ४.६८ पट अधिक उत्पादन देते',
      'dfl_certified': 'शासकीय प्रमाणित',
      'dfl_uncertified': 'अप्रमाणित',
      'pesticide_none': 'काहीही नाही',
      'pesticide_present': 'धोका आहे',
      'feed_optimal': '✅ योग्य वारंवारता',
      'feed_suboptimal': '⚠ ५ व्या अवस्थेसाठी अपुरी वारंवारता',
      
      // Leaf Scanner Screen
      'leaf_scanner_title': 'पानांचा स्कॅनर',
      'leaf_scanner_sub': 'आवृत्ती २ — पानांची गुणवत्ता विश्लेषण',
      'capture_leaf': 'तुतीचे पान कॅप्चर करा',
      'daylight_tip': 'सपाट पृष्ठभागावर सूर्यप्रकाशात चांगले निकाल मिळतात',
      'camera': 'कॅमेरा',
      'gallery': 'गॅलरी',
      'foliar_report': 'पानांचा गुणवत्ता अहवाल',
      'necrotic_area': 'खराब क्षेत्रफळ',
      'feed_suitability': 'खाद्य सुसंगतता',
      'moisture_proxy': 'पाण्याचा अंश',
      'leaf_saved_alert': 'पानांची माहिती जतन झाली — उत्पादन अंदाज पाहण्यासाठी डॅशबोर्डवर जा',
      
      // Soil Scanner Screen
      'soil_scanner_title': 'मातीचा स्कॅनर',
      'soil_scanner_sub': 'आवृत्ती २ — माती परीक्षण विश्लेषण',
      'scan_card': 'तुमचे सॉईल हेल्थ कार्ड स्कॅन करा',
      'krishi_tip': 'भारत सरकारद्वारे जारी केलेले - कृषी विज्ञान केंद्रातून उपलब्ध',
      'soil_fitness': 'मातीची\nयोग्यता',
      'suitability_score_label': 'तुतीसाठी मातीची सुसंगतता',
      'nutrient_radar': 'पोषक द्रव्य रडार',
      'radar_subtitle': 'वास्तविक वि. तुतीची आदर्श पातळी',
      'core_parameters': 'मुख्य घटक',
      'extended_parameters': 'इतर घटक',
      'verify_correct_values': 'तपासा आणि दुरुस्त करा',
      'correct_errors_sub': 'जतन करण्यापूर्वी चुकीचे आकडे दुरुस्त करा',
      'confirm_save_soil': 'तपासा आणि डॅशबोर्डवर जतन करा',
      
      // History Screen
      'batch_history': 'बॅचचा इतिहास',
      'past_forecasts': 'जुने अंदाज येथे दिसतील.',
      'empty_history': 'कोणतीही नोंद आढळली नाही. स्कॅन पूर्ण करा आणि इतिहास पहा.',
      'date': 'दिनांक: ',
      'breed': 'कीटक जात: ',
      'season': 'हंगाम: ',
      
      // Bottleneck Recommendations
      'reco_foliage': 'पानांची गुणवत्ता सुधारण्यासाठी ५५-६५ दिवसांच्या दरम्यान शेंड्याची पाने (स्थान +२ ते +४) तोडा.',
      'reco_climate': 'रेशीम कीटकांच्या वाढीसाठी रेशीम गृहाचे तापमान २४-२६°C आणि आर्द्रता ७५-८५% ठेवा.',
      'reco_soil': 'पानांवर नत्र-स्फुरद-पालाश (१९:१९:१९) फवारणी करा. यामुळे कोश उत्पादनात ५२.८% वाढ होऊ शकते.',
      'reco_disease': 'कीटकांच्या कात टाकण्याच्या वेळी बेडेक्स किंवा सेरिसिलीन पावडरचा वापर करा. प्रमाणित अंडीपुंज वापरा.',
      'reco_breed': 'सीएसआर बायव्होल्टाइन जात वापरा आणि ५ व्या अवस्थेत दिवसातून ४ वेळा खाद्य द्या.',
      'reco_default': 'सध्याची परिस्थिती चांगली आहे. दररोज पानांची गुणवत्ता आणि हवामानावर लक्ष ठेवा.',
    }
  };

  String translate(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context, {bool listen = true}) {
    final provider = Provider.of<LocaleProvider>(context, listen: listen);
    return AppLocalizations(provider.currentLocale);
  }
}

/// LocaleProvider manages language state (en/mr)
class LocaleProvider extends ChangeNotifier {
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;

  void toggleLocale() {
    _currentLocale = _currentLocale == 'en' ? 'mr' : 'en';
    notifyListeners();
  }

  void setLocale(String langCode) {
    if (langCode == 'en' || langCode == 'mr') {
      _currentLocale = langCode;
      notifyListeners();
    }
  }
}
