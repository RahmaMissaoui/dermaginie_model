# training/scheduler.py
import torch
from config import LEARNING_RATE, WEIGHT_DECAY, LR_PATIENCE


def get_optimizer(model):
    """Create AdamW optimizer for trainable parameters."""
    return torch.optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=LEARNING_RATE,
        weight_decay=WEIGHT_DECAY
    )


def get_scheduler(optimizer):
    """Create ReduceLROnPlateau scheduler."""
    return torch.optim.lr_scheduler.ReduceLROnPlateau(
        optimizer,
        mode='max',
        factor=0.5,
        patience=LR_PATIENCE,
        min_lr=1e-6,
    )