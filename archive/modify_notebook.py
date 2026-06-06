import json
import shutil

notebook_path = r"C:\Users\Shashwat\OneDrive\Desktop\notebook4bd5bed4ee.ipynb"
backup_path = r"C:\Users\Shashwat\OneDrive\Desktop\notebook4bd5bed4ee_backup.ipynb"

# 1. Backup the original file
shutil.copy2(notebook_path, backup_path)

# 2. Load the notebook
with open(notebook_path, 'r', encoding='utf-8') as f:
    nb = json.load(f)

# Helper to find a code cell by index (filtering out markdown if needed, but the original indices 4, 8, 10 etc. include markdown)
# We will just iterate and match on ID or exact original source text, but since we parsed them linearly before:
# Cell 4 (Code) - Dataset Exploration
# Cell 8 (Code) - Quality Label Mapping
# Cell 10 (Code) - Data Config
# Cell 13 (Code) - Model Build
# Cell 15 (Code) - Warmup fit
# Cell 17 (Code) - Finetune fit
# Cell 24 (Code) - Inference logic

# Let's map out the replacements:

new_cell_4 = """import os
import pandas as pd

# 1. Broadly search /kaggle/input/ for any image files
SEARCH_DIR = '/kaggle/input/'
all_classes = []

print("Searching for folders containing images...")

def find_class_root(base):
    for root, dirs, files in os.walk(base):
        subdirs = [d for d in dirs]
        if len(subdirs) >= 2:
            has_images = False
            for sd in subdirs:
                sd_path = os.path.join(root, sd)
                if os.path.isdir(sd_path):
                    imgs = [f for f in os.listdir(sd_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
                    if len(imgs) > 0:
                        has_images = True
                        break
            if has_images:
                return root
    return base

DATASET_ROOT = find_class_root(SEARCH_DIR)
BASE_DIR = DATASET_ROOT

print(f"✅ Success! Data root automatically detected at: {DATASET_ROOT}")

CLASS_NAMES = sorted([
    d for d in os.listdir(DATASET_ROOT)
    if os.path.isdir(os.path.join(DATASET_ROOT, d))
])

for cls in CLASS_NAMES:
    cls_path = os.path.join(DATASET_ROOT, cls)
    img_files = [f for f in os.listdir(cls_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    all_classes.append({
        'Class': cls,
        'Path': cls_path,
        'Image Count': len(img_files)
    })

df_classes = pd.DataFrame(all_classes)
if not df_classes.empty:
    print("\\nDetected class folders:")
    print(df_classes[['Class', 'Image Count']].to_string(index=False))
    print(f"\\nTotal images: {df_classes['Image Count'].sum()}")
else:
    print("❌ STILL NO IMAGES FOUND. Double check Dataset path.")
"""

new_cell_5 = """# Root directory auto-detection is now handled robustly in the previous script!
# Printing class names to confirm:
print("Dataset root detected:", DATASET_ROOT)
print("Classes found:", CLASS_NAMES)
"""

new_cell_8 = """# ----------------------------------------------------------------
# Diseased vs Healthy class explicit mapping
# This explicitly maps the healthy class so that the grading logic has a reliable foundation.
# ----------------------------------------------------------------

HEALTHY_CLASSES = ['Disease Free leaves']  # Ensure this matches your healthy folder name exactly
DISEASED_CLASSES = [c for c in CLASS_NAMES if c not in HEALTHY_CLASSES]

print("Healthy classes:", HEALTHY_CLASSES)
print("Diseased classes:", DISEASED_CLASSES)

if len(HEALTHY_CLASSES) == 0 or HEALTHY_CLASSES[0] not in CLASS_NAMES:
    print("\\n[WARNING] Healthy class 'Disease Free leaves' not found in actual dataset folders!")
    print("Check spelling in class names.")
"""

new_cell_10 = """# ----- Configuration -----
IMG_SIZE = 224          # EfficientNetB0 default
BATCH_SIZE = 32
EPOCHS_WARMUP = 5       # Train only top layers first
EPOCHS_FINETUNE = 20    # Then unfreeze and fine-tune
SEED = 42

# ----- Augmentation for training (Stronger to prevent overfitting) -----
train_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
    validation_split=0.20,
    rotation_range=40,
    width_shift_range=0.20,
    height_shift_range=0.20,
    shear_range=0.15,
    zoom_range=0.25,
    horizontal_flip=True,
    vertical_flip=True,
    brightness_range=[0.7, 1.3],
    fill_mode='reflect'
)

val_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
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

CLASS_INDICES = train_generator.class_indices   # dict: class_name -> index
INDEX_TO_CLASS = {v: k for k, v in CLASS_INDICES.items()}

print("Class index mapping:", CLASS_INDICES)
print(f"Training samples : {train_generator.samples}")
print(f"Validation samples: {val_generator.samples}")

# Compute class weights to handle serious data imbalance
from sklearn.utils.class_weight import compute_class_weight
import numpy as np

train_classes = train_generator.classes
class_weights = compute_class_weight(
    class_weight='balanced',
    classes=np.unique(train_classes),
    y=train_classes
)
class_weight_dict = dict(enumerate(class_weights))
print("\\nComputed Class Weights (Balances smaller classes):", class_weight_dict)
"""

