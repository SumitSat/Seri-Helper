import 'package:cloud_firestore/cloud_firestore.dart';

class YieldService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculates the expected cocoon yield based on sericulture parameters.
  /// Baseline optimal yield: ~60 kg per acre per crop.
  Map<String, dynamic> calculateYield({
    required String leafGrade,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double moisture,
    required double farmAreaAcres,
  }) {
    double baselineYieldPerAcre = 60.0; // kg

    // 1. Leaf Quality Modifier (38.2% importance in literature)
    double leafModifier = 1.0;
    if (leafGrade == 'Excellent') leafModifier = 1.0;
    else if (leafGrade == 'Medium') leafModifier = 0.75;
    else leafModifier = 0.40; // Poor leaves severely stunt silkworm growth

    // 2. Soil Health Modifier
    // Ideal pH is 6.5 to 6.8
    double phModifier = (ph >= 6.0 && ph <= 7.2) ? 1.0 : 0.8;
    
    // Simplistic NPK check (Mock baseline values)
    double nScore = (nitrogen >= 15.0) ? 1.0 : (nitrogen / 15.0);
    double pScore = (phosphorus >= 5.0) ? 1.0 : (phosphorus / 5.0);
    double kScore = (potassium >= 10.0) ? 1.0 : (potassium / 10.0);
    
    double soilModifier = ((nScore + pScore + kScore) / 3.0) * phModifier;

    // 3. Final Calculation
    double expectedYield = baselineYieldPerAcre * farmAreaAcres * leafModifier * soilModifier;
    
    // Cap maximum efficiency to 110% of baseline
    if (expectedYield > baselineYieldPerAcre * farmAreaAcres * 1.1) {
      expectedYield = baselineYieldPerAcre * farmAreaAcres * 1.1;
    }

    return {
      'expectedYieldKg': expectedYield.toStringAsFixed(2),
      'leafModifier': leafModifier,
      'soilModifier': soilModifier,
      'recommendation': _generateRecommendation(leafGrade, soilModifier, ph),
    };
  }

  String _generateRecommendation(String leafGrade, double soilModifier, double ph) {
    if (leafGrade == 'Poor') {
      return "URGENT: Discard diseased leaves immediately. Treat plants with appropriate fungicide.";
    }
    if (ph < 6.0) {
      return "Soil is too acidic. Consider adding agricultural lime to boost mulberry growth.";
    }
    if (soilModifier < 0.8) {
      return "Soil nutrients are low. Apply NPK fertilizer to reach optimal 250:100:100 ratio.";
    }
    return "Excellent conditions! Maintain current irrigation and monitoring.";
  }

  /// Syncs the final report to Firebase Firestore
  Future<void> saveYieldReportToFirebase(Map<String, dynamic> reportData) async {
    try {
      await _firestore.collection('yield_reports').add({
        ...reportData,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Report synced to Firebase successfully.");
    } catch (e) {
      print("Firebase sync failed: $e");
      // Fallback for local dev if Firebase isn't initialized yet
      throw Exception("Could not sync to cloud. Ensure Firebase is configured.");
    }
  }
}
