# training/callbacks.py
import torch
from config import VIT_FREEZE_BLOCKS


class GradualUnfreeze:
    """Gradually unfreeze ViT encoder blocks when validation AUC plateaus."""
    
    def __init__(self, model, optimizer, patience=4):
        self.model = model
        self.optimizer = optimizer
        self.patience = patience
        self.wait = 0
        self.best_auc = 0.0
        self.next_to_unfreeze = VIT_FREEZE_BLOCKS - 1

    def step(self, val_auc):
        if val_auc > self.best_auc:
            self.best_auc = val_auc
            self.wait = 0
        else:
            self.wait += 1
            if self.wait >= self.patience and self.next_to_unfreeze >= 4:
                block = self.model.vit_branch.vit.encoder.layer[self.next_to_unfreeze]
                for param in block.parameters():
                    param.requires_grad = True
                self.optimizer.add_param_group({
                    'params': [p for p in block.parameters() if p.requires_grad],
                    'lr': self.optimizer.param_groups[0]['lr'] * 0.1,
                })
                print(f'\n→ Unfroze ViT encoder block {self.next_to_unfreeze}')
                self.next_to_unfreeze -= 1
                self.wait = 0