new_cell_13 = """NUM_CLASSES = len(CLASS_NAMES)

def build_model(num_classes, freeze_base=True):
    \"\"\"
    EfficientNetB0 + custom classification head.
    freeze_base=True  → warm-up phase (only head trains)
    freeze_base=False → fine-tuning phase (full network trains)
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
    # Increased Dropout to combat overfitting!
    x = layers.Dropout(0.60)(x)
    x = layers.Dense(256, activation='relu',
                     kernel_regularizer=keras.regularizers.l2(1e-4))(x)
    # Increased Dropout here too!
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

new_cell_15 = """callbacks_warmup = [
    EarlyStopping(monitor='val_accuracy', patience=3, restore_best_weights=True, verbose=1),
    ModelCheckpoint('/kaggle/working/best_warmup.keras',
                    monitor='val_accuracy', save_best_only=True, verbose=1)
]

history_warmup = model.fit(
    train_generator,
    epochs=EPOCHS_WARMUP,
    validation_data=val_generator,
    callbacks=callbacks_warmup,
    class_weight=class_weight_dict,  # <-- Applying class weights here!
    verbose=1
)

print("\\nWarm-up complete.")
print(f"Best val accuracy: {max(history_warmup.history['val_accuracy']):.4f}")
"""

new_cell_17 = """# Unfreeze the last 30 layers of the base model
base_model.trainable = True
layers_to_freeze = len(base_model.layers) - 30
for layer in base_model.layers[:layers_to_freeze]:
    layer.trainable = False

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-4),  # lower LR for fine-tune
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

callbacks_finetune = [
    # Reduced patience to 3 to prevent over-memorizing the train set
    EarlyStopping(monitor='val_accuracy', patience=3, restore_best_weights=True, verbose=1),
    ModelCheckpoint('/kaggle/working/best_model.keras',
                    monitor='val_accuracy', save_best_only=True, verbose=1),
    ReduceLROnPlateau(monitor='val_loss', factor=0.3, patience=2,
                      min_lr=1e-7, verbose=1)
]

# Reset generators before fine-tuning
train_generator.reset()
val_generator.reset()

history_finetune = model.fit(
    train_generator,
    epochs=EPOCHS_FINETUNE,
    validation_data=val_generator,
    callbacks=callbacks_finetune,
    class_weight=class_weight_dict,   # <-- Applying class weights here!
    verbose=1
)

print("\\nFine-tuning complete.")
print(f"Best val accuracy: {max(history_finetune.history['val_accuracy']):.4f}")
"""

new_cell_24 = """def predict_leaf_quality(image_path, model, class_indices, healthy_classes,
                         img_size=224):
    \"\"\"
    Takes a path to any leaf image.
    Returns a quality verdict: Excellent / Medium / Poor based on robust confidence intervals.

    Parameters
    ----------
    image_path         : str   — path to the input image
    model              : keras Model
    class_indices      : dict  — {class_name: index} from training generator
    healthy_classes    : list  — names of healthy folder(s)
    img_size           : int   — model input size (default 224)

    Returns
    -------
    result : dict with keys:
        'quality'        : 'Excellent' | 'Medium' | 'Poor'
        'is_diseased'    : bool
        'raw_class'      : predicted class name
        'confidence'     : confidence for the predicted class
        'all_probs'      : dict of {class_name: probability}
    \"\"\"
    import cv2
    import numpy as np
    import matplotlib.pyplot as plt
    # 1. Load and preprocess
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(f"Could not load image: {image_path}")
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (img_size, img_size))
    img_norm = img_resized.astype('float32') / 255.0
    img_batch = np.expand_dims(img_norm, axis=0)    # shape: (1, H, W, 3)

    # 2. Predict
    proba = model.predict(img_batch, verbose=0)[0]  # shape: (num_classes,)
    pred_idx = int(np.argmax(proba))
    idx_to_cls = {v: k for k, v in class_indices.items()}
    pred_class_name = idx_to_cls[pred_idx]
    pred_confidence = float(proba[pred_idx])

    # 3. Determine healthy indices
    h_indices = set()
    for hc in healthy_classes:
        if hc in class_indices:
            h_indices.add(class_indices[hc])

    # 4. Map to quality using scientifically robust buffer zones
    is_diseased = (pred_idx not in h_indices)
    
    if not is_diseased and pred_confidence >= 0.90:
        # High confidence Healthy prediction
        quality = 'Excellent'
    elif (not is_diseased and 0.70 <= pred_confidence < 0.90) or (is_diseased and pred_confidence < 0.50):
        # Med confidence Healthy OR Low confidence Diseased -> Manual review/Medium grade
        quality = 'Medium'
    else:
        # Diseased prediction with > 50% confidence
        quality = 'Poor'

    # 5. All probabilities
    all_probs = {idx_to_cls[i]: round(float(proba[i]), 4) for i in range(len(proba))}

    return {
        'quality': quality,
        'is_diseased': is_diseased,
        'raw_class': pred_class_name,
        'confidence': pred_confidence,
        'all_probs': all_probs
    }


