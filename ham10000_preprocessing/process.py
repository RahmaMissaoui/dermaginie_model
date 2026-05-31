# preprocess.py
import os
import pandas as pd
from tqdm import tqdm
from config import *
from utils import dull_razor, resize_with_padding, apply_clahe, find_image_path


def preprocess_image(img_path: str) -> np.ndarray:
    """Complete preprocessing: DullRazor → Resize → CLAHE"""
    img_bgr = cv2.imread(img_path)
    if img_bgr is None:
        raise FileNotFoundError(f"Could not read: {img_path}")

    img_bgr = dull_razor(img_bgr)
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_rgb = resize_with_padding(img_rgb)
    img_rgb = apply_clahe(img_rgb)
    return img_rgb


def preprocess_all_images():
    """Preprocess all images and save as .npy"""
    df = pd.read_csv(METADATA_PATH)
    df['label'] = df['dx'].map(LABEL_MAP)
    df['image_path'] = df['image_id'].apply(lambda x: find_image_path(x, IMG_DIR1, IMG_DIR2))

    errors = []
    for _, row in tqdm(df.iterrows(), total=len(df), desc="Preprocessing Images"):
        out_path = os.path.join(OUTPUT_DIR, f"{row['image_id']}.npy")
        if os.path.exists(out_path):
            continue

        try:
            img = preprocess_image(row['image_path'])
            np.save(out_path, img)
        except Exception as e:
            errors.append(row['image_id'])
            print(f"❌ Error processing {row['image_id']}: {e}")

    df = df[~df['image_id'].isin(errors)].reset_index(drop=True)
    df.to_csv(os.path.join(OUTPUT_DIR, 'metadata_base.csv'), index=False)

    print(f"✅ Preprocessing done! {len(df)} images saved.")
    return df