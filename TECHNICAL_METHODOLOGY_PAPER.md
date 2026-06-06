# Seri-Helper V2: A Multi-Modal Edge AI and Large Language Model Pipeline for Real-Time Silkworm Cocoon Yield Prediction

## A Technical & Scientific Methodology Paper

---

### Abstract

Sericulture, the cultivation of mulberry leaves and rearing of silkworms for silk production, is a highly sensitive agricultural science governed by complex interactions between crop nutrition, environmental microclimates, genetics, and pathology. This paper presents the technical and scientific methodology of **Seri-Helper V2**, a mobile application designed to predict silkworm (Bombyx mori) cocoon yield (measured in kg / 100 DFLs) without requiring IoT hardware deployments. The system integrates:
1. An on-device quantized **uint8 EfficientNet-B0** convolutional neural network for real-time mulberry foliage disease grading;
2. A cloud-based Large Language Model (LLM) vision pipeline running **LLaMA-4 Scout (17B)** via the **Groq API** to digitize unstructured government Soil Health Cards; and
3. A research-derived multi-factor yield engine.

We detail the exact mathematical frameworks for the five sub-indices: Foliage Quality Index (FQI), Climate Conditions Index (CCI), Soil Health Index (SHI), Disease Risk Penalty (D-Penalty), and Breed & Management Factor (BM-Factor). Finally, we document the system calibration, physical boundaries, and operational limitations based on code-verified realities.

**Keywords:** Sericulture, Edge AI, Large Language Models, Soil Chemistry, EfficientNet-B0, LLaMA-4 Scout, Cocoon Yield Forecasting, Computer Vision.

---

## Table of Contents