def display_prediction(image_path, result):
    \"\"\"Visualise the image alongside the prediction verdict.\"\"\"
    import cv2
    import matplotlib.pyplot as plt
    img = cv2.imread(image_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    quality_colors = {'Excellent': '#2ecc71', 'Medium': '#f39c12', 'Poor': '#e74c3c'}
    quality_icons  = {'Excellent': '✅', 'Medium': '⚠️', 'Poor': '❌'}
    q = result['quality']

    fig, (ax_img, ax_bar) = plt.subplots(1, 2, figsize=(12, 5))

    # Left: image
    ax_img.imshow(img_rgb)
    ax_img.set_title(
        f"{quality_icons[q]} Quality: {q}   |   Raw class: {result['raw_class']}\\n"
        f"Confidence: {result['confidence']:.2%}   |   Diseased: {result['is_diseased']}",
        fontsize=12, fontweight='bold',
        color=quality_colors[q]
    )
    ax_img.axis('off')

    # Right: probability bars
    classes = list(result['all_probs'].keys())
    probs = list(result['all_probs'].values())
    bar_colors = ['#e74c3c' if c not in HEALTHY_CLASSES else '#2ecc71' for c in classes]
    bars = ax_bar.barh(classes, probs, color=bar_colors, edgecolor='white')
    for bar_item, prob in zip(bars, probs):
        ax_bar.text(bar_item.get_width() + 0.01, bar_item.get_y() + bar_item.get_height() / 2,
                    f'{prob:.2%}', va='center', fontsize=10)
    ax_bar.set_xlim(0, 1.15)
    ax_bar.set_xlabel('Probability')
    ax_bar.set_title('Class Probabilities', fontsize=12, fontweight='bold')
    ax_bar.grid(axis='x', alpha=0.3)

    plt.tight_layout()
    plt.show()

    print("\\n" + "=" * 50)
    print(f"  QUALITY VERDICT : {quality_icons[q]} {q}")
    print("=" * 50)
    if q == 'Excellent':
        print("  The leaf is HEALTHY with HIGH confidence (≥ 90%).")
        print("  → Suitable for silkworm feeding. Top-grade quality.")
    elif q == 'Medium':
        print("  The leaf is Borderline (Moderate confidence or Ambiguous symptoms).")
        print("  → Usable, but inspect manually before use.")
    else:
        print(f"  Disease detected: {result['raw_class']} (Confidence ≥ 50%)")
        print("  → NOT suitable. Leaf should be discarded.")
    print("=" * 50)


print("Inference functions defined successfully with new robust grading logic.")
"""


new_cell_imports = """
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau
"""

def string_chunk_list(code_str):
    # Splits by newline but keeps the newline character
    lines = code_str.splitlines(keepends=True)
    return lines

cell_index_map = {
    4: new_cell_4,
    5: new_cell_5,
    8: new_cell_8,
    10: new_cell_10,
    13: new_cell_13,
    15: new_cell_15,
    17: new_cell_17,
    24: new_cell_24
}

for idx, replacement in cell_index_map.items():
    if idx < len(nb['cells']):
        # convert string to list of lines to conform to ipynb standard
        nb['cells'][idx]['source'] = string_chunk_list(replacement)
        # Clear out previous outputs to avoid confusion when opening in Kaggle
        if 'outputs' in nb['cells'][idx]:
            nb['cells'][idx]['outputs'] = []

# Update confidence threshold parameter removing from cells 26 and 28 just in case since we hardcoded logic inside the function directly
# Although predict_leaf_quality no longer explicitly needs confidence_threshold passed in as an argument.
if 26 < len(nb['cells']):
    c26_text = "".join(nb['cells'][26]['source'])
    c26_text = c26_text.replace("confidence_threshold=CONFIDENCE_THRESHOLD", "")
    nb['cells'][26]['source'] = string_chunk_list(c26_text)
if 28 < len(nb['cells']):
    c28_text = "".join(nb['cells'][28]['source'])
    c28_text = c28_text.replace("confidence_threshold=CONFIDENCE_THRESHOLD", "")
    nb['cells'][28]['source'] = string_chunk_list(c28_text)

with open(notebook_path, 'w', encoding='utf-8') as f:
    json.dump(nb, f, indent=1)

print("Modification complete.")
