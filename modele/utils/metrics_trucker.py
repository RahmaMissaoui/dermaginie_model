# utils/metrics_tracker.py
class MetricsTracker:
    """Track and store metrics during training."""
    
    def __init__(self):
        self.history = {
            'train_loss': [],
            'train_acc': [],
            'train_auc': [],
            'val_loss': [],
            'val_acc': [],
            'val_auc': []
        }
        self.best_metrics = {
            'val_loss': float('inf'),
            'val_acc': 0.0,
            'val_auc': 0.0,
            'epoch': 0
        }
    
    def update(self, phase, loss, accuracy, auc, epoch=None):
        """Update metrics history."""
        self.history[f'{phase}_loss'].append(loss)
        self.history[f'{phase}_acc'].append(accuracy)
        self.history[f'{phase}_auc'].append(auc)
        
        if phase == 'val':
            if loss < self.best_metrics['val_loss']:
                self.best_metrics['val_loss'] = loss
                self.best_metrics['epoch'] = epoch
            if accuracy > self.best_metrics['val_acc']:
                self.best_metrics['val_acc'] = accuracy
            if auc > self.best_metrics['val_auc']:
                self.best_metrics['val_auc'] = auc
    
    def get_best(self):
        """Get best validation metrics."""
        return self.best_metrics
    
    def get_history(self):
        """Get full training history."""
        return self.history
    
    def reset(self):
        """Reset tracker."""
        self.history = {k: [] for k in self.history}
        self.best_metrics = {
            'val_loss': float('inf'),
            'val_acc': 0.0,
            'val_auc': 0.0,
            'epoch': 0
        }