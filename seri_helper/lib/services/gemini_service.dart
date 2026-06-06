import 'dart:convert';
import 'dart:io';
import 'package:seri_helper/models/models.dart';

/// GeminiService uses the Groq LLM (Llama-4-Scout vision model) to extract
/// comprehensive soil health parameters from a photographed Soil Health Card.
///
/// V2 upgrade: Now extracts all 11 parameters (5 core + 6 extended)
/// and returns a typed [SoilData] object instead of a raw map.
class GeminiService {
  // Groq API Key — free tier, no regional restrictions. Get yours at console.groq.com/keys
  static const String _apiKey = "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";
  static const String _endpoint = "https://api.groq.com/openai/v1/chat/completions";
  static const String _model    = "meta-llama/llama-4-scout-17b-16e-instruct";

  /// V2 SYSTEM PROMPT — instructs the model to extract all soil parameters
  /// that feed into the SHI (Soil Health Index) of the yield calculation engine.
  static const String _soilPrompt = """
You are an expert agronomist AI assistant specializing in soil health analysis for mulberry cultivation in India.

Analyze the uploaded Soil Health Card image and extract ALL numerical values present.

Return ONLY a single, valid JSON object. No markdown, no code fences, no explanations.

Required fields (use 0.0 if the value is genuinely absent from the card):
{
  "nitrogen": <kg/ha as decimal>,
  "phosphorus": <kg/ha as decimal>,
  "potassium": <kg/ha as decimal>,
  "pH": <pH value as decimal, typically 5.0 to 9.0>,
  "moisture": <percentage as decimal, or 0.0 if not shown>
}

Extended fields (include ONLY if the value is visible on the card; omit the key entirely if not present):
{
  "ec": <Electrical Conductivity in dS/m>,
  "organicCarbon": <OC percentage, e.g. 0.75>,
  "zinc": <Zinc in mg/kg>,
  "iron": <Iron in mg/kg>,
  "boron": <Boron in mg/kg>,
  "sulfur": <Sulfur in mg/kg>
}

Important rules:
1. Merge both objects into a SINGLE flat JSON response.
2. Never guess or fabricate values. Only extract what is clearly printed on the card.
3. If units on the card differ from the above (e.g. N in %), convert to kg/ha using: N% × 10 = kg/ha approximate.
4. pH should be a decimal between 4.0 and 9.5. If you see a value outside this range, it is likely misread — double check.
5. Return ONLY the JSON object. No other text whatsoever.
""";

  /// Analyzes a Soil Health Card image and returns a typed [SoilData] object.
  Future<SoilData> parseSoilHealthCard(File imageFile) async {
    final imageBytes  = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final requestBody = jsonEncode({
      "model": _model,
      "messages": [
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": _soilPrompt,
            },
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,$base64Image",
              }
            }
          ]
        }
      ],
      "temperature": 0.05, // Very low temperature — we want deterministic extraction, not creativity
      "max_tokens":  768,
    });

    final httpClient = HttpClient();
    final request    = await httpClient.postUrl(Uri.parse(_endpoint));
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $_apiKey');
    request.write(requestBody);

    final response     = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      print('[GeminiService] Groq HTTP ${response.statusCode}: $responseBody');
      throw Exception('Groq API error ${response.statusCode}');
    }

    final decoded = jsonDecode(responseBody);
    final rawText = decoded['choices'][0]['message']['content'] as String;

    // Strip markdown fences if the model adds them despite instructions
    final cleaned = rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    print('[GeminiService] Raw LLM output: $cleaned');

    final Map<String, dynamic> jsonMap = jsonDecode(cleaned);

    // Build and return the strongly-typed SoilData object
    return SoilData.fromLlmJson(jsonMap);
  }
}
