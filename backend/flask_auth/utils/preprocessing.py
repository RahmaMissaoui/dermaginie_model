# Preprocessing functions for skin lesion images.
# Stages: 1. DullRazor hair removal, 2. Aspect-ratio resize + padding, 3. CLAHE contrast enhancement

import cv2
import numpy as np

IMG_SIZE = 224
IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)
_MEAN_255 = tuple(int(m * 255) for m in IMAGENET_MEAN)

def dull_razor(image_bgr, kernel_size=17):
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (kernel_size, kernel_size))
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel)
    _, mask = cv2.threshold(blackhat, 10, 255, cv2.THRESH_BINARY)
    return cv2.inpaint(image_bgr, mask, inpaintRadius=5, flags=cv2.INPAINT_TELEA)

def resize_with_padding(image_rgb, target=IMG_SIZE):
    h, w = image_rgb.shape[:2]
    scale = target / max(h, w)
    nh, nw = int(h * scale), int(w * scale)
    resized = cv2.resize(image_rgb, (nw, nh), interpolation=cv2.INTER_CUBIC)
    canvas = np.full((target, target, 3), _MEAN_255, dtype=np.uint8)
    pt = (target - nh) // 2
    pl = (target - nw) // 2
    canvas[pt:pt + nh, pl:pl + nw] = resized
    return canvas

def apply_clahe(image_rgb, clip_limit=2.0, tile_grid=(8, 8)):
    lab = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2LAB)
    l, a, b = cv2.split(lab)
    clahe_obj = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid)
    l_eq = clahe_obj.apply(l)
    return cv2.cvtColor(cv2.merge((l_eq, a, b)), cv2.COLOR_LAB2RGB)

def preprocess_numpy(img_path):
    img_bgr = cv2.imread(img_path)
    if img_bgr is None:
        raise ValueError(f"Could not read image at {img_path}")
    img_bgr = dull_razor(img_bgr)
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_rgb = resize_with_padding(img_rgb, IMG_SIZE)
    img_rgb = apply_clahe(img_rgb)
    return img_rgb

def preprocess_from_bytes(image_bytes, target=IMG_SIZE):
    nparr = np.frombuffer(image_bytes, np.uint8)
    img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    if img_bgr is None:
        raise ValueError("Could not decode image from bytes")
    img_bgr = dull_razor(img_bgr)
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_rgb = resize_with_padding(img_rgb, target)
    img_rgb = apply_clahe(img_rgb)
    return img_rgb

print("✅ Preprocessing module loaded")