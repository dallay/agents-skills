---
name: tensorflow-ml
description: >-
  TensorFlow and Keras machine learning patterns for model building, training, data
  pipelines, evaluation, transfer learning, deployment, and GPU-accelerated deep learning.
  Use when the task involves `TensorFlow`, `Keras`, `machine learning model`, `deep
  learning`, or `neural network training`.
license: MIT
metadata:
  version: "1.0.0"
---

## When to Use

- Building neural network models with Keras Sequential or Functional API.
- Setting up efficient data pipelines with `tf.data`.
- Training, evaluating, and tuning deep learning models.
- Applying transfer learning from pre-trained models (ResNet, MobileNet, BERT).
- Saving, loading, and serving models (SavedModel, H5, TFLite).
- Debugging training issues: overfitting, vanishing gradients, slow convergence.
- Configuring GPU/TPU acceleration and mixed precision training.
- Visualizing training with TensorBoard.

## Critical Patterns

- **Keras Is THE API:** Use `tf.keras` for all model building. Raw `tf.Module` and `tf.GradientTape`
  are only for advanced custom training loops. Start with the high-level API.
- **Functional API Over Sequential:** Use Functional API for anything beyond a simple linear stack.
  It supports multi-input, multi-output, shared layers, and residual connections.
- **tf.data for Everything:** Never use Python generators or `numpy` loading for training data in
  production. `tf.data.Dataset` handles prefetching, parallel mapping, and memory-efficient
  streaming.
- **Callbacks Are Your Safety Net:** Always use `EarlyStopping` (patience-based),
  `ModelCheckpoint` (save best weights), and `ReduceLROnPlateau`. Never train blind without them.
- **Validate on Held-Out Data:** Always split data into train/validation/test. Use validation loss (
  not training loss) for all tuning decisions. Test set is touched exactly once.
- **Mixed Precision for Speed:** Enable
  `tf.keras.mixed_precision.set_global_policy("mixed_float16")` on modern GPUs (Volta+) for ~2x
  speedup with minimal accuracy impact.
- **SavedModel for Deployment:** Always export as SavedModel format (not H5) for production serving.
  SavedModel preserves the computation graph and is framework-agnostic.

## Code Examples

### Model Building: Functional API

```python
import tensorflow as tf
from tensorflow import keras
from keras import layers

def build_classifier(input_shape: tuple[int, ...], num_classes: int) -> keras.Model:
    """Build a CNN classifier with residual connections."""
    inputs = keras.Input(shape=input_shape, name="image_input")

    # Convolutional block 1
    x = layers.Conv2D(32, 3, padding="same", activation="relu")(inputs)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(32, 3, padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D()(x)
    x = layers.Dropout(0.25)(x)

    # Convolutional block 2 with residual
    shortcut = layers.Conv2D(64, 1, strides=2, padding="same")(x)
    x = layers.Conv2D(64, 3, padding="same", activation="relu")(x)
    x = layers.BatchNormalization()(x)
    x = layers.Conv2D(64, 3, padding="same")(x)
    x = layers.BatchNormalization()(x)
    x = layers.MaxPooling2D()(x)
    x = layers.Add()([x, shortcut])  # Residual connection
    x = layers.Activation("relu")(x)
    x = layers.Dropout(0.25)(x)

    # Classification head
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.5)(x)
    outputs = layers.Dense(num_classes, activation="softmax", name="predictions")(x)

    return keras.Model(inputs=inputs, outputs=outputs, name="cnn_classifier")

model = build_classifier(input_shape=(224, 224, 3), num_classes=10)
model.summary()
```

### Training with Callbacks

```python
# Compile with optimizer, loss, and metrics
model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

# Essential callbacks
callbacks = [
    keras.callbacks.EarlyStopping(
        monitor="val_loss",
        patience=10,
        restore_best_weights=True,  # Roll back to best epoch
    ),
    keras.callbacks.ModelCheckpoint(
        filepath="checkpoints/best_model.keras",
        monitor="val_loss",
        save_best_only=True,
    ),
    keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=5,
        min_lr=1e-6,
    ),
    keras.callbacks.TensorBoard(
        log_dir="logs/fit",
        histogram_freq=1,
    ),
]

history = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=100,  # EarlyStopping will handle actual stopping
    callbacks=callbacks,
)
```

### Efficient Data Pipeline with tf.data

```python
def build_dataset(
    file_pattern: str,
    batch_size: int = 32,
    is_training: bool = True,
    image_size: tuple[int, int] = (224, 224),
) -> tf.data.Dataset:
    """Build an optimized tf.data pipeline."""

    def parse_example(serialized: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
        features = tf.io.parse_single_example(serialized, {
            "image": tf.io.FixedLenFeature([], tf.string),
            "label": tf.io.FixedLenFeature([], tf.int64),
        })
        image = tf.io.decode_jpeg(features["image"], channels=3)
        image = tf.image.resize(image, image_size)
        image = tf.cast(image, tf.float32) / 255.0
        return image, features["label"]

    def augment(image: tf.Tensor, label: tf.Tensor) -> tuple[tf.Tensor, tf.Tensor]:
        image = tf.image.random_flip_left_right(image)
        image = tf.image.random_brightness(image, max_delta=0.2)
        image = tf.image.random_contrast(image, lower=0.8, upper=1.2)
        return image, label

    AUTOTUNE = tf.data.AUTOTUNE

    dataset = tf.data.TFRecordDataset(
        tf.io.gfile.glob(file_pattern),
        num_parallel_reads=AUTOTUNE,
    )

    if is_training:
        dataset = dataset.shuffle(buffer_size=10000)

    dataset = dataset.map(parse_example, num_parallel_calls=AUTOTUNE)

    if is_training:
        dataset = dataset.map(augment, num_parallel_calls=AUTOTUNE)

    dataset = dataset.batch(batch_size)
    dataset = dataset.prefetch(AUTOTUNE)  # Overlap data loading with training

    return dataset

train_dataset = build_dataset("data/train-*.tfrecord", is_training=True)
val_dataset = build_dataset("data/val-*.tfrecord", is_training=False)
```

