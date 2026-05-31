import os

SEED = 42

# Paths
BASE_PATH = '/home/dilmi/Downloads/archive'
METADATA_PATH = os.path.join(BASE_PATH, 'HAM10000_metadata.csv')

IMG_DIR1 = os.path.join(BASE_PATH, 'HAM10000_images_part_1')
IMG_DIR2 = os.path.join(BASE_PATH, 'HAM10000_images_part_2')

# Fallback
if not os.path.isdir(IMG_DIR1):
    IMG_DIR1 = os.path.join(BASE_PATH, 'ham10000_images_part_1')
if not os.path.isdir(IMG_DIR2):
    IMG_DIR2 = os.path.join(BASE_PATH, 'ham10000_images_part_2')

OUTPUT_DIR = os.path.join(os.path.expanduser('~'), 'Downloads', 'preprocessed_ham10000_v2')

# Image settings
IMG_SIZE = 224
IMAGENET_MEAN = (0.485, 0.456, 0.406)

# Classes
LABEL_MAP = {'akiec': 0, 'bcc': 1, 'bkl': 2, 'df': 3, 'mel': 4, 'nv': 5, 'vasc': 6}
CLASS_NAMES = list(LABEL_MAP.keys())
NUM_CLASSES = len(CLASS_NAMES)

# SMOTE & GAN
SMOTE_STRATEGY = {3: 400, 0: 450, 6: 380}
GAN_TARGET_CLASSES = ['df', 'akiec', 'vasc']
GAN_TARGET_COUNT = 500
GAN_EPOCHS = 80
GAN_BATCH = 16
GAN_LR = 2e-4
GAN_LATENT = 100
GAN_IMG_SIZE = 64

os.makedirs(OUTPUT_DIR, exist_ok=True)