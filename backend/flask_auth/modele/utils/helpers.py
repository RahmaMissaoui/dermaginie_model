# utils/helpers.py
import os
import random
import json
import torch
import numpy as np
import pandas as pd
from datetime import datetime
from config import SEED, DEVICE, CLASS_NAMES, CHECKPOINT_PATH


def set_seed(seed=SEED):
    """Set random seeds for reproducibility."""
    os.environ['PYTHONHASHSEED'] = str(seed)
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False
    print(f"Random seed set to {seed}")


def get_device():
    """Get available device (CUDA/CPU)."""
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    print(f"Using device: {device}")
    if device.type == 'cuda':
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    return device


def count_parameters(model):
    """Count total and trainable parameters in model."""
    total = sum(p.numel() for p in model.parameters())
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"Total parameters: {total:,}")
    print(f"Trainable parameters: {trainable:,}")
    print(f"Non-trainable parameters: {total - trainable:,}")
    return total, trainable


def save_checkpoint(model, optimizer, epoch, metrics, filename=None):
    """Save training checkpoint."""
    if filename is None:
        filename = CHECKPOINT_PATH
    
    checkpoint = {
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'metrics': metrics,
        'timestamp': datetime.now().isoformat()
    }
    torch.save(checkpoint, filename)
    print(f"Checkpoint saved to {filename}")


def load_checkpoint(model, optimizer=None, filename=None, map_location=None):
    """Load training checkpoint."""
    if filename is None:
        filename = CHECKPOINT_PATH
    
    if map_location is None:
        map_location = DEVICE
    
    checkpoint = torch.load(filename, map_location=map_location)
    model.load_state_dict(checkpoint['model_state_dict'])
    
    if optimizer is not None:
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
    
    print(f"Checkpoint loaded from {filename}")
    print(f"Resuming from epoch {checkpoint['epoch']}")
    
    return checkpoint


def get_class_distribution(df, label_col='label'):
    """Get class distribution statistics."""
    distribution = df[label_col].value_counts().sort_index()
    percentages = distribution / len(df) * 100
    
    stats = {}
    for i, (idx, count) in enumerate(distribution.items()):
        class_name = CLASS_NAMES[idx] if idx < len(CLASS_NAMES) else f"Class_{idx}"
        stats[class_name] = {
            'count': count,
            'percentage': percentages.iloc[i]
        }
    
    return stats


def print_model_summary(model, input_size=(1, 3, 224, 224)):
    """Print model summary (simplified version)."""
    print("\n" + "="*60)
    print("MODEL SUMMARY")
    print("="*60)
    
    total_params, trainable_params = count_parameters(model)
    
    print("\nArchitecture:")
    print("-"*40)
    for name, module in model.named_children():
        num_params = sum(p.numel() for p in module.parameters())
        print(f"  {name}: {module.__class__.__name__} ({num_params:,} params)")
    
    print("\n" + "="*60)


def save_experiment_config(config_dict, save_path='experiment_config.json'):
    """Save experiment configuration to JSON file."""
    # Convert non-serializable objects
    serializable_config = {}
    for key, value in config_dict.items():
        if isinstance(value, (int, float, str, bool, list, dict, type(None))):
            serializable_config[key] = value
        else:
            serializable_config[key] = str(value)
    
    serializable_config['timestamp'] = datetime.now().isoformat()
    
    with open(save_path, 'w') as f:
        json.dump(serializable_config, f, indent=4)
    print(f"Experiment config saved to {save_path}")


class AverageMeter:
    """Computes and stores the average and current value."""
    
    def __init__(self):
        self.reset()
    
    def reset(self):
        self.val = 0
        self.avg = 0
        self.sum = 0
        self.count = 0
    
    def update(self, val, n=1):
        self.val = val
        self.sum += val * n
        self.count += n
        self.avg = self.sum / self.count


class EarlyStopping:
    """Early stopping callback."""
    
    def __init__(self, patience=15, min_delta=0.001, mode='max'):
        self.patience = patience
        self.min_delta = min_delta
        self.mode = mode
        self.counter = 0
        self.best_score = None
        self.early_stop = False
        
    def __call__(self, score):
        if self.best_score is None:
            self.best_score = score
        elif self._is_improvement(score):
            self.best_score = score
            self.counter = 0
        else:
            self.counter += 1
            if self.counter >= self.patience:
                self.early_stop = True
        
        return self.early_stop
    
    def _is_improvement(self, score):
        if self.mode == 'max':
            return score > self.best_score + self.min_delta
        else:
            return score < self.best_score - self.min_delta