# config.py
import os

# Paths
PREPROCESSED_PATH = '/kaggle/input/datasets/missaouirahma/preprocessed-ham10000-v2/preprocessed_ham10000_v2'

# Image
IMG_SIZE = 224
IMAGENET_MEAN = (0.485, 0.456, 0.406)
IMAGENET_STD = (0.229, 0.224, 0.225)

# Classes
LABEL_MAP = {'akiec': 0, 'bcc': 1, 'bkl': 2, 'df': 3, 'mel': 4, 'nv': 5, 'vasc': 6}
CLASS_NAMES = list(LABEL_MAP.keys())
NUM_CLASSES = len(CLASS_NAMES)

# Training
BATCH_SIZE = 32
EPOCHS = 60
LEARNING_RATE = 1e-4
WEIGHT_DECAY = 1e-5
CNN_FREEZE_UNTIL = 200
VIT_FREEZE_BLOCKS = 6
STEPS_MULTIPLIER = 2

# Loss
FOCAL_ALPHA = 0.4
FOCAL_GAMMA = 2.5
LAMBDA_DICE = 0.5

# Callbacks
LR_PATIENCE = 3
EARLY_STOP_PATIENCE = 15
CHECKPOINT_PATH = 'hybrid_best.pt'
FINAL_MODEL_PATH = 'hybrid_final.pt'

# Resume Settings
RESUME_TRAINING = False
RESUME_PATH = 'hybrid_best.pt'
START_EPOCH = 1

# Random Seed
SEED = 42