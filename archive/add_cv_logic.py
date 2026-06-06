import json

target_path = r"C:\Users\Shashwat\OneDrive\Desktop\notebook4bd5bed4ee.ipynb"

with open(target_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

new_cell_24 = """def calculate_greenness_index(image_bgr):
    \"\"\"
    Converts an image to HSV color space, isolates the leaf by masking out the background,
    and calculates the percentage of 'Vital Green' pixels indicating chlorophyll levels.
    
    Returns the percentage (0.0 to 1.0) and the masked leaf for visualization.
    \"\"\"
    import cv2
    import numpy as np
    
    # 1. Isolate the leaf from the background
    # Convert to grayscale and apply Otsu's thresholding
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    
    # Use morphological operations to refine the mask
    kernel = np.ones((5,5), np.uint8)
    leaf_mask = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_OPEN, kernel)
    
    # 2. Analyze the hue in the HSV color space
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    
    # Define the 'Vital Green' bounds in HSV (OpenCV Hue ranges from 0-179)
    # Healthy leaves usually fall between Hue 35 (yellow-green) and 85 (cyan-green)
    lower_green = np.array([35, 40, 40])
    upper_green = np.array([85, 255, 255])
    
    # Create mask for green pixels
    green_mask = cv2.inRange(hsv, lower_green, upper_green)
    
    # Only consider green pixels that are actually part of the leaf
    vital_green_pixels = cv2.bitwise_and(green_mask, leaf_mask)
    
    # 3. Calculate percentage
    total_leaf_pixels = cv2.countNonZero(leaf_mask)
    if total_leaf_pixels == 0:
        return 0.0, leaf_mask
        
    green_pixel_count = cv2.countNonZero(vital_green_pixels)
    greenness_index = green_pixel_count / total_leaf_pixels
    
    return greenness_index, vital_green_pixels


def predict_leaf_quality(image_path, model, class_indices, healthy_classes,
                         img_size=224):
    \"\"\"
    Phase 1 (AI): Detects pathological diseases via EfficientNetB0.
    Phase 2 (CV): If disease-free, analyzes chlorophyll/freshness via OpenCV HSV masking.

    Parameters
    ----------
    image_path         : str   — path to the input image
    model              : keras Model
    class_indices      : dict  — {class_name: index} from training generator
    healthy_classes    : list  — names of healthy folder(s)
    img_size           : int   — model input size (default 224)
    \"\"\"
    import cv2
    import numpy as np
    
    # 1. Load and preprocess for Neural Network
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not load image: {image_path}")
        
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (img_size, img_size))
    img_norm = img_resized.astype('float32') / 255.0
    img_batch = np.expand_dims(img_norm, axis=0)    # shape: (1, H, W, 3)

    # 2. Phase 1: AI Disease Prediction
    proba = model.predict(img_batch, verbose=0)[0]  
    pred_idx = int(np.argmax(proba))
    idx_to_cls = {v: k for k, v in class_indices.items()}
    pred_class_name = idx_to_cls[pred_idx]
    pred_confidence = float(proba[pred_idx])

    # Check if AI considers it diseased
    h_indices = {class_indices[hc] for hc in healthy_classes if hc in class_indices}
    is_diseased = (pred_idx not in h_indices)
    
    # 3. Phase 2: Computer Vision Vital Greenness Analysis
    greenness_index, green_mask = calculate_greenness_index(img)
    
    # 4. Hybrid Grading Logic
    if is_diseased and pred_confidence >= 0.50:
        # AI confirms disease pathogen
        quality = 'Poor'
        reason = f"Disease detected: {pred_class_name} ({pred_confidence:.1%})"
    elif not is_diseased:
        # AI confirms no disease. Now grade nutritional/freshness quality via CV
        if greenness_index >= 0.85:
            quality = 'Excellent'
            reason = f"High Freshness (Chlorophyll: {greenness_index:.1%})"
        elif greenness_index >= 0.60:
            quality = 'Medium'
            reason = f"Moderate Freshness/Mild Chlorosis (Chlorophyll: {greenness_index:.1%})"
        else:
            quality = 'Poor'
            reason = f"Senescent/Dry (Chlorophyll: {greenness_index:.1%})"
    else:
        quality = 'Medium'
        reason = f"Ambiguous Disease Symptoms ({pred_confidence:.1%})"

    all_probs = {idx_to_cls[i]: round(float(proba[i]), 4) for i in range(len(proba))}

    return {
        'quality': quality,
        'reason': reason,
        'is_diseased': is_diseased,
        'raw_class': pred_class_name,
        'confidence': pred_confidence,
        'all_probs': all_probs,
        'greenness_index': greenness_index,
        'green_mask': green_mask
    }


def display_prediction(image_path, result):
    \"\"\"Visualise the image alongside the hybrid AI+CV prediction verdict.\"\"\"
    import cv2
    import matplotlib.pyplot as plt
    
    img = cv2.imread(image_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    quality_colors = {'Excellent': '#2ecc71', 'Medium': '#f39c12', 'Poor': '#e74c3c'}
    quality_icons  = {'Excellent': '✅', 'Medium': '⚠️', 'Poor': '❌'}
    q = result['quality']

    fig, axes = plt.subplots(1, 3, figsize=(16, 5))

    # A: Original Image
    axes[0].imshow(img_rgb)
    axes[0].set_title(
        f"{quality_icons[q]} Grade: {q}\\n"
        f"AI Class: {result['raw_class']} ({result['confidence']:.0%})",
        fontsize=11, fontweight='bold', color=quality_colors[q]
    )
    axes[0].axis('off')

    # B: CV Chlorophyll Mask
    axes[1].imshow(result['green_mask'], cmap='Greens')
    axes[1].set_title(
        f"CV Phase: Vital Greenness Map\\n"
        f"Chlorophyll Index: {result['greenness_index']:.1%}",
        fontsize=11, fontweight='bold'
    )
    axes[1].axis('off')

    # C: Probability Bars
    classes = list(result['all_probs'].keys())
    probs = list(result['all_probs'].values())
    bar_colors = ['#e74c3c' if c not in HEALTHY_CLASSES else '#2ecc71' for c in classes]
    bars = axes[2].barh(classes, probs, color=bar_colors, edgecolor='white')
    for bar_item, prob in zip(bars, probs):
        axes[2].text(bar_item.get_width() + 0.01, bar_item.get_y() + bar_item.get_height() / 2,
                    f'{prob:.2%}', va='center', fontsize=10)
    axes[2].set_xlim(0, 1.15)
    axes[2].set_xlabel('Probability')
    axes[2].set_title('AI Logits / Disease Probabilities', fontsize=11, fontweight='bold')
    axes[2].grid(axis='x', alpha=0.3)

    plt.tight_layout()
    plt.show()

    print("\\n" + "=" * 60)
    print(f"  FINAL HYBRID VERDICT : {quality_icons[q]} {q}")
    print("=" * 60)
    print("  " + result['reason'])
    if q == 'Excellent':
        print("  → Result: Disease-Free + Peak Nutritional Yield.")
    elif q == 'Medium':
        print("  → Result: Disease-Free + Suboptimal Moisture/Chlorophyll.")
    elif result['is_diseased']:
        print("  → Result: Pathogen detected. Discard immediately.")
    else:
        print("  → Result: Unfit for yield due to severe yellowing/drying.")
    print("=" * 60)


print("Hybrid AI+CV inference module configured successfully.")
"""

def string_chunk_list(code_str):
    return code_str.splitlines(keepends=True)

if 24 < len(nb['cells']):
    nb['cells'][24]['source'] = string_chunk_list(new_cell_24)

    # Save the updated file
    with open(target_path, 'w', encoding='utf-8') as f:
        json.dump(nb, f, indent=1)
    
    print("CV Integration Complete.")
else:
    print("Cell 24 not found or index mismatch. Check parsed configuration.")
