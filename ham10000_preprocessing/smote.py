# smote.py
import numpy as np
import pandas as pd
from tqdm import tqdm
from imblearn.over_sampling import SMOTE
from config import *


def load_images_for_smote(df: pd.DataFrame):
    imgs, labels = [], []
    for _, row in tqdm(df.iterrows(), desc="Loading images for SMOTE"):
        path = os.path.join(OUTPUT_DIR, f"{row['image_id']}.npy")
        if os.path.exists(path):
            img = np.load(path).astype(np.float32) / 255.0
            imgs.append(img.flatten())
            labels.append(row['label'])
    return np.array(imgs), np.array(labels)


def apply_smote_augmentation(df_base: pd.DataFrame) -> pd.DataFrame:
    print("\n🔄 Applying SMOTE...")

    smote_classes = list(SMOTE_STRATEGY.keys())
    df_minority = df_base[df_base['label'].isin(smote_classes)].copy()
    df_nv = df_base[df_base['dx'] == 'nv'].sample(500, random_state=SEED).copy()

    df_for_smote = pd.concat([df_minority, df_nv], ignore_index=True)

    X, y = load_images_for_smote(df_for_smote)

    strategy = {k: v for k, v in SMOTE_STRATEGY.items() if v > np.sum(y == k)}
    strategy[5] = int(np.sum(y == 5))  # keep nv count

    sm = SMOTE(sampling_strategy=strategy, k_neighbors=5, random_state=SEED)
    X_res, y_res = sm.fit_resample(X, y)

    # Extract synthetic samples only
    X_synth = X_res[len(X):]
    y_synth = y_res[len(X):]

    new_rows = []
    for i, (flat_img, label) in enumerate(zip(X_synth, y_synth)):
        img = (flat_img.reshape(IMG_SIZE, IMG_SIZE, 3) * 255).clip(0, 255).astype(np.uint8)
        img_id = f"smote_{CLASS_NAMES[label]}_{i:04d}"
        np.save(os.path.join(OUTPUT_DIR, f"{img_id}.npy"), img)

        new_rows.append({
            'image_id': img_id,
            'dx': CLASS_NAMES[label],
            'label': int(label),
            'source': 'smote'
        })

    df_smote = pd.DataFrame(new_rows)
    print(f"✅ SMOTE created {len(df_smote)} synthetic images.")
    return df_smote