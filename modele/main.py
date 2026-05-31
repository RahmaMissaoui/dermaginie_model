# main.py
import os
import warnings
import random
import numpy as np
import pandas as pd
import torch
from sklearn.model_selection import train_test_split

from config import SEED, DEVICE, CHECKPOINT_PATH, RESUME_TRAINING, START_EPOCH, CLASS_NAMES
from data.dataset import SkinLesionDataset, get_transforms
from data.dataloader import build_balanced_sampler, compute_class_weights, create_dataloaders
from models.hybrid_model import HybridModel
from losses.focal_dice_loss import UnifiedFocalLoss
from training.scheduler import get_optimizer, get_scheduler
from training.train import train
from evaluation.metrics import evaluate_model, plot_confusion_matrix, plot_training_curves
from evaluation.explainability import explain_sample
from utils import set_seed, get_device, count_parameters
from utils.visualization import plot_class_distribution, plot_sample_images

# Suppress warnings
warnings.filterwarnings('ignore')

# Set reproducibility
def set_seed(seed):
    os.environ['PYTHONHASHSEED'] = str(seed)
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

set_seed(SEED)

print(f'PyTorch : {torch.__version__}')
print(f'Device  : {DEVICE}')
if DEVICE.type == 'cuda':
    print(f'GPU     : {torch.cuda.get_device_name(0)}')


def load_preprocessed_dataframe():
    """Load preprocessed dataset."""
    from config import PREPROCESSED_PATH
    df = pd.read_csv(f'{PREPROCESSED_PATH}/metadata.csv')
    print(f'Total images : {len(df)}')
    print(df['dx'].value_counts())
    return df


def split_dataset(df, seed=SEED):
    """Split dataset into train/val/test."""
    train_df, temp_df = train_test_split(
        df, test_size=0.30, stratify=df['label'], random_state=seed
    )
    val_df, test_df = train_test_split(
        temp_df, test_size=0.50, stratify=temp_df['label'], random_state=seed
    )
    print(f'Train: {len(train_df)} | Val: {len(val_df)} | Test: {len(test_df)}')
    return train_df.reset_index(drop=True), val_df.reset_index(drop=True), test_df.reset_index(drop=True)


def main():
    # Load data
    print("\n" + "="*60)
    print("LOADING DATA")
    print("="*60)
    df = load_preprocessed_dataframe()
    train_df, val_df, test_df = split_dataset(df)
    
    # Create datasets
    print("\n" + "="*60)
    print("CREATING DATASETS")
    print("="*60)
    train_transform, eval_transform = get_transforms()
    
    train_dataset = SkinLesionDataset(train_df, transform=train_transform)
    val_dataset = SkinLesionDataset(val_df, transform=eval_transform)
    test_dataset = SkinLesionDataset(test_df, transform=eval_transform)
    print(f'Datasets: train={len(train_dataset)} val={len(val_dataset)} test={len(test_dataset)}')
    
    # Create samplers and loaders
    print("\n" + "="*60)
    print("CREATING DATALOADERS")
    print("="*60)
    train_sampler = build_balanced_sampler(train_df)
    class_weights = compute_class_weights(train_df)
    train_loader, val_loader, test_loader = create_dataloaders(
        train_dataset, val_dataset, test_dataset, train_sampler
    )
    
    steps_per_epoch = len(train_sampler) // 32
    print(f'Steps/epoch: {steps_per_epoch}')
    
    # Create model
    print("\n" + "="*60)
    print("CREATING MODEL")
    print("="*60)
    model = HybridModel().to(DEVICE)
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f'\nTotal params    : {total_params:,}')
    print(f'Trainable params: {trainable_params:,}')
    
    # Create loss, optimizer, scheduler
    print("\n" + "="*60)
    print("SETTING UP TRAINING COMPONENTS")
    print("="*60)
    criterion = UnifiedFocalLoss(alpha=class_weights).to(DEVICE)
    optimizer = get_optimizer(model)
    scheduler = get_scheduler(optimizer)
    
    # Resume training if specified
    start_epoch = START_EPOCH
    if RESUME_TRAINING:
        checkpoint = torch.load(CHECKPOINT_PATH, map_location=DEVICE)
        model.load_state_dict(checkpoint)
        print(f'Resumed from checkpoint: {CHECKPOINT_PATH}')
    
    # Train
    print("\n" + "="*60)
    print("STARTING TRAINING")
    print("="*60)
    history = train(
        model=model,
        train_loader=train_loader,
        val_loader=val_loader,
        criterion=criterion,
        optimizer=optimizer,
        scheduler=scheduler,
        epochs=60,
        device=DEVICE
    )
    
    # Evaluate
    print("\n" + "="*60)
    print("EVALUATING MODEL")
    print("="*60)
    y_true, y_pred = evaluate_model(
        model, val_loader, test_loader, test_df, criterion, optimizer
    )
    
    # Plot results
    print("\n" + "="*60)
    print("GENERATING PLOTS")
    print("="*60)
    plot_confusion_matrix(y_true, y_pred, CLASS_NAMES)
    plot_training_curves(history)
    
    # Explain a few test samples
    print("\n" + "="*60)
    print("GENERATING EXPLANATIONS")
    print("="*60)
    for idx in [0, 10, 42, 100]:
        if idx < len(test_dataset):
            explain_sample(model, test_df, test_dataset, sample_idx=idx)
    
    print("\n" + "="*60)
    print("TRAINING COMPLETE!")
    print("="*60)

    

if __name__ == "__main__":
    main()