# utils.py
import cv2
import numpy as np
from config import IMAGENET_MEAN, IMG_SIZE


def dull_razor(image_bgr: np.ndarray, kernel_size: int = 17) -> np.ndarray:
    """Remove hair using DullRazor technique."""
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (kernel_size, kernel_size))
    blackhat = cv2.morphologyEx(gray, cv2.MORPH_BLACKHAT, kernel)
    _, mask = cv2.threshold(blackhat, 10, 255, cv2.THRESH_BINARY)
    return cv2.inpaint(image_bgr, mask, inpaintRadius=5, flags=cv2.INPAINT_TELEA)


def resize_with_padding(image_rgb: np.ndarray, target: int = IMG_SIZE) -> np.ndarray:
    """Resize image while keeping aspect ratio and pad with ImageNet mean color."""
    mean_255 = tuple(int(m * 255) for m in IMAGENET_MEAN)
    h, w = image_rgb.shape[:2]
    scale = target / max(h, w)
    nh, nw = int(h * scale), int(w * scale)

    resized = cv2.resize(image_rgb, (nw, nh), interpolation=cv2.INTER_CUBIC)
    canvas = np.full((target, target, 3), mean_255, dtype=np.uint8)

    pt = (target - nh) // 2
    pl = (target - nw) // 2
    canvas[pt:pt + nh, pl:pl + nw] = resized
    return canvas


def apply_clahe(image_rgb: np.ndarray, clip_limit: float = 2.0, tile_grid: tuple = (8, 8)) -> np.ndarray:
    """Apply CLAHE contrast enhancement."""
    lab = cv2.cvtColor(image_rgb, cv2.COLOR_RGB2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid)
    l_eq = clahe.apply(l)
    return cv2.cvtColor(cv2.merge((l_eq, a, b)), cv2.COLOR_LAB2RGB)


def find_image_path(img_id: str, dir1, dir2) -> str:
    """Find image in either part_1 or part_2 folder."""
    for directory in [dir1, dir2]:
        path = os.path.join(directory, img_id + '.jpg')
        if os.path.exists(path):
            return path
    return os.path.join(dir1, img_id + '.jpg')  # fallback