# evaluation/metrics.py
import numpy as np
import torch
import torch.nn.functional as F
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix
from config import DEVICE, CLASS_NAMES
from training.train import run_epoch


def evaluate_model(model, val_loader, test_loader, test_df, criterion, optimizer, device=DEVICE):
    """Evaluate model on validation and test sets."""
    for split, loader, label in [
        ('VALIDATION', val_loader, None),
        ('TEST', test_loader, test_df['label'].values)
    ]:
        print(f'\n=== {split} SET ===')
        m = run_epoch(model, loader, criterion, optimizer, device, training=False)
        for k, v in m.items():
            print(f'  {k}: {v:.4f}')

    # Per-class report (test only)
    model.eval()
    all_probs, all_labels = [], []
    with torch.no_grad():
        for imgs, labels in test_loader:
            logits = model(imgs.to(device))
            probs = F.softmax(logits, dim=-1)
            all_probs.append(probs.cpu())
            all_labels.append(labels)

    all_probs = torch.cat(all_probs).numpy()
    all_labels = torch.cat(all_labels).numpy()
    all_preds = all_probs.argmax(axis=1)

    print('\nClassification Report (Test Set):')
    print(classification_report(all_labels, all_preds,
                                target_names=CLASS_NAMES, digits=4))
    return all_labels, all_preds


def plot_confusion_matrix(y_true, y_pred, class_names, save_path='confusion_matrix.png'):
    """Plot confusion matrix."""
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=class_names, yticklabels=class_names)
    plt.xlabel('Predicted')
    plt.ylabel('True')
    plt.title('Confusion Matrix — Test Set')
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()


def plot_training_curves(history, save_path='training_curves.png'):
    """Plot training curves for loss, accuracy, and AUC."""
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    for ax, metric in zip(axes, ['loss', 'acc', 'auc']):
        label = {'loss': 'Loss', 'acc': 'Accuracy', 'auc': 'AUC'}[metric]
        ax.plot(history[f'train_{metric}'], label='Train', linewidth=2)
        ax.plot(history[f'val_{metric}'], label='Val', linewidth=2)
        ax.set_title(label)
        ax.set_xlabel('Epoch')
        ax.legend()
        ax.grid(True, alpha=0.3)
    plt.suptitle('Training History', fontsize=14)
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()