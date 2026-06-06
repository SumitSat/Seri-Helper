# 🌿 Seri-Helper: Task Checklist

This checklist tracks the collaborative implementation of the Seri-Helper application, dividing responsibilities between the AI Agent and the User.

## 🧠 Part 1: Machine Learning Optimization (Python)
- [x] **Agent**: Write Python script for Full Integer Quantization & metadata addition.
- [x] **User**: Run the Python script to convert the existing `.keras` model to an optimized `.tflite` model.

## 🏗️ Part 2: Flutter App Foundation & Firebase Setup
- [x] **User**: Run the `flutter create seri_helper` command in the terminal.
- [x] **Agent**: Provide `pubspec.yaml` dependencies and initial Dart boilerplate (theming, routing).
- [x] **User**: Create a new Firebase project (Spark Plan) via the Firebase Web Console.
- [x] **User**: Enable Firestore Database and Authentication (Email/Anonymous) in Firebase.
- [x] **User**: Download `google-services.json` and place it in the correct Flutter Android directory.

## 🍃 Part 3: Foliage Grading Module (Computer Vision)
- [x] **Agent**: Write Dart code for the camera interface, cropping, and image preprocessing.
- [x] **Agent**: Implement TFLite model inference and the "Safety-First Thresholding" logic.
- [x] **Agent**: Build the "Reasoning" Results UI to display the leaf grade and biological reasoning.
- [x] **User**: Compile and test the camera and grading speeds on a physical Android device.

## 🧪 Part 4: Pedological Informatics (Gemini LLM)
- [x] **Agent**: Design the System Prompt for Gemini (including English/Marathi few-shot examples).
- [x] **Agent**: Integrate the `google_generative_ai` SDK and build the "Human-in-the-loop" validation UI.
- [x] **User**: Generate a free API key (Groq) for soil health card parsing.
- [x] **User**: Save the API key securely in the project code.
- [x] **User**: Provide 1-2 sample Soil Health Card images to test the extraction prompt.

## 🌤️ Part 5: Yield Engine & Dashboard
- [x] **Agent**: Build Firestore database schemas and the daily environmental log UI.
- [x] **Agent**: Implement the mathematical yield calculation engine.
- [x] **Agent**: Integrate OpenWeatherMap API & GPS coordinates lookup.
- [ ] **User**: (Optional) Register for a free OpenWeatherMap API key if GPS-based weather fetching is desired.

## 🚀 Part 6: Deployment & Play Store
- [x] **Agent**: Write the Privacy Policy text.
- [x] **Agent**: Implement Marathi/English multi-language support and resolve final UI/UX items.
- [ ] **User**: Run the `flutter build appbundle` command to generate the release build.
- [ ] **User**: Upload the App Bundle to the Google Play Developer Console.
