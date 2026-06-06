import json

target_path = r"C:\Users\Shashwat\OneDrive\Desktop\Mulberry_Yield_Project\notebook4bd5bed4ee.ipynb"

with open(target_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

def lines(s):
    return s.splitlines(keepends=True)

# ═══════════════════════════════════════════════════════════════════
# CELL 10 — Data Loading & Augmentation
#
# ROOT CAUSE FIX: EfficientNetB0 was pretrained with its own internal
# normalization. It expects raw [0–255] pixels and applies:
#     x = (x / 127.5) - 1
# internally via preprocess_input().
#
# Using rescale=1./255 delivered [0–1] inputs → model received
# completely wrong signal from epoch 1 → single-class collapse.
#
# Fix: Use preprocessing_function=preprocess_input instead of rescale.
# ═══════════════════════════════════════════════════════════════════
new_cell_10 = """# ----- Configuration -----
IMG_SIZE       = 224   # EfficientNetB0 native input size
BATCH_SIZE     = 32
EPOCHS_WARMUP  = 10    # warm-up: only head trains (frozen base)
EPOCHS_FINETUNE= 30    # fine-tune: last 30 layers unfrozen
SEED           = 42

# ---------------------------------------------------------------
# CRITICAL FIX: Use EfficientNetB0's own preprocessor, NOT rescale.
# EfficientNetB0 expects raw [0-255] pixels and normalizes
# them internally to [-1, 1] via preprocess_input().
# Applying rescale=1./255 breaks the pretrained feature space.
# ---------------------------------------------------------------
from tensorflow.keras.applications.efficientnet import preprocess_input

# Augmentation for training — moderate range to avoid destroying signal
train_datagen = ImageDataGenerator(
    preprocessing_function=preprocess_input,   # ← THE CORE FIX
    validation_split=0.20,
    rotation_range=30,
    width_shift_range=0.15,
    height_shift_range=0.15,
    shear_range=0.10,
    zoom_range=0.20,
    horizontal_flip=True,
    vertical_flip=False,      # leaves don't flip vertically in nature
    brightness_range=[0.8, 1.2],
    fill_mode='reflect'
)

# Validation: ONLY preprocessing — no augmentation, never rescale
val_datagen = ImageDataGenerator(
    preprocessing_function=preprocess_input,   # ← same preprocessor
    validation_split=0.20
)

train_generator = train_datagen.flow_from_directory(
    DATASET_ROOT,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    seed=SEED,
    shuffle=True
)

val_generator = val_datagen.flow_from_directory(
    DATASET_ROOT,
    target_size=(IMG_SIZE, IMG_SIZE),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation',
    seed=SEED,
    shuffle=False
)

CLASS_INDICES  = train_generator.class_indices        # {class_name: index}
INDEX_TO_CLASS = {v: k for k, v in CLASS_INDICES.items()}
NUM_CLASSES    = len(CLASS_NAMES)

print("Class index mapping:", CLASS_INDICES)
print(f"Training samples  : {train_generator.samples}")
print(f"Validation samples: {val_generator.samples}")

# ── Compute balanced class weights to handle data imbalance ──────
from sklearn.utils.class_weight import compute_class_weight
import numpy as np

train_classes  = train_generator.classes
weights        = compute_class_weight('balanced',
                                      classes=np.unique(train_classes),
                                      y=train_classes)
class_weight_dict = dict(enumerate(weights))
print("\\nClass weights (higher = rarer class gets more attention):")
for idx, w in class_weight_dict.items():
    print(f"  [{idx}] {INDEX_TO_CLASS[idx]:25s} weight = {w:.4f}")
"""

# ═══════════════════════════════════════════════════════════════════
# CELL 13 — Model Architecture
#
# Fix: Use LOWER dropout (0.30 / 0.20) during the warmup phase.
# During warmup only a 256-neuron head is learning on top of frozen
# EfficientNet features. With Dropout(0.60/0.50) over half the
# gradient signal was destroyed every step — the head couldn't
# converge. Lower dropout lets the head first establish a good
# decision boundary, then fine-tuning regularizes it further.
# ═══════════════════════════════════════════════════════════════════
new_cell_13 = """# -------------------------------------------------------
# IMPORTANT FOR KAGGLE USERS (first run only):
#   Kaggle Notebook -> Settings -> Internet -> Turn ON
# Weights are cached after first download to ~/.keras/models/
# -------------------------------------------------------
import os

WEIGHTS_CACHE = os.path.expanduser('~/.keras/models/efficientnetb0_notop.h5')
if not os.path.exists(WEIGHTS_CACHE):
    print("[INFO] Weights not cached yet — ensure Internet is ON for this run.")
else:
    print(f"[INFO] Cached weights found at: {WEIGHTS_CACHE}")

def build_model(num_classes, dropout1=0.30, dropout2=0.20, freeze_base=True):
    \"\"\"
    EfficientNetB0 + custom classification head.

    dropout1 / dropout2 are intentionally LOWER during warmup so the
    small head (256 neurons, 3 classes) can converge from frozen
    EfficientNet features. Fine-tuning uses higher dropout to
    regularize the full unlocked network.

    freeze_base=True  -> warmup phase  (head-only training)
    freeze_base=False -> fine-tune phase (last-30-layers unlocked)
    \"\"\"
    base_model = EfficientNetB0(
        include_top=False,
        weights='imagenet',
        input_shape=(IMG_SIZE, IMG_SIZE, 3)
    )
    base_model.trainable = not freeze_base

    inputs = keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
    x = base_model(inputs, training=not freeze_base)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(dropout1)(x)
    x = layers.Dense(256, activation='relu',
                     kernel_regularizer=keras.regularizers.l2(1e-4))(x)
    x = layers.Dropout(dropout2)(x)
    outputs = layers.Dense(num_classes, activation='softmax')(x)

    return keras.Model(inputs, outputs), base_model

# ── Phase 1: warmup model — lower dropout, frozen base ───────────
model, base_model = build_model(NUM_CLASSES,
                                dropout1=0.30,
                                dropout2=0.20,
                                freeze_base=True)
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)
model.summary()
"""

# ═══════════════════════════════════════════════════════════════════
# CELL 15 — Warmup Training
# Increase warmup to 10 epochs to give the head proper convergence time
# ═══════════════════════════════════════════════════════════════════
new_cell_15 = """callbacks_warmup = [
    EarlyStopping(monitor='val_accuracy', patience=4,
                  restore_best_weights=True, verbose=1),
    ModelCheckpoint('/kaggle/working/best_warmup.keras',
                    monitor='val_accuracy', save_best_only=True, verbose=1)
]

history_warmup = model.fit(
    train_generator,
    epochs=EPOCHS_WARMUP,
    validation_data=val_generator,
    callbacks=callbacks_warmup,
    class_weight=class_weight_dict,
    verbose=1
)

warmup_best_val = max(history_warmup.history['val_accuracy'])
print(f"\\nWarm-up complete. Best val accuracy: {warmup_best_val:.4f}")
"""

# ═══════════════════════════════════════════════════════════════════
# CELL 17 — Fine-tuning
#
# Fixes:
# 1. Load best warmup weights BEFORE unfreezing base layers.
# 2. Rebuild model with HIGHER dropout (0.50/0.40) since now the
#    full network is being regularized — not just the head.
# 3. Transfer warmup head weights to the new model so we don't lose
#    the head convergence achieved in Phase 1.
# 4. Pass initial_epoch so callbacks & LR schedulers count correctly.
# ═══════════════════════════════════════════════════════════════════
new_cell_17 = """# ── Load best warmup checkpoint ──────────────────────────────────
model = keras.models.load_model('/kaggle/working/best_warmup.keras')

# ── Rebuild with higher dropout for fine-tuning regularization ────
# We transfer the trained head weights into a new model that uses
# higher Dropout(0.50 / 0.40) now that the full network will train.
warmup_weights = model.get_weights()

ft_model, ft_base = build_model(NUM_CLASSES,
                                 dropout1=0.50,
                                 dropout2=0.40,
                                 freeze_base=False)

# Copy weights: only set if shapes match (head layers line up after index 2)
ft_model.set_weights(warmup_weights)

# Freeze first (total - 30) layers of the base — only last 30 unfreeze
layers_to_freeze = len(ft_base.layers) - 30
for layer in ft_base.layers[:layers_to_freeze]:
    layer.trainable = False

print(f"Fine-tuning: {sum(1 for l in ft_model.layers if l.trainable)} trainable layers")

ft_model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=5e-5),   # lower LR for fine-tune
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

callbacks_finetune = [
    EarlyStopping(monitor='val_accuracy', patience=5,
                  restore_best_weights=True, verbose=1),
    ModelCheckpoint('/kaggle/working/best_model.keras',
                    monitor='val_accuracy', save_best_only=True, verbose=1),
    ReduceLROnPlateau(monitor='val_loss', factor=0.3,
                      patience=3, min_lr=1e-7, verbose=1)
]

train_generator.reset()
val_generator.reset()

warmup_epochs_ran = len(history_warmup.history['accuracy'])

history_finetune = ft_model.fit(
    train_generator,
    epochs=warmup_epochs_ran + EPOCHS_FINETUNE,
    initial_epoch=warmup_epochs_ran,           # ← correctly continues epoch count
    validation_data=val_generator,
    callbacks=callbacks_finetune,
    class_weight=class_weight_dict,
    verbose=1
)

# Use ft_model as the active model for all subsequent cells
model = ft_model

print(f"\\nFine-tuning complete.")
print(f"Best val accuracy: {max(history_finetune.history['val_accuracy']):.4f}")
"""

# ═══════════════════════════════════════════════════════════════════
# CELL 22 — Honest Hybrid Quality Evaluation
#
# Fix: The previous Cell 22 just used raw AI confidence for quality
# grading, which was meaningless when the model is collapsed.
# Now we do the HONEST evaluation:
# - Run the full Hybrid AI+CV pipeline on actual validation images
# - Compare prediction vs ground truth
# - Report the real quality distribution
# ═══════════════════════════════════════════════════════════════════
new_cell_22 = """# ── Calibrate greenness thresholds from actual healthy training images ──
# Instead of hardcoded arbitrary numbers, we measure the actual
# greenness distribution of known-healthy images to set thresholds.

import cv2, numpy as np, os
from pathlib import Path

def calculate_greenness_index(image_bgr):
    \"\"\"
    Measures the fraction of leaf pixels in the 'Vital Green' HSV range.
    Background is removed via Otsu thresholding.
    Returns (greenness_ratio, green_pixel_mask)
    \"\"\"
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    _, leaf_mask = cv2.threshold(gray, 0, 255,
                                  cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    kernel = np.ones((5, 5), np.uint8)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_CLOSE, kernel)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_OPEN,  kernel)

    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    # Hue 35–85 covers yellow-green to cyan-green (chlorophyll spectrum)
    lower_green = np.array([35, 40, 40])
    upper_green = np.array([85, 255, 255])
    green_mask  = cv2.inRange(hsv, lower_green, upper_green)
    vital_green = cv2.bitwise_and(green_mask, leaf_mask)

    total = cv2.countNonZero(leaf_mask)
    if total == 0:
        return 0.0, vital_green
    return cv2.countNonZero(vital_green) / total, vital_green


# ── Step 1: Calibrate thresholds from known healthy images ────────
healthy_cls_path = os.path.join(DATASET_ROOT, HEALTHY_CLASSES[0])
healthy_imgs = [f for f in os.listdir(healthy_cls_path)
                if f.lower().endswith(('.jpg', '.jpeg', '.png'))]

# Sample up to 40 healthy images for calibration
calibration_sample = healthy_imgs[:40]
greenness_scores   = []

for fname in calibration_sample:
    fpath = os.path.join(healthy_cls_path, fname)
    img   = cv2.imread(fpath)
    if img is None:
        continue
    g, _ = calculate_greenness_index(img)
    greenness_scores.append(g)

greenness_scores = np.array(greenness_scores)
mean_g = greenness_scores.mean()
std_g  = greenness_scores.std()

# Thresholds derived from population statistics of healthy leaves:
# Excellent = mean - 0.5*std and above  (upper portion of healthy distribution)
# Medium    = mean - 1.5*std to Excellent threshold
# Poor      = below mean - 1.5*std (severely deficient for a "healthy" leaf)
THRESHOLD_EXCELLENT = float(np.clip(mean_g - 0.5 * std_g, 0.40, 0.90))
THRESHOLD_MEDIUM    = float(np.clip(mean_g - 1.5 * std_g, 0.20, THRESHOLD_EXCELLENT))

print("=== Greenness Calibration (from healthy training images) ===")
print(f"  Samples used      : {len(greenness_scores)}")
print(f"  Mean greenness    : {mean_g:.3f}  ({mean_g:.1%})")
print(f"  Std dev           : {std_g:.3f}")
print(f"  Threshold EXCELLENT: >= {THRESHOLD_EXCELLENT:.3f} ({THRESHOLD_EXCELLENT:.1%})")
print(f"  Threshold MEDIUM   : >= {THRESHOLD_MEDIUM:.3f} ({THRESHOLD_MEDIUM:.1%})")
print(f"  Below MEDIUM = POOR (unhealthy despite no pathogen)")
print("=" * 55)

# ── Step 2: Identify healthy class index ──────────────────────────
healthy_indices = {CLASS_INDICES[hc] for hc in HEALTHY_CLASSES if hc in CLASS_INDICES}

# ── Step 3: Run Hybrid AI+CV on ALL validation images ─────────────
val_generator.reset()

# Reload best model
model = keras.models.load_model('/kaggle/working/best_model.keras')

preds_proba = model.predict(val_generator, verbose=1)
preds_class = np.argmax(preds_proba, axis=1)
true_class  = val_generator.classes
val_fnames  = val_generator.filenames   # relative paths from DATASET_ROOT

# Hybrid quality grading per image
quality_preds = []
quality_true  = []

for i in range(len(preds_class)):
    pred_idx    = preds_class[i]
    confidence  = float(preds_proba[i][pred_idx])
    img_abs     = os.path.join(DATASET_ROOT, val_fnames[i])

    # ── AI Phase: Disease detection ───────────────────────────────
    is_diseased = (pred_idx not in healthy_indices)

    if is_diseased and confidence >= 0.50:
        q = 'Poor'
    elif is_diseased and confidence < 0.50:
        # Low confidence disease: ambiguous — run CV to decide
        img = cv2.imread(img_abs)
        g, _ = calculate_greenness_index(img) if img is not None else (0.0, None)
        q = 'Excellent' if g >= THRESHOLD_EXCELLENT else ('Medium' if g >= THRESHOLD_MEDIUM else 'Poor')
    else:
        # ── CV Phase: Healthy leaf freshness assessment ────────────
        img = cv2.imread(img_abs)
        g, _ = calculate_greenness_index(img) if img is not None else (0.0, None)
        q = 'Excellent' if g >= THRESHOLD_EXCELLENT else ('Medium' if g >= THRESHOLD_MEDIUM else 'Poor')

    quality_preds.append(q)

    # Ground truth quality (for diseased images ground truth is always Poor)
    gt_is_healthy = (true_class[i] in healthy_indices)
    quality_true.append('Healthy' if gt_is_healthy else 'Diseased')

# ── Report ────────────────────────────────────────────────────────
from collections import Counter

print("\\n" + "=" * 60)
print("HYBRID AI+CV Quality Grade Distribution — Validation Set")
print("=" * 60)
grade_counts = Counter(quality_preds)
total = len(quality_preds)
for grade in ['Excellent', 'Medium', 'Poor']:
    count = grade_counts.get(grade, 0)
    bar = '█' * int(count / total * 30)
    print(f"  {grade:12s}: {count:4d}/{total} ({count/total:5.1%})  {bar}")
print("=" * 60)

# Breakdown: among ground-truth healthy images, what grades did we assign?
healthy_mask  = np.array([1 if q == 'Healthy' for q in quality_true else 0 for q in quality_true])
diseased_mask = 1 - healthy_mask

healthy_grade_pred = [quality_preds[i] for i in range(total) if quality_true[i] == 'Healthy']
diseased_grade_pred= [quality_preds[i] for i in range(total) if quality_true[i] == 'Diseased']

print("\\nAmong HEALTHY ground-truth images:")
hc = Counter(healthy_grade_pred)
for g in ['Excellent', 'Medium', 'Poor']:
    print(f"  {g:12s}: {hc.get(g, 0)}")

print("\\nAmong DISEASED ground-truth images:")
dc = Counter(diseased_grade_pred)
for g in ['Excellent', 'Medium', 'Poor']:
    print(f"  {g:12s}: {dc.get(g, 0)}")
"""

# ═══════════════════════════════════════════════════════════════════
# CELL 24 — Complete Hybrid Inference Pipeline
# Updated to use calibrated thresholds from Cell 22
# ═══════════════════════════════════════════════════════════════════
new_cell_24 = """def calculate_greenness_index(image_bgr):
    \"\"\"
    Measures fraction of leaf pixels in the 'Vital Green' HSV chlorophyll range.

    Pipeline:
      1. Otsu thresholding -> isolate leaf from white/uniform background
      2. Morphological cleanup -> remove noise, fill holes in leaf mask
      3. HSV conversion -> measure Hue range [35-85] (yellow-green to cyan-green)
      4. Intersect green mask with leaf mask -> count only leaf-green pixels

    Returns:
      greenness_index : float in [0.0, 1.0]
      green_mask      : binary image for visualization
    \"\"\"
    import cv2, numpy as np

    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    _, leaf_mask = cv2.threshold(gray, 0, 255,
                                  cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    kernel    = np.ones((5, 5), np.uint8)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_CLOSE, kernel)
    leaf_mask = cv2.morphologyEx(leaf_mask, cv2.MORPH_OPEN,  kernel)

    hsv        = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    lower_green = np.array([35,  40,  40])
    upper_green = np.array([85, 255, 255])
    green_mask  = cv2.inRange(hsv, lower_green, upper_green)
    vital_green = cv2.bitwise_and(green_mask, leaf_mask)

    total = cv2.countNonZero(leaf_mask)
    if total == 0:
        return 0.0, vital_green
    return cv2.countNonZero(vital_green) / total, vital_green


def predict_leaf_quality(image_path, model, class_indices,
                         healthy_classes, img_size=224):
    \"\"\"
    Two-Phase Hybrid AI + Computer Vision Leaf Quality Grader.

    Phase 1 — AI Disease Screening (EfficientNetB0):
      If model detects a known disease pathogen with >= 50% confidence
      the leaf is immediately graded POOR (discard).

    Phase 2 — CV Nutritional Assessment (OpenCV HSV):
      If AI confirms no disease, OpenCV measures the chlorophyll/green
      pixel fraction of the actual leaf image. Grade is assigned using
      calibrated thresholds derived from the dataset's own healthy images.

      Excellent : greenness >= THRESHOLD_EXCELLENT
      Medium    : greenness >= THRESHOLD_MEDIUM  (senescent or mildly depleted)
      Poor      : greenness <  THRESHOLD_MEDIUM  (non-diseased but nutritionally unfit)

    Parameters
    ----------
    image_path     : str   — absolute path to leaf image
    model          : keras Model — trained EfficientNetB0 classifier
    class_indices  : dict  — {class_name: index}
    healthy_classes: list  — list of healthy folder names
    img_size       : int   — resize target (must match model input shape)

    Returns
    -------
    dict with keys: quality, reason, is_diseased, raw_class,
                    confidence, greenness_index, all_probs, green_mask
    \"\"\"
    import cv2, numpy as np
    from tensorflow.keras.applications.efficientnet import preprocess_input

    # ── Load and preprocess for the AI (MUST use preprocess_input) ────
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Cannot load image: {image_path}")

    img_rgb     = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (img_size, img_size))
    img_preproc = preprocess_input(img_resized.astype('float32'))   # [-1, 1]
    img_batch   = np.expand_dims(img_preproc, axis=0)

    # ── Phase 1: AI disease prediction ────────────────────────────────
    proba       = model.predict(img_batch, verbose=0)[0]
    pred_idx    = int(np.argmax(proba))
    idx_to_cls  = {v: k for k, v in class_indices.items()}
    pred_class  = idx_to_cls[pred_idx]
    confidence  = float(proba[pred_idx])
    h_indices   = {class_indices[hc] for hc in healthy_classes if hc in class_indices}
    is_diseased = pred_idx not in h_indices

    # ── Phase 2: CV greenness analysis on the original image ──────────
    greenness_index, green_mask = calculate_greenness_index(img)

    # ── Grading decision matrix ────────────────────────────────────────
    # Use calibrated thresholds from Cell 22 (THRESHOLD_EXCELLENT, THRESHOLD_MEDIUM)
    # Falls back to sensible defaults if Cell 22 hasn't run yet.
    t_exc = globals().get('THRESHOLD_EXCELLENT', 0.55)
    t_med = globals().get('THRESHOLD_MEDIUM',    0.35)

    if is_diseased and confidence >= 0.50:
        quality = 'Poor'
        reason  = f"Pathogen detected: {pred_class} ({confidence:.1%} confidence)"
    elif is_diseased and confidence < 0.50:
        # Ambiguous disease signal: let CV decide
        if greenness_index >= t_exc:
            quality = 'Excellent'
        elif greenness_index >= t_med:
            quality = 'Medium'
        else:
            quality = 'Poor'
        reason = (f"Ambiguous AI signal ({confidence:.1%}) — "
                  f"CV Greenness: {greenness_index:.1%}")
    else:
        # AI confirmed healthy → grade by leaf freshness via CV
        if greenness_index >= t_exc:
            quality = 'Excellent'
            reason  = f"Disease-Free + High Chlorophyll ({greenness_index:.1%})"
        elif greenness_index >= t_med:
            quality = 'Medium'
            reason  = f"Disease-Free + Moderate Chlorophyll ({greenness_index:.1%})"
        else:
            quality = 'Poor'
            reason  = (f"Disease-Free but Severely Depleted Chlorophyll "
                       f"({greenness_index:.1%}) — leaf is senescent or dehydrated")

    all_probs = {idx_to_cls[i]: round(float(proba[i]), 4) for i in range(len(proba))}

    return {
        'quality'        : quality,
        'reason'         : reason,
        'is_diseased'    : is_diseased,
        'raw_class'      : pred_class,
        'confidence'     : confidence,
        'greenness_index': greenness_index,
        'all_probs'      : all_probs,
        'green_mask'     : green_mask
    }


def display_prediction(image_path, result):
    \"\"\"3-panel display: original image | CV greenness map | AI probability bars.\"\"\"
    import cv2, matplotlib.pyplot as plt

    img     = cv2.imread(image_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    quality_colors = {'Excellent': '#2ecc71', 'Medium': '#f39c12', 'Poor': '#e74c3c'}
    quality_icons  = {'Excellent': '✅', 'Medium': '⚠️', 'Poor': '❌'}
    q       = result['quality']
    color   = quality_colors[q]

    fig, axes = plt.subplots(1, 3, figsize=(18, 5))

    # Panel 1 — Original image + verdict title
    axes[0].imshow(img_rgb)
    axes[0].set_title(
        f"{quality_icons[q]} GRADE: {q}\\n{result['reason']}",
        fontsize=11, fontweight='bold', color=color)
    axes[0].axis('off')

    # Panel 2 — CV Vital Greenness heatmap
    axes[1].imshow(result['green_mask'], cmap='Greens')
    t_exc = globals().get('THRESHOLD_EXCELLENT', 0.55)
    t_med = globals().get('THRESHOLD_MEDIUM',    0.35)
    axes[1].set_title(
        f"CV Chlorophyll Map\\n"
        f"Greenness Index: {result['greenness_index']:.1%}  "
        f"(Exc≥{t_exc:.0%} | Med≥{t_med:.0%})",
        fontsize=11, fontweight='bold')
    axes[1].axis('off')

    # Panel 3 — AI disease probability bars
    classes = list(result['all_probs'].keys())
    probs   = list(result['all_probs'].values())
    bar_colors = ['#2ecc71' if c in HEALTHY_CLASSES else '#e74c3c' for c in classes]
    bars = axes[2].barh(classes, probs, color=bar_colors, edgecolor='white')
    for bar, prob in zip(bars, probs):
        axes[2].text(bar.get_width() + 0.01,
                     bar.get_y() + bar.get_height() / 2,
                     f'{prob:.2%}', va='center', fontsize=10)
    axes[2].set_xlim(0, 1.15)
    axes[2].set_xlabel('Probability')
    axes[2].set_title('AI Disease Probabilities', fontsize=11, fontweight='bold')
    axes[2].grid(axis='x', alpha=0.3)

    plt.tight_layout()
    plt.show()

    print("\\n" + "=" * 60)
    print(f"  HYBRID VERDICT : {quality_icons[q]} {q}")
    print("=" * 60)
    print(f"  {result['reason']}")
    print("-" * 60)
    if q == 'Excellent':
        print("  Leaf is HEALTHY + Peak Chlorophyll.")
        print("  → SUITABLE for silkworm feeding. Top-grade yield.")
    elif q == 'Medium':
        print("  Leaf is borderline — moderate freshness or ambiguous signal.")
        print("  → Inspect manually before use.")
    else:
        if result['is_diseased']:
            print(f"  Pathogen detected: {result['raw_class']}.")
        else:
            print("  Leaf is disease-free but nutritionally depleted / dehydrated.")
        print("  → NOT suitable. Leaf should be DISCARDED.")
    print("=" * 60)


print("Hybrid AI+CV inference pipeline ready.")
print(f"Using calibrated thresholds — Excellent: >= {globals().get('THRESHOLD_EXCELLENT', 'N/A (run Cell 22 first)')},"
      f" Medium: >= {globals().get('THRESHOLD_MEDIUM', 'N/A')}")
"""

# ── Apply all patches ─────────────────────────────────────────────
patches = {
    10: new_cell_10,
    13: new_cell_13,
    15: new_cell_15,
    17: new_cell_17,
    22: new_cell_22,
    24: new_cell_24,
}

for idx, code in patches.items():
    if idx < len(nb['cells']) and nb['cells'][idx]['cell_type'] == 'code':
        nb['cells'][idx]['source']  = lines(code)
        nb['cells'][idx]['outputs'] = []
        print(f"[OK] Patched Cell {idx}")
    else:
        print(f"[WARN] Cell {idx} not found!")

with open(target_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("All patches applied. Notebook saved successfully.")