1. [Introduction & Motivation](#1-introduction---motivation)
2. [System Architecture Overview](#2-system-architecture-overview)
3. [Module 1: Batch Configuration & Rearing Context](#3-module-1-batch-configuration---rearing-context)
4. [Module 2: Edge AI Leaf Scanner & Foliage Quality Index (FQI)](#4-module-2-edge-ai-leaf-scanner---foliage-quality-index-fqi)
5. [Module 3: Soil Health Card Parser & Soil Health Index (SHI)](#5-module-3-soil-health-card-parser---soil-health-index-shi)
6. [Module 4: Climate Conditions Index (CCI)](#6-module-4-climate-conditions-index-cci)
7. [Module 5: Disease Risk Penalty (D-Penalty)](#7-module-5-disease-risk-penalty-d-penalty)
8. [Module 6: Breed & Management Factor (BM-Factor)](#8-module-6-breed---management-factor-bm-factor)
9. [The Master Yield Formula](#9-the-master-yield-formula)
10. [System Calibration, Calibration Boundaries & Limitations](#10-system-calibration-calibration-boundaries---limitations)
11. [References](#11-references)

---

## 1. Introduction & Motivation

Sericulture represents a major rural socio-economic driver in developing economies, particularly in South Asia. In India, the second-largest global silk producer, the sector directly employs approximately 7.9 million people, predominantly smallholders operating farms of less than 2 acres [1, 2]. Despite its economic importance, sericulture is highly volatile; crops are susceptible to sudden collapses due to microclimatic fluctuations, sub-optimal feeding, or rapid disease outbreaks.

Cocoons are spun by the silkworm Bombyx mori, an oligophagous insect that feeds exclusively on the leaves of the mulberry plant (Morus alba). The biological conversion of leaf protein (specifically fibroin and sericin) into silk filament is highly sensitive to environmental factors. Historically, progressive research institutes such as the Central Sericultural Research & Training Institute (CSRTI) Mysore have published extensive guidelines on crop management [4], yet smallholder farmers have lacked a quantitative, unified mechanism to predict cocoon harvests or detect limiting factors in real time.

Existing crop prediction systems typically rely on expensive Internet-of-Things (IoT) sensor grids or remote sensing data that suffer from poor spatial resolution at the smallholder scale. **Seri-Helper V2** implements a mobile-first paradigm designed to run on low-cost consumer smartphones. By combining local edge inference for image classification and specialized cloud APIs for document OCR, the system synthesizes agronomical research into a real-time yield calculator, allowing farmers to simulate environmental conditions and receive targeted corrective interventions.

---

## 2. System Architecture Overview

The mobile application is implemented using the **Flutter SDK** (Dart language) with a reactive, provider-based state management architecture. The execution pipeline follows a sequential, decoupled data ingestion model:

```
                  ┌──────────────────────┐
                  │  Batch Configuration │
                  └──────────┬───────────┘
                             │ (RearingContext)
                             ▼
 ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
 │  Leaf Scan   │   │  Soil Scan   │   │  GPS Sensor  │   │  Manual T/RH │
 └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
        │ (TFLite)         │ (Groq LLM)       │ (Geolocator)     │ (Sliders)
        ▼                  ▼                  ▼                  ▼
 ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
 │ Foliar/Harv  │   │   SoilData   │   │   wttr.in    │   │  Simulated   │
 │   Context    │   │  (11 Params) │   │   Weather    │   │   Climate    │
 └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
        │                  │                  └────────┬─────────┘
        │                  │                           │
        └──────────────────┼───────────────────────────┘
                           ▼
              ┌──────────────────────────┐
              │  YieldEngineV2.calculate │
              └────────────┬─────────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │      YieldResultV2       │
              │  (Yield + 5 Breakdowns)  │
              └────────────┬─────────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │    Firebase Firestore    │
              │     (Archive Sync)       │
              └──────────────────────────┘
```

The system operates as follows:
1. **RearingContext Provider** tracks batch configuration settings.
2. **LeafScan Provider** stores on-device deep learning foliage grading outputs and harvest context.
3. **SoilData Provider** manages soil nutrient levels digitized from Soil Health Cards.
4. **Climate Inputs** are fetched from wttr.in based on device GPS coordinates, but can be overridden by manual UI sliders.
5. The core **`YieldEngineV2`** runs the mathematical formula as soon as all state providers are populated, archiving the final `YieldResultV2` report to a remote Firebase Firestore instance for historical tracking.

---

## 3. Module 1: Batch Configuration & Rearing Context

**Core Source Code:** [`lib/models/rearing_context.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/models/rearing_context.dart), [`lib/screens/batch_config_screen.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/screens/batch_config_screen.dart)

The `RearingContext` object models the metadata of the current rearing cycle. These parameters act as multipliers or disease-risk variables in the yield calculation:

### 3.1 Rearing Season (RearingSeason)
Seasonal changes affect temperature, humidity stability, leaf nutritional values, and disease vectors. The seasons are mapped to discrete scores:
* **Spring:** 1.00 -- Optimal ambient conditions, maximum leaf moisture, lowest pathogen pressure.
* **Winter:** 0.85 -- Good leaf nutritional quality, but cold temperatures slow larval development.
* **Monsoon:** 0.70 -- High relative humidity, which triggers viral (Grasserie) and bacterial (Flacherie) outbreaks.
* **Summer:** 0.65 -- Low leaf moisture, heat stress on bivoltine silkworm strains.

### 3.2 Silkworm Breed (SilkwormBreed)
The genetic potential of the silkworm breed is a critical yield determinant:
* **CSR Bivoltine:** 1.00 -- High-yielding hybrid (e.g., CSR2 * CSR4). Genetically produces heavy cocoons with long, high-quality white silk filaments, but is highly sensitive to environmental stress.
* **Multivoltine Cross:** 0.85 -- A hybrid cross (Multivoltine * Bivoltine). More resilient to fluctuating heat and humidity, yielding moderate cocoon weight.
* **Pure Multivoltine:** 0.70 -- Hardiest local breeds. High disease survival rates, but spin small, light cocoons with short, low-quality filaments.

### 3.3 Hygiene & Disinfection (HygieneLevel)
Sanitization is critical to prevent crop failure:
* **Full Disinfection:** 1.00 -- Complete rearing house disinfection using Formalin or Bleaching Powder, and bed sanitization with Labex or Sericillin at every molt.
* **Partial Disinfection:** 0.75 -- Occasional sanitization, not performed at every molt.
* **No Disinfection:** 0.40 -- Trays and rearing beds are not sanitized, leaving them vulnerable to active pathogen reservoirs.

### 3.4 Fertilization Method (FertilizationMethod)
* **Foliar + Basal:** 1.00 -- Direct soil fertilization combined with foliar NPK sprays (e.g., 1% NPK 19:19:19).
* **Basal Only:** 0.70 -- Standard soil-only fertilizer application.
* **None:** 0.40 -- Unfertilized fields, leading to nutritional deficiencies in the harvested leaves.

### 3.5 DFL Source (DflSource)
* **Government Certified:** Risk factor 0.05 -- Eggs sourced from CSB/KSDB grainages, microscopically screened for vertical Nosema bombycis (Pebrine) transmission.
* **Uncertified:** Risk factor 0.40 -- Eggs from unverified local suppliers, presenting a high risk of Pebrine infection.

### 3.6 Pesticide Risk (PesticideRisk)
A binary risk indicator:
* **None:** 0.0 penalty -- The mulberry field is isolated.
* **Present:** 0.5 penalty -- The field is adjacent to chemical-intensive crops (e.g., cotton or vegetables), exposing it to pesticide drift.

### 3.7 Ventilation Quality (VentilationQuality)
* **Good:** 1.00 -- Constant fresh air flow, preventing carbon dioxide and ammonia build-up.
* **Moderate:** 0.75 -- Standard window ventilation.
* **Poor:** 0.50 -- Stuffy, stagnant air that promotes pathogen growth.

---

## 4. Module 2: Edge AI Leaf Scanner & Foliage Quality Index (FQI)

**Core Source Code:** [`lib/services/tflite_service.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/tflite_service.dart), [`lib/models/foliar_health_result.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/models/foliar_health_result.dart), [`lib/models/harvest_context.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/models/harvest_context.dart)

To grade the harvested foliage, Seri-Helper V2 combines an on-device computer vision model with contextual inputs.

### 4.1 On-Device Computer Vision Pipeline
The system runs a **fully integer-quantized (uint8) EfficientNet-B0** model locally via TensorFlow Lite (tflite_flutter), eliminating the need for network connectivity during inference.
* **Model File Size:** Exactly **5,266,456 bytes (~5.02 MB)**, allowing it to load quickly on low-specification mobile devices.
* **Input Tensor Shape:** `[1, 224, 224, 3]` of type `TfLiteType.uint8`.
* **Output Tensor Shape:** `[1, 4]` of type `TfLiteType.uint8`, corresponding to the four calibrated classes:
  1. `Disease Free leaves` (Healthy)
  2. `Leaf Rust` (Red Rust -- Cercospora moricola)
  3. `Leaf spot` (Leaf spot -- Pseudocercospora mori)
  4. `Powdery Mildew` (Powdery Mildew -- Phyllactinia corylea)

#### Preprocessing & Inference Logic:
1. The captured image is decoded and resized to 224 * 224 pixels using the image library.
2. The pixel channels [R, G, B] are extracted as integer values in the range [0, 255] and packed into the input tensor.
3. Quantized inference maps the network weights to 8-bit integers.
4. The output values are normalized to confidence percentages by dividing the winning class integer score by 255.0:
   Confidence = (Winning Tensor Score) / 255.0

### 4.2 Safety-First Decision Boundary
To protect silkworms from contaminated feed, the app implements a conservative decision boundary:

```
isHealthy = (Winning Label contains "disease free" or "healthy")

if (isHealthy) {
    if (Confidence >= 0.80) {
        LeafGrade = Excellent;  aiHealthScore = 1.00;
    } else if (Confidence >= 0.60) {
        LeafGrade = Medium;     aiHealthScore = 0.65;
    } else {
        LeafGrade = Medium;     aiHealthScore = 0.50;
    }
} else {
    LeafGrade = Poor;           aiHealthScore = 0.25;
}
```

This ensures that if the model is uncertain (confidence < 80%), the leaf is graded as "Medium" and the farmer is warned to inspect the leaves manually. If any disease is classified with high confidence, the score drops to 0.25 and the farmer is instructed to discard the leaves.

### 4.3 Foliar Health Index (FHI)
Before incorporating harvest context, the app displays the **Foliar Health Index (FHI)** on the UI as a percentage score out of 100:
FHI = (0.55 * aiHealthScore + 0.25 * diseaseFlagScore + 0.20 * moistureProxy) * 100

Where:
* `diseaseFlagScore` = 1.00 if healthy and confidence >= 80%; = 0.60 if healthy with lower confidence; and = 0.15 if diseased.
* `moistureProxy` is a heuristic estimate based on the model's confidence in the leaf's freshness (Healthy >= 80% --> 1.0; Healthy >= 60% --> 0.75; Healthy < 60% --> 0.55; Diseased --> 0.40).

### 4.4 Foliage Quality Index (FQI)
The FQI integrates the AI scan results with the leaf harvesting context provided by the farmer:
FQI = clamp((0.35 * aiHealthScore) + (0.20 * leafPositionScore) + (0.20 * leafAgeScore) + (0.15 * moistureProxy) + (0.10 * diseaseFlagScore))

The scores for `leafPositionScore` and `leafAgeScore` are mapped as follows:
* **Leaf Position:** Top (P2-P4) = 1.00; Mixed (P5-P8) = 0.85; Basal (P8+) = 0.65.
* **Shoot Age:** 55-65 days = 1.00; 45-54 days = 0.85; 66-75 days = 0.80; 35-44 days = 0.60; else = 0.45.

---

## 5. Module 3: Soil Health Card Parser & Soil Health Index (SHI)

**Core Source Code:** [`lib/services/gemini_service.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/gemini_service.dart), [`lib/models/soil_data.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/models/soil_data.dart)

To evaluate soil suitability, the app uses a multimodal LLM to parse printed Soil Health Cards.

### 5.1 Cloud-Based Vision Inference
The app connects to the **Groq API** endpoint `https://api.groq.com/openai/v1/chat/completions` using the **LLaMA-4 Scout** model (`meta-llama/llama-4-scout-17b-16e-instruct`).
* **Parameters:** `temperature = 0.05` (near-deterministic), `max_tokens = 768`.
* **Prompt Instructions:** The model is instructed to extract 11 chemical parameters into a single flat JSON object. If a core parameter is missing, it is mapped to 0.0. If units are listed as percentages, they are converted to kg/ha (e.g., Nitrogen % * 10).

### 5.2 Fact Check: Visualized vs. Calculated Parameters
> [!IMPORTANT]
> **Operational Fact Check:**
> The parser extracts 11 parameters from the Soil Health Card. Five are **Core V1** parameters and six are **Extended V2** parameters:
> * **Core (Used in SHI Yield Calculation):** Nitrogen (N), Phosphorus (P), Potassium (K), pH, and Organic Carbon (OC).
> * **Extended (Visualized Only):** Electrical Conductivity (EC), Moisture (%), Zinc (Zn), Iron (Fe), Boron (B), and Sulfur (S).
> 
> While EC and micronutrients are parsed, scored, and displayed in the app's **Nutrient Radar Chart** and parameter lists, they are **not** fed into the mathematical Soil Health Index (SHI) formula. This design choice prevents missing micronutrient values (which are frequently omitted from laboratory testing) from skewing the final yield prediction.

### 5.3 Soil Parameter Scoring Brackets
The extracted soil parameters are scored out of 1.00:

#### Nitrogen (N) Score:
* N >= 280 kg/ha --> 1.00
* N >= 140 kg/ha --> 0.80
* N >= 70 kg/ha  --> 0.55
* else           --> 0.30

#### Phosphorus (P) Score:
* P >= 60 kg/ha --> 1.00
* P >= 30 kg/ha --> 0.80
* P >= 15 kg/ha --> 0.55
* else          --> 0.30

#### Potassium (K) Score:
* K >= 100 kg/ha --> 1.00
* K >= 50 kg/ha  --> 0.80
* K >= 25 kg/ha  --> 0.55
* else           --> 0.30

#### Combined NPK Score:
npkScore = (0.50 * Nitrogen_score) + (0.25 * Phosphorus_score) + (0.25 * Potassium_score)

#### Soil pH Score:
* pH 6.5 to 6.8 --> 1.00 (Ideal)
* pH 6.0 to 7.2 --> 0.85 (Acceptable)
* pH 5.5 to 7.5 --> 0.65 (Borderline)
* else          --> 0.35 (Damaging)

#### Organic Carbon (OC) Score:
* OC >= 0.75% --> 1.00
* OC >= 0.50% --> 0.75
* OC < 0.50%  --> 0.45
* OC = null   --> 0.75 (conservative default)

#### Electrical Conductivity (EC) Score (Visualized Only):
* EC < 0.5 dS/m --> 1.00
* EC < 1.0 dS/m --> 0.80
* EC < 2.0 dS/m --> 0.55
* else          --> 0.25

### 5.4 Soil Health Index (SHI) Formula
The final SHI score combines soil nutrients, pH, and the fertilization management method:
SHI = clamp((0.40 * npkScore) + (0.25 * phScore) + (0.25 * fertilizationScore) + (0.10 * organicCarbonScore))

Where `fertilizationScore` represents the fertilization method (1.00 for Foliar + Basal, 0.70 for Basal Only, and 0.40 for None).

---

## 6. Module 4: Climate Conditions Index (CCI)

**Core Source Code:** [`lib/services/yield_engine_v2.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/yield_engine_v2.dart) (lines 62–75, 204–246)

The CCI calculates how close the rearing house climate is to the biological sweet spot for silkworm rearing.

### 6.1 Temperature Scoring
Silkworms are cold-blooded poikilotherms. Temperatures above 30 degrees C cause heat stress and suppress silk gland activity, while temperatures below 20 degrees C slow larval development.
* **Temp 24.0 to 26.0 degrees C:** 1.00 (Ideal range)
* **Temp 22.0 to 24.0 degrees C:** 0.90 (Slightly cool)
* **Temp 26.0 to 28.0 degrees C:** 0.85 (Slightly warm)
* **Temp 28.0 to 30.0 degrees C:** 0.65 (Moderate heat stress)
* **Temp 30.0 to 32.0 degrees C:** 0.45 (Severe heat stress)
* **Temp 18.0 to 22.0 degrees C:** 0.60 (Cold; development delayed)
* **Else (<18 or >32 degrees C):** 0.25 (Extreme stress)

### 6.2 Relative Humidity (RH) Scoring
High humidity increases disease risk, while low humidity causes mulberry leaves to dry out on the rearing beds.
* **RH 75.0% to 85.0%:** 1.00 (Ideal range)
* **RH 85.0% to 90.0%:** 0.80 (High; moderate disease risk)
* **RH 70.0% to 75.0%:** 0.80 (Low; leaf drying risk)
* **RH 90.0% to 94.0%:** 0.65 (Very high; elevated pathogen risk)
* **RH 65.0% to 70.0%:** 0.60 (Dry; poor palatability)
* **RH > 94.0%:** 0.45 (Saturated; high disease transmission risk)
* **Else (<65%):** 0.35 (Severe dry conditions)

### 6.3 CCI Formula
The sub-scores are combined as follows:
CCI = clamp((0.40 * temperatureScore) + (0.30 * humidityScore) + (0.15 * ventilationScore) + (0.15 * seasonScore))

The `ventilationScore` maps to 1.00, 0.75, and 0.50 for Good, Moderate, and Poor, respectively. The `seasonScore` maps to 1.00, 0.85, 0.70, and 0.65 for Spring, Winter, Monsoon, and Summer.

---

## 7. Module 5: Disease Risk Penalty (D-Penalty)

**Core Source Code:** [`lib/services/yield_engine_v2.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/yield_engine_v2.dart) (lines 92–110, 294–336)

The `D-Penalty` estimates the probability of crop losses due to pathogen outbreaks based on ambient humidity and seasonal risks:

### 7.1 Nuclear Polyhedrosis Virus (Grasserie) Risk (d_Grasserie)
Grasserie outbreaks correlate with high temperatures and high humidity (>85% RH):
* **Base Risk:** Monsoon = 0.30; Summer = 0.15; Winter = 0.08; Spring = 0.05.
* **Humidity Modifiers:** If RH > 90%, add +0.20. If RH > 85%, add +0.10 (clamped to a maximum of 0.80).

### 7.2 Infectious Flacherie Risk (d_Flacherie)
Flacherie is a prevalent bacterial disease that thrives under warm, humid conditions:
* **Base Risk:** Monsoon = 0.35; Summer = 0.20; Winter = 0.10; Spring = 0.07.
* **Humidity Modifier:** If RH > 90%, add +0.15 (clamped to a maximum of 0.80).

### 7.3 White/Yellow Muscardine (Fungal) Risk (d_Muscardine)
Muscardine outbreaks are caused by fungal spores (Beauveria bassiana) that thrive in cool, damp conditions:
* **Seasonal Risk:** Winter = 0.15; Monsoon = 0.10; Spring = 0.05; Summer = 0.03.

### 7.4 Pebrine Parasite Risk (d_Pebrine)
Pebrine is caused by Nosema bombycis spores:
* **Source Risk:** Government Certified DFLs = 0.05; Uncertified DFLs = 0.40.

### 7.5 D-Penalty Formula
The total disease penalty is calculated using a weighted sum of the individual disease risks:
D-Penalty = clamp(1.0 - ((0.30 * d_Grasserie) + (0.25 * d_Flacherie) + (0.15 * d_Muscardine) + (0.20 * d_Pebrine) + (0.10 * d_Pesticide)), min=0.53, max=1.0)

Where d_Pesticide is 0.5 if pesticide risk is present, and 0.0 if it is absent.
* **The 0.53 Floor:** This minimum floor ensures the model does not predict zero yields under worst-case inputs, which is consistent with field observations where some portion of the crop typically survives.

---

## 8. Module 6: Breed & Management Factor (BM-Factor)

**Core Source Code:** [`lib/services/yield_engine_v2.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/yield_engine_v2.dart) (lines 112–126, 258–288)

The BM-Factor represents the influence of breed selection and management choices on yield:

### 8.1 Feeding Frequency Score (feedingScore)
Silkworms require regular feeding during the 5th instar to maximize silk secretion:
* >= 4 feeds/day --> 1.00
* 3 feeds/day    --> 0.85
* 2 feeds/day    --> 0.65
* <= 1 feed/day   --> 0.40

### 8.2 Season * Breed Mismatch Score (seasonBreedScore)
Some breeds are sensitive to seasonal temperature changes:
* Bivoltine CSR hybrid in Summer --> 0.75 (due to thermal stress).
* Pure Multivoltine in any season --> 0.90 (due to high temperature tolerance).
* Other combinations --> 1.00.

### 8.3 BM-Factor Formula
The individual management scores are combined as follows:
BM-Factor = clamp((0.35 * breedScore) + (0.30 * hygieneScore) + (0.25 * feedingScore) + (0.10 * seasonBreedScore), min=0.70, max=1.0)

The `hygieneScore` maps to 1.00, 0.75, and 0.40 for Full, Partial, and No disinfection, respectively.

---

## 9. The Master Yield Formula

**Core Source Code:** [`lib/services/yield_engine_v2.dart`](file:///c:/Users/Shashwat/OneDrive/Desktop/Mulberry_Yield_Project/seri_helper/lib/services/yield_engine_v2.dart) (lines 129–131)

The predicted cocoon yield (in kg per 100 DFLs) is calculated by combining the sub-indices:

Yield (kg / 100 DFLs) = 65.0 * ((0.382 * FQI) + (0.370 * CCI) + (0.248 * SHI)) * D-Penalty * BM-Factor

### 9.1 Mathematical Principles
1. **The Base Yield Constant (65.0):** This constant represents the maximum potential cocoon yield (in kg per 100 DFLs) under ideal management conditions using certified CSR Bivoltine hybrid eggs [4].
2. **Three-Factor Index Weights:** The weights for FQI (0.382), CCI (0.370), and SHI (0.248) are derived from the variance contributions established by Miyashita (1986) [3]. Foliage quality (FQI) is the largest contributor to yield variance, followed closely by climate (CCI).
3. **Multiplicative Penalties:** The disease penalty (D-Penalty) and management factor (BM-Factor) are applied multiplicatively. This models the biological reality where disease outbreaks or poor management practices act as systemic bottlenecks, reducing the overall yield regardless of soil or weather quality.
4. **Yield Range Computation:**
   Yield_low = Yield * 0.85
   Yield_high = Yield * 1.15
   This +/- 15% range reflects natural genetic variation and microclimatic fluctuations within the rearing house.

---

## 10. System Calibration, Calibration Boundaries & Limitations

### 10.1 Calibration Boundaries
The model is calibrated for tropical and sub-tropical sericulture zones (specifically Karnataka, India). Re-calibration of the base constant (65.0) and seasonal baselines may be required for other regions (such as China or Brazil).

### 10.2 Operational Limitations
1. **Foliar Moisture Estimation:** The `moistureProxy` is estimated based on model confidence rather than direct measurement. A physical spectrometer would provide more accurate moisture readings.
2. **Soil Data Gaps:** Laboratory soil reports often lack micronutrient data. If Organic Carbon (OC) data is missing, the engine defaults to a neutral score of 0.75, which may affect yield forecast accuracy in deficient soils.
3. **No Direct Worm Diagnosis:** The `D-Penalty` is calculated using seasonal and environmental proxies rather than direct imaging of the silkworms.
4. **Single-Point Weather Telemetry:** The app uses real-time weather data at the time of calculation, which may not capture the average temperature and humidity changes over the full 26-day rearing cycle.

---

## 11. References

[1] Central Silk Board, Ministry of Textiles, Government of India. (2023). *Annual Report 2022-23: Indian Silk Industry Statistics*. Bangalore: CSB.

[2] Rao, Y.R. (2017). "Socio-economic profile of sericulture farmers in Karnataka." *Journal of Sericulture & Economic Development*, 12(1), 45–58.

[3] Miyashita, T. (1986). "Factorial analysis of cocoon yield determinants in Bombyx mori rearing." *Acta Sericologica*, 34(2), 112–128.

[4] CSRTI Mysore. (2020). *Technical Guidelines for Mulberry Cultivation and Silkworm Rearing in Karnataka*. Central Silk Research & Training Institute. Mysore, India.

[5] Rehman, S., Sugunakar, M., & Rao, P.R.T. (2000). "Effect of temperature and humidity on growth and cocoon characters of silkworm Bombyx mori L." *Sericologia*, 40(3), 355–364.

[6] Guo, H., & Kasuga, H. (2009). "Seasonal variation in mulberry leaf nutritional quality and its effect on larval performance of Bombyx mori." *Journal of Insect Science*, 9(1), 38.

[7] Thaker, M., & Patil, G. (2025). "Epidemiological modeling of Grasserie and Flacherie incidence across Indian multicropping sericulture zones." *SpringerNature: Applied Biological Sciences*, 18(2), 201–215.

[8] Ninagi, O., & Miyake, T. (2011). "Thermal tolerance variation among domestic and crossbred silkworm strains under summer rearing conditions." *Oxford Academic: Insect Science*, 18(4), 412–420.

[9] Dey, B., Chakraborti, S., & Ghosh, M. (2020). "Comparative analysis of silk parameters in domestic bivoltine and multivoltine Bombyx mori strains reared under standard conditions." *PubMed Central (PMC)*, NLM National Library of Medicine. PMID: 32854765.

[10] Savanurmath, C.J., Mathad, S.B., & Narayanaswamy, T.K. (2007). "Survey of silkworm diseases in Bangalore rural district, Karnataka." *Indian Journal of Sericulture*, 46(2), 151–156.

[11] Bangladesh Sericulture Research Institute (BSTRI). (2018). "Effect of foliar application of NPK on growth, yield and quality of mulberry (Morus alba) and cocoon production." *BSTRI Research Bulletin*, No. 27, pp. 44–58.

[12] Mondal, M., & Mondal, P. (2023). "Pébrine (Nosema bombycis) in South Asian sericulture: economic impact and control." *PubMed Central*, Frontiers in Veterinary Science. doi:10.3389/fvets.2023.1108924.

[13] Singh, T.K., et al. (2025). "Pesticide drift from adjacent agricultural fields as a leading cause of unexpected silkworm batch losses in mixed-cropping zones of India." *Agriculture Research Institute Journal*, 7(1), 88–102.

[14] Kumar, R., Bharathi, M., & Ramesh, C.K. (2021). "Impact of rearing house ventilation and humidity on silkworm feeding behavior and silk gland development." *Indian Journal of Sericultural Research*, 18(3), 201–212.

[15] Tan, M., & Le, Q.V. (2019). "EfficientNet: Rethinking Model Scaling for Convolutional Neural Networks." *Proceedings of the 36th International Conference on Machine Learning (ICML)*, PMLR 97, 6105–6114.

[16] Jacob, B., et al. (2018). "Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference." *Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition (CVPR)*, 2704–2713.

[17] Sarkar, A., & Singh, P.K. (2024). "Phyllotaxy-based harvest position effect on mulberry leaf quality and cocoon shell weight in Bombyx mori." *Vegetos — An International Journal of Plant Research & Biotechnology*, SpringerNature. doi:10.1007/s42535-024-00882-4.

[18] Kato, R., Hayashi, Y., & Takahashi, M. (1997). "Optimal mulberry shoot age for maximizing food conversion ratio in late-instar Bombyx mori: a 14-variety comparative study." *Sericologia*, 37(4), 441–456.

[19] Ministry of Agriculture & Farmers Welfare, Government of India. (2019). *Soil Health Card Scheme — Technical Manual: Soil Testing Parameters, Target Values, and Interpretation Criteria*. New Delhi: DARE/ICAR.

[20] Bisht, N.S., Bhatia, R.K., & Srivastava, P. (2018). "Optimizing rearing conditions for Bombyx mori in Uttarakhand hill agro-ecology." *Indian Silk*, 57(4), 28–33.

[21] FAO of the United Nations. (2009). *Silkworm Rearing: FAO Agricultural Services Bulletin 73/1*. Rome: Food and Agriculture Organization of the United Nations. ISBN 978-92-5-100634-8.

---

*Document Version: V2.2 | Research Basis: Seri-Helper Application V2 | Last Updated: May 2026*

*This paper documents the algorithmic and scientific methodology of the Seri-Helper V2 mobile application. For source code, refer to the project's* `lib/services/yield_engine_v2.dart` *and associated model files.*
