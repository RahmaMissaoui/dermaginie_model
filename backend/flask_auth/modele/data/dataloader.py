# data/dataloader.py
import numpy as np
import torch
from torch.utils.data import DataLoader, WeightedRandomSampler
from sklearn.utils.class_weight import compute_class_weight
from config import NUM_CLASSES, BATCH_SIZE, STEPS_MULTIPLIER


def build_balanced_sampler(df_subset):
    """Create weighted sampler for class balance."""
    labels = df_subset['label'].values
    counts = np.bincount(labels, minlength=NUM_CLASSES)
    weights = 1.0 / counts
    sample_weights = torch.tensor([weights[l] for l in labels], dtype=torch.float)
    num_samples = len(labels) * STEPS_MULTIPLIER
    return WeightedRandomSampler(sample_weights, num_samples=num_samples, replacement=True)


def compute_class_weights(train_df):
    """Compute class weights for loss function."""
    arr = compute_class_weight(
        class_weight='balanced',
        classes=np.arange(NUM_CLASSES),
        y=train_df['label'].values
    )
    weights = torch.tensor(arr, dtype=torch.float)
    print('Class weights:')
    for i, name in enumerate(CLASS_NAMES):
        print(f'  {name:6s}: {weights[i]:.3f}')
    return weights


def create_dataloaders(train_dataset, val_dataset, test_dataset, train_sampler):
    """Create all dataloaders."""
    train_loader = DataLoader(
        train_dataset, batch_size=BATCH_SIZE,
        sampler=train_sampler, num_workers=4, pin_memory=True
    )
    val_loader = DataLoader(
        val_dataset, batch_size=BATCH_SIZE,
        shuffle=False, num_workers=4, pin_memory=True
    )
    test_loader = DataLoader(
        test_dataset, batch_size=BATCH_SIZE,
        shuffle=False, num_workers=4, pin_memory=True
    )
    return train_loader, val_loader, test_loader