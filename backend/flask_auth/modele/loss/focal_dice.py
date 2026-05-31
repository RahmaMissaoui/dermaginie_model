# losses/focal_dice_loss.py
import torch
import torch.nn as nn
import torch.nn.functional as F
from config import FOCAL_GAMMA, LAMBDA_DICE, NUM_CLASSES


class UnifiedFocalLoss(nn.Module):
    """Combined Focal and Dice loss."""
    
    def __init__(self, alpha=None, gamma=FOCAL_GAMMA, lambda_dice=LAMBDA_DICE,
                 num_classes=NUM_CLASSES):
        super().__init__()
        self.gamma = gamma
        self.lambda_dice = lambda_dice
        self.num_classes = num_classes
        
        if alpha is not None:
            self.register_buffer('alpha', alpha.float())
        else:
            self.register_buffer('alpha', torch.ones(num_classes))

    def forward(self, logits, targets):
        probs = F.softmax(logits, dim=-1).clamp(1e-7, 1.0 - 1e-7)
        targets_oh = F.one_hot(targets, self.num_classes).float()

        # Focal component
        log_p = torch.log(probs)
        ce = -(targets_oh * log_p).sum(dim=-1)
        p_t = torch.exp(-ce)
        alpha_t = (targets_oh * self.alpha).sum(dim=-1)
        focal = alpha_t * (1.0 - p_t) ** self.gamma * ce

        # Dice component
        eps = 1e-6
        intersection = (targets_oh * probs).sum(dim=-1)
        dice = 1.0 - (2.0 * intersection + eps) / (
            targets_oh.sum(dim=-1) + probs.sum(dim=-1) + eps
        )

        loss = (focal + self.lambda_dice * dice).mean()
        return loss