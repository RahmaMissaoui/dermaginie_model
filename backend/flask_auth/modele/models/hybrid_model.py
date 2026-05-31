# models/hybrid_model.py
import torch.nn as nn
from .cnn_branch import CNNBranch
from .vit_branch import ViTBranch
from .fusion import BidirectionalCrossAttentionFusion
from config import NUM_CLASSES


class HybridModel(nn.Module):
    """Complete hybrid CNN-ViT model."""
    
    def __init__(self, num_classes=NUM_CLASSES):
        super().__init__()
        self.cnn_branch = CNNBranch()
        self.vit_branch = ViTBranch()
        self.fusion = BidirectionalCrossAttentionFusion(fused_dim=512, num_heads=8)

        self.head = nn.Sequential(
            nn.Linear(512, 256),
            nn.LayerNorm(256, eps=1e-6),
            nn.ReLU(inplace=True),
            nn.Dropout(0.5),
            nn.Linear(256, 128),
            nn.LayerNorm(128, eps=1e-6),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
            nn.Linear(128, num_classes),
        )

    def forward(self, x):
        cnn_feat = self.cnn_branch(x)
        vit_feat = self.vit_branch(x)
        fused = self.fusion(cnn_feat, vit_feat)
        logits = self.head(fused)
        return logits