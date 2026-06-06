# 🐛 Seri-Helper: AI-Powered Sericulture Yield Optimizer

![Seri-Helper Banner](https://img.shields.io/badge/Status-Production_Ready-success?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![TensorFlow Lite](https://img.shields.io/badge/TensorFlow_Lite-AI-orange?style=for-the-badge&logo=tensorflow)
![Groq AI](https://img.shields.io/badge/Groq-Llama_3-black?style=for-the-badge)

**Seri-Helper** is a state-of-the-art, AI-driven mobile application designed to revolutionize sericulture (silk farming). By combining Edge AI computer vision with cloud-based Large Language Models, the app provides real-time, highly accurate silk cocoon yield predictions based on holistic farm conditions.

## ✨ Key Features

- **🌿 AI Leaf Quality Scanner**: Uses a custom-trained **EfficientNetB0** model running on-device (via TFLite) to detect mulberry leaf diseases (Red Rust, Leaf Spot, Powdery Mildew) and grade nutritional quality instantly.
- **🌍 Soil Health Card Extraction**: Integrates with **Groq (Llama-4 Vision)** to instantly digitize physical Soil Health Cards using the device camera, extracting 11 critical soil parameters automatically.
- **🌡️ Live Climate Simulation**: Fetches real-time GPS weather data (Temperature & Humidity) and allows farmers to simulate "what-if" scenarios to see how micro-climate adjustments affect cocoon yield.
- **🧬 Comprehensive Yield Engine V2**: A scientifically-backed algorithm that calculates an expected yield (in kg / 100 DFLs) based on a 5-factor breakdown:
  - **FQI** (Foliage Quality Index)
  - **CCI** (Climate Conditions Index)
  - **SHI** (Soil Health Index)
  - **D-Penalty** (Disease Risk Penalty)
  - **BM-Factor** (Breed & Management Multiplier)
- **🌐 Bilingual Support**: Full UI localization in English and Marathi (मराठी) to support local farming communities.

## 📱 App Walkthrough

1. **Batch Configuration**: Define rearing season, silkworm breed (e.g., CSR Bivoltine), and hygiene protocols.
2. **Leaf Analysis**: Snap a picture of a mulberry leaf to assess its suitability for specific silkworm instars.
3. **Soil Analysis**: Scan a laboratory soil report to input NPK, pH, and micronutrient data.
4. **Yield Dashboard**: View the unified dashboard that synthesizes all data streams into an actionable yield forecast, highlighting primary bottlenecks and suggesting targeted agricultural interventions.

## 🛠️ Technology Stack

- **Frontend Application**: Flutter (Dart) with Impeller graphics.
- **On-Device AI**: TensorFlow Lite (`tflite_flutter`) for rapid, offline image classification.
- **Cloud AI**: Groq API for lightning-fast multimodal OCR and data extraction from soil cards.
- **Backend Storage**: Firebase Firestore for archiving historical yield reports.
- **State Management**: Provider architecture for reactive UI updates.

## ⚙️ Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/Mulberry_Yield_Project.git
   cd Mulberry_Yield_Project/seri_helper
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the App**:
   Connect a physical device or emulator, then run:
   ```bash
   flutter run
   ```

## 📖 User Guide & FAQ

Are you a researcher or farmer looking to understand the scientific metrics behind the app? Please refer to the comprehensive [User Guide in English](USER_GUIDE.md), [User Guide in Marathi (मराठी)](USER_GUIDE_MR.md), or the [FAQ & Technical Guide](FAQ_AND_GUIDE.md) for detailed step-by-step instructions and definitions on Shoot Age, DFLs, Leaf Positions, soil metrics, and climate impact.

## 🔬 Research & Model Training

The foundational computer vision models were trained on a highly curated Mulberry Leaf Dataset. The training pipeline, data augmentation strategies, and evaluation metrics (Confusion Matrices, Precision/Recall) can be found in the `notebooks/` directory of this repository.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.
