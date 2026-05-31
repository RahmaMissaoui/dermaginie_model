# utils/visualization.py
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
from config import CLASS_NAMES, IMAGENET_MEAN, IMAGENET_STD


def plot_class_distribution(train_df, val_df, test_df, save_path='class_distribution.png'):
    """Plot class distribution for train/val/test splits."""
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    datasets = [('Train', train_df), ('Validation', val_df), ('Test', test_df)]
    
    for ax, (name, df) in zip(axes, datasets):
        counts = df['dx'].value_counts()
        bars = ax.bar(range(len(counts)), counts.values, color='steelblue')
        ax.set_xticks(range(len(counts)))
        ax.set_xticklabels(counts.index, rotation=45, ha='right')
        ax.set_title(f'{name} Set\nTotal: {len(df)} samples')
        ax.set_ylabel('Count')
        
        # Add value labels on bars
        for bar, count in zip(bars, counts.values):
            ax.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 5,
                    str(count), ha='center', va='bottom', fontsize=10)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()


def plot_sample_images(dataset, num_samples=5, save_path='sample_images.png'):
    """Plot sample images from dataset."""
    fig, axes = plt.subplots(1, num_samples, figsize=(15, 3))
    
    # Denormalize function
    def denormalize(tensor):
        mean = np.array(IMAGENET_MEAN).reshape(3, 1, 1)
        std = np.array(IMAGENET_STD).reshape(3, 1, 1)
        img = tensor.cpu().numpy()
        img = img * std + mean
        img = np.clip(img, 0, 1)
        return img.transpose(1, 2, 0)
    
    for i in range(num_samples):
        img, label = dataset[i]
        img_denorm = denormalize(img)
        axes[i].imshow(img_denorm)
        axes[i].set_title(f'Class: {CLASS_NAMES[label.item()]}')
        axes[i].axis('off')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()


def plot_prediction_vs_confidence(probs, true_labels, pred_labels, class_names,
                                  save_path='prediction_confidence.png'):
    """Plot prediction confidence distribution."""
    fig, axes = plt.subplots(1, 2, figsize=(12, 5))
    
    # Histogram of confidence scores
    confidences = np.max(probs, axis=1)
    correct_mask = (pred_labels == true_labels)
    
    axes[0].hist(confidences[correct_mask], bins=20, alpha=0.7, 
                 label='Correct', color='green', edgecolor='black')
    axes[0].hist(confidences[~correct_mask], bins=20, alpha=0.7,
                 label='Incorrect', color='red', edgecolor='black')
    axes[0].set_xlabel('Confidence Score')
    axes[0].set_ylabel('Frequency')
    axes[0].set_title('Prediction Confidence Distribution')
    axes[0].legend()
    
    # Per-class accuracy bar plot
    class_correct = {}
    for i, class_name in enumerate(class_names):
        mask = (true_labels == i)
        if mask.sum() > 0:
            class_correct[class_name] = (pred_labels[mask] == true_labels[mask]).sum() / mask.sum()
    
    classes = list(class_correct.keys())
    accuracies = list(class_correct.values())
    colors = ['green' if acc > 0.7 else 'orange' if acc > 0.5 else 'red' for acc in accuracies]
    
    bars = axes[1].bar(range(len(classes)), accuracies, color=colors, edgecolor='black')
    axes[1].set_xticks(range(len(classes)))
    axes[1].set_xticklabels(classes, rotation=45, ha='right')
    axes[1].set_ylim([0, 1])
    axes[1].set_ylabel('Accuracy')
    axes[1].set_title('Per-Class Accuracy')
    axes[1].axhline(y=0.7, color='green', linestyle='--', alpha=0.5, label='Good (70%)')
    axes[1].axhline(y=0.5, color='orange', linestyle='--', alpha=0.5, label='Fair (50%)')
    axes[1].legend()
    
    # Add value labels
    for bar, acc in zip(bars, accuracies):
        axes[1].text(bar.get_x() + bar.get_width()/2, bar.get_height() + 0.02,
                    f'{acc:.2%}', ha='center', va='bottom', fontsize=9)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()


def plot_learning_rate_vs_loss(lr_history, loss_history, save_path='lr_vs_loss.png'):
    """Plot learning rate vs loss for finding optimal LR."""
    plt.figure(figsize=(10, 6))
    plt.plot(lr_history, loss_history)
    plt.xscale('log')
    plt.xlabel('Learning Rate')
    plt.ylabel('Loss')
    plt.title('Learning Rate Finder')
    plt.grid(True, alpha=0.3)
    
    # Mark the recommended learning rate
    min_loss_idx = np.argmin(loss_history)
    best_lr = lr_history[min_loss_idx]
    plt.axvline(x=best_lr, color='red', linestyle='--', alpha=0.7)
    plt.text(best_lr, plt.ylim()[1] * 0.9, f'Best LR: {best_lr:.2e}', 
             ha='center', va='top', color='red')
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()


def save_experiment_results(history, metrics, save_dir='experiment_results'):
    """Save all experiment results to files."""
    import os
    import json
    from datetime import datetime
    
    os.makedirs(save_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Save training history
    history_df = pd.DataFrame(history)
    history_df.to_csv(f'{save_dir}/training_history_{timestamp}.csv', index=False)
    
    # Save metrics summary
    with open(f'{save_dir}/metrics_summary_{timestamp}.json', 'w') as f:
        json.dump(metrics, f, indent=4)
    
    # Plot and save all figures
    plot_training_curves(history, save_path=f'{save_dir}/training_curves_{timestamp}.png')
    
    print(f"Results saved to {save_dir}/")


def plot_training_curves(history, save_path='training_curves.png'):
    """Plot training curves for loss, accuracy, and AUC."""
    fig, axes = plt.subplots(1, 3, figsize=(18, 5))
    
    metrics = ['loss', 'accuracy', 'auc']
    titles = ['Loss', 'Accuracy', 'AUC']
    
    for ax, metric, title in zip(axes, metrics, titles):
        ax.plot(history[f'train_{metric}'], label='Train', linewidth=2)
        ax.plot(history[f'val_{metric}'], label='Validation', linewidth=2)
        ax.set_title(title)
        ax.set_xlabel('Epoch')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # Mark best validation value
        if metric != 'loss':
            best_val = max(history[f'val_{metric}'])
            best_epoch = history[f'val_{metric}'].index(best_val)
            ax.scatter(best_epoch, best_val, color='red', s=50, zorder=5)
            ax.annotate(f'Best: {best_val:.4f}', 
                       xy=(best_epoch, best_val),
                       xytext=(5, 5), textcoords='offset points',
                       fontsize=9, color='red')
        else:
            best_val = min(history[f'val_{metric}'])
            best_epoch = history[f'val_{metric}'].index(best_val)
            ax.scatter(best_epoch, best_val, color='red', s=50, zorder=5)
            ax.annotate(f'Best: {best_val:.4f}',
                       xy=(best_epoch, best_val),
                       xytext=(5, 5), textcoords='offset points',
                       fontsize=9, color='red')
    
    plt.suptitle('Training History', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.show()