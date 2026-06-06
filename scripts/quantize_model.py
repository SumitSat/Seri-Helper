import tensorflow as tf
import os
import numpy as np
import cv2

# Import preprocess_input exactly as used in the training notebook
from tensorflow.keras.applications.efficientnet import preprocess_input

# Configuration Paths - Update these if your files are located elsewhere
MODEL_PATH = './working/mulberry_quality_classifier.keras' 
DATASET_PATH = './datasets/Mulberry Data'          
TFLITE_MODEL_PATH = './working/mulberry_quality_classifier.tflite'
IMG_SIZE = 224

def representative_dataset_gen():
    """Generates a representative dataset for full integer quantization."""
    count = 0
    print("Calibrating model with sample images...")
    for root, _, files in os.walk(DATASET_PATH):
        for file in files:
            if file.lower().endswith(('.png', '.jpg', '.jpeg')):
                img_path = os.path.join(root, file)
                img = cv2.imread(img_path)
                if img is None: continue
                img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
                img_resized = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))
                # Apply the exact same preprocessing used during training
                img_preproc = preprocess_input(img_resized.astype('float32'))
                img_batch = np.expand_dims(img_preproc, axis=0)
                
                yield [img_batch]
                
                count += 1
                if count >= 100:  # 100 images are sufficient for accurate calibration
                    return

def add_metadata(tflite_path):
    """Embeds label metadata into the TFLite model using tflite_support."""
    try:
        from tflite_support.metadata_writers import image_classifier
        from tflite_support.metadata_writers import writer_utils

        # Create a labels.txt file temporarily
        labels_path = "temp_labels.txt"
        with open(labels_path, "w") as f:
            f.write("Disease Free leaves\nLeaf Rust\nLeaf spot\nPowdery Mildew")

        print("Embedding metadata and labels into the TFLite model...")
        ImageClassifierWriter = image_classifier.MetadataWriter
        _MODEL_PATH = tflite_path
        
        # Standard normalization for EfficientNetB0 (already handled in preprocess_input, 
        # but metadata expects some values. We set mean=0, std=1 for metadata to keep it neutral)
        writer = ImageClassifierWriter.create_for_inference(
            writer_utils.load_file(_MODEL_PATH), 
            [127.5], [127.5], [labels_path])
            
        writer_utils.save_file(writer.populate(), _MODEL_PATH)
        os.remove(labels_path)
        print("Metadata successfully embedded!")
        
    except ImportError:
        print("\n[WARNING] 'tflite-support' library not found. Skipping metadata embedding.")
        print("You can still use the model by manually mapping the outputs in Dart code.")
        print("To embed metadata, run: pip install tflite-support\n")

def main():
    print(f"Loading Keras model from {MODEL_PATH}...")
    if not os.path.exists(MODEL_PATH):
        print(f"\n[ERROR] Model not found at {MODEL_PATH}")
        print("Please ensure you have run the training notebook and placed the '.keras' model there.")
        return

    model = tf.keras.models.load_model(MODEL_PATH)

    print("Initializing TFLiteConverter...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Optimization flag for Full Integer Quantization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    if os.path.exists(DATASET_PATH):
        print(f"Using dataset at {DATASET_PATH} for INT8 calibration...")
        converter.representative_dataset = representative_dataset_gen
        # Restrict ops to INT8 builtins
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        # Set input/output types to uint8 for maximum compatibility on mobile
        converter.inference_input_type = tf.uint8
        converter.inference_output_type = tf.uint8
    else:
        print(f"\n[WARNING] Dataset not found at {DATASET_PATH}.")
        print("Falling back to Dynamic Range Quantization (Float32 in/out, INT8 weights).")
        print("This will still compress the model, but INT8 inference is faster.")

    print("Converting model (this may take a minute)...")
    tflite_model = converter.convert()

    # Ensure output directory exists
    os.makedirs(os.path.dirname(TFLITE_MODEL_PATH), exist_ok=True)
    
    print(f"Saving TFLite model to {TFLITE_MODEL_PATH}...")
    with open(TFLITE_MODEL_PATH, 'wb') as f:
        f.write(tflite_model)
        
    print(f"\n✅ Conversion successful! Compressed model size: {len(tflite_model) / (1024*1024):.2f} MB")
    
    # Try adding metadata
    add_metadata(TFLITE_MODEL_PATH)

if __name__ == '__main__':
    main()
