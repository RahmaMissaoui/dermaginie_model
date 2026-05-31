# models/cnn_branch.py
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchvision.models as tvm
from config import CNN_FREEZE_UNTIL


class CNNBranch(nn.Module):
    """DenseNet169 branch for local texture feature extraction."""
    
    def __init__(self, freeze_until=CNN_FREEZE_UNTIL):
        super().__init__()
        base = tvm.densenet169(weights=tvm.DenseNet169_Weights.IMAGENET1K_V1)

        # Freeze first `freeze_until` named parameters
        params = list(base.named_parameters())
        for name, param in params[:freeze_until]:
            param.requires_grad = False

        self.features = base.features
        self.pool = nn.AdaptiveAvgPool2d((1, 1))
        self.norm = nn.BatchNorm1d(1664)
        self.dropout = nn.Dropout(0.3)

        trainable = sum(p.numel() for p in self.parameters() if p.requires_grad)
        total = sum(p.numel() for p in self.parameters())
        print(f'CNN  | trainable: {trainable:,} / {total:,}')

    def forward(self, x):
        x = self.features(x)
        x = F.relu(x, inplace=True)
        x = self.pool(x).flatten(1)
        x = self.norm(x)
        x = self.dropout(x)
        return x