### Transfer Learning

```python
def build_transfer_model(num_classes: int, fine_tune_from: int = 100) -> keras.Model:
    """Transfer learning with MobileNetV2: freeze base, fine-tune top layers."""
    base_model = keras.applications.MobileNetV2(
        input_shape=(224, 224, 3),
        include_top=False,
        weights="imagenet",
    )

    # Freeze all layers initially
    base_model.trainable = False

    inputs = keras.Input(shape=(224, 224, 3))
    # Preprocessing built into the pipeline
    x = keras.applications.mobilenet_v2.preprocess_input(inputs)
    x = base_model(x, training=False)  # training=False keeps BN in inference mode
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.3)(x)
    outputs = layers.Dense(num_classes, activation="softmax")(x)

    model = keras.Model(inputs, outputs)

    # Phase 1: Train only the new head
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    # model.fit(train_ds, epochs=10, validation_data=val_ds)

    # Phase 2: Fine-tune top layers of base model
    base_model.trainable = True
    for layer in base_model.layers[:fine_tune_from]:
        layer.trainable = False  # Keep early layers frozen

    model.compile(
        optimizer=keras.optimizers.Adam(1e-5),  # Much lower LR for fine-tuning
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    # model.fit(train_ds, epochs=20, validation_data=val_ds)

    return model
```

### Saving and Loading Models

```python
# Save as SavedModel (recommended for production)
model.save("saved_models/my_model")

# Load
loaded_model = keras.models.load_model("saved_models/my_model")

# Save as Keras format (.keras)
model.save("my_model.keras")

# Export to TensorFlow Lite (mobile/edge)
converter = tf.lite.TFLiteConverter.from_saved_model("saved_models/my_model")
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Dynamic range quantization
tflite_model = converter.convert()

with open("model.tflite", "wb") as f:
    f.write(tflite_model)
```

### GPU Setup and Mixed Precision

```python
# Verify GPU availability
print("GPUs available:", tf.config.list_physical_devices("GPU"))

# Prevent TensorFlow from allocating all GPU memory at once
gpus = tf.config.list_physical_devices("GPU")
for gpu in gpus:
    tf.config.experimental.set_memory_growth(gpu, True)

# Enable mixed precision for ~2x speedup on modern GPUs
tf.keras.mixed_precision.set_global_policy("mixed_float16")

# When using mixed precision, ensure the final output layer uses float32
# outputs = layers.Dense(num_classes, activation="softmax", dtype="float32")(x)
```

## Commands

```bash
# Verify TensorFlow installation and GPU
python -c "import tensorflow as tf; print(tf.__version__); print(tf.config.list_physical_devices('GPU'))"

# Launch TensorBoard
tensorboard --logdir=logs/fit --port=6006

# Convert SavedModel to TFLite
python -m tensorflow.lite.python.lite --saved_model_dir=saved_models/my_model --output_file=model.tflite

# Profile model performance
python -c "
import tensorflow as tf
model = tf.keras.models.load_model('saved_models/my_model')
tf.profiler.experimental.start('logs/profiler')
# Run inference
tf.profiler.experimental.stop()
"
```

## Best Practices

### DO

- Use `tf.data.AUTOTUNE` for `num_parallel_calls` and `prefetch` — let TensorFlow optimize
  throughput automatically.
- Always set `restore_best_weights=True` in `EarlyStopping` — otherwise you keep the last epoch's
  weights, not the best.
- Use `training=False` when calling a base model during transfer learning — this keeps
  BatchNormalization in inference mode.
- Use the `.keras` format (or SavedModel) for saving — avoid legacy H5 for new projects.
- Set `tf.config.experimental.set_memory_growth(gpu, True)` to prevent TF from grabbing all GPU
  memory upfront.
- Use `tf.keras.mixed_precision` on Volta+ GPUs for significant training speedup.
- Monitor `val_loss` (not `val_accuracy`) for `EarlyStopping` and `ModelCheckpoint` — loss is a
  smoother signal.

### DON'T

- Don't use Python lists or NumPy arrays as training input for large datasets — use
  `tf.data.Dataset` with prefetching and parallel mapping.
- Don't train without a validation split — you'll have no way to detect overfitting until it's too
  late.
- Don't fine-tune a pre-trained model at a high learning rate — use 10-100x lower LR (e.g., 1e-5)
  than the initial head training rate.
- Don't forget `model.compile()` after changing `layer.trainable` — the trainability changes only
  take effect after recompilation.
- Don't use `accuracy` as the only metric for imbalanced datasets — add `tf.keras.metrics.AUC`,
  `Precision`, and `Recall`.
- Don't save models with `model.save_weights()` alone — it loses the architecture. Use
  `model.save()` for full portability.
- Don't skip data augmentation for image tasks — it's the cheapest form of regularization.
- Don't ignore the output dtype with mixed precision — always set the final classification layer to
  `dtype="float32"` to avoid numerical instability.
