import json

target_path = r"C:\Users\Shashwat\OneDrive\Desktop\Mulberry_Yield_Project\notebook4bd5bed4ee.ipynb"

with open(target_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

def lines(s):
    return s.splitlines(keepends=True)

# ─────────────────────────────────────────────
# CELL 13 — Model Architecture
# Fix: cache the weights locally so Kaggle doesn't need internet after the first run.
# We also add a clear note telling user to turn on internet ONCE to cache the weights.
# ─────────────────────────────────────────────
new_cell_13 = """NUM_CLASSES = len(CLASS_NAMES)

# -------------------------------------------------------
# IMPORTANT FOR KAGGLE USERS:
# The first time you run this notebook, you MUST enable internet access:
#   Kaggle Notebook → Settings (right panel) → Internet → Turn ON
# After the first run, weights are cached in /root/.keras/models/
# and you can turn internet back off.
# -------------------------------------------------------

import os

# Check if weights are already cached locally (avoids network call on re-runs)
WEIGHTS_CACHE = os.path.expanduser('~/.keras/models/efficientnetb0_notop.h5')
WEIGHTS_ARG   = 'imagenet'   # 'imagenet' downloads if not found; None = random init

if not os.path.exists(WEIGHTS_CACHE):
    print("[INFO] Pre-trained weights not cached yet.")
    print("[INFO] Ensure Internet is ON in Kaggle Settings for this first run.")
else:
    print(f"[INFO] Pre-trained weights found at: {WEIGHTS_CACHE}")

def build_model(num_classes, freeze_base=True):
    \"\"\"
    EfficientNetB0 + custom classification head.
    freeze_base=True  -> warm-up phase (only head trains)
    freeze_base=False -> fine-tuning phase (full network trains)
    \"\"\"
    base_model = EfficientNetB0(
        include_top=False,
        weights=WEIGHTS_ARG,
        input_shape=(IMG_SIZE, IMG_SIZE, 3)
    )
    base_model.trainable = not freeze_base

    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = base_model(inputs, training=not freeze_base)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.60)(x)
    x = layers.Dense(256, activation='relu',
                     kernel_regularizer=keras.regularizers.l2(1e-4))(x)
    x = layers.Dropout(0.50)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)

    model = keras.Model(inputs, outputs)
    return model, base_model

# Phase 1: warm-up
model, base_model = build_model(NUM_CLASSES, freeze_base=True)
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)
model.summary()
"""

# ─────────────────────────────────────────────
# CELL 22 — Quality Grade Evaluation
# Fix: remove CONFIDENCE_THRESHOLD reference, use the hybrid greenness logic thresholds.
# ─────────────────────────────────────────────
new_cell_22 = """# --- Map to Quality grades ---
# Identify index of each healthy class
healthy_indices = set()
for cls in HEALTHY_CLASSES:
    if cls in CLASS_INDICES:
        healthy_indices.add(CLASS_INDICES[cls])

def get_quality_label(pred_class_idx, pred_proba_row):
    \"\"\"
    Maps raw model output to quality grade.
    Diseased classes -> Poor (> 50% confidence)
    Healthy class -> graded by neural network confidence as proxy
                     (full CV greenness check is done at inference time)
    \"\"\"
    confidence = float(pred_proba_row[pred_class_idx])
    if pred_class_idx in healthy_indices:
        if confidence >= 0.90:
            return 'Excellent'
        elif confidence >= 0.70:
            return 'Medium'
        else:
            return 'Poor'  # very low confidence healthy prediction
    else:
        if confidence >= 0.50:
            return 'Poor'
        else:
            return 'Medium'   # Ambiguous low-confidence diseased prediction

# Map predictions to quality grades
quality_preds = [
    get_quality_label(pred_class_idx=preds_class[i], pred_proba_row=preds_proba[i])
    for i in range(len(preds_class))
]

# Compute per-class expected quality (ground truth)
quality_true = []
for true_idx in true_class:
    if true_idx in healthy_indices:
        quality_true.append('Healthy (Disease-Free)')
    else:
        quality_true.append('Diseased (Poor)')

# --- Quality distribution summary ---
from collections import Counter
print("\\n" + "=" * 50)
print("Quality Grade Distribution on Validation Set")
print("=" * 50)
grade_counts = Counter(quality_preds)
total = len(quality_preds)
for grade in ['Excellent', 'Medium', 'Poor']:
    count = grade_counts.get(grade, 0)
    print(f"  {grade:12s}: {count:4d} / {total}  ({count/total:.1%})")
print("=" * 50)
"""

# ─────────────────────────────────────────────
# CELL 26 — Demo Inference
# Fix: clean up old signature (remove leftover args)
# ─────────────────────────────────────────────
new_cell_26 = """# -------------------------------------------------------
# Demo: pick one image from each class and run inference
# -------------------------------------------------------
demo_images = {}
for cls in CLASS_NAMES:
    cls_path = os.path.join(DATASET_ROOT, cls)
    imgs = [f for f in os.listdir(cls_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    if len(imgs) > 5:
        demo_images[cls] = os.path.join(cls_path, imgs[5])   # pick 6th image as demo

for cls_name, img_path in demo_images.items():
    print(f"\\n{'='*60}")
    print(f"Input class: {cls_name}")
    result = predict_leaf_quality(
        image_path=img_path,
        model=model,
        class_indices=CLASS_INDICES,
        healthy_classes=HEALTHY_CLASSES,
        img_size=IMG_SIZE
    )
    display_prediction(img_path, result)
"""

# ─────────────────────────────────────────────
# CELL 28 — Custom Image Prediction
# Fix: clean up old signature
# ─────────────────────────────────────────────
new_cell_28 = """# -------------------------------------------------------
# CHANGE THIS PATH to your own uploaded image
# -------------------------------------------------------
MY_IMAGE_PATH = '/kaggle/working/my_leaf.jpg'

if os.path.exists(MY_IMAGE_PATH):
    result = predict_leaf_quality(
        image_path=MY_IMAGE_PATH,
        model=model,
        class_indices=CLASS_INDICES,
        healthy_classes=HEALTHY_CLASSES,
        img_size=IMG_SIZE
    )
    display_prediction(MY_IMAGE_PATH, result)
else:
    print(f"[INFO] No custom image found at '{MY_IMAGE_PATH}'.")
    print("Upload a leaf image to /kaggle/working/ and update MY_IMAGE_PATH above.")
"""

# ─────────────────────────────────────────────
# CELL 30 — Save Model
# Fix: remove .h5 format (causes pickle error), remove CONFIDENCE_THRESHOLD reference
# ─────────────────────────────────────────────
new_cell_30 = """# Save model in native Keras format (recommended, .h5 is legacy and causes pickle errors)
model.save('/kaggle/working/mulberry_quality_classifier.keras')
print("Model saved as mulberry_quality_classifier.keras")

# Save metadata
import json as _json
meta = {
    'class_indices': CLASS_INDICES,
    'healthy_classes': HEALTHY_CLASSES,
    'diseased_classes': DISEASED_CLASSES,
    'img_size': IMG_SIZE,
    'greenness_thresholds': {
        'Excellent': 0.85,
        'Medium_lower': 0.60,
        'Poor_below': 0.60
    },
    'disease_confidence_threshold': 0.50
}
with open('/kaggle/working/model_metadata.json', 'w') as f:
    _json.dump(meta, f, indent=2)

print("Metadata saved to /kaggle/working/model_metadata.json")
fpath = '/kaggle/working/mulberry_quality_classifier.keras'
if os.path.exists(fpath):
    size_mb = os.path.getsize(fpath) / (1024 * 1024)
    print(f"  mulberry_quality_classifier.keras  ({size_mb:.1f} MB)")
"""

# Apply all patches
patches = {
    13: new_cell_13,
    22: new_cell_22,
    26: new_cell_26,
    28: new_cell_28,
    30: new_cell_30,
}

for idx, code in patches.items():
    if idx < len(nb['cells']) and nb['cells'][idx]['cell_type'] == 'code':
        nb['cells'][idx]['source'] = lines(code)
        nb['cells'][idx]['outputs'] = []
        print(f"Patched Cell {idx}")
    else:
        print(f"WARNING: Cell {idx} not found or is not a code cell!")

# Save
with open(target_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("\nAll patches applied successfully!")
