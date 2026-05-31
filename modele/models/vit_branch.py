# models/vit_branch.py
import torch.nn as nn
from transformers import ViTModel
from config import VIT_FREEZE_BLOCKS


class ViTBranch(nn.Module):
    """ViT-B/16 branch for global structure feature extraction."""
    
    def __init__(self, freeze_blocks=VIT_FREEZE_BLOCKS):
        super().__init__()
        self.vit = ViTModel.from_pretrained('google/vit-base-patch16-224-in21k')

        # Freeze embeddings and first `freeze_blocks` encoder blocks
        for param in self.vit.embeddings.parameters():
            param.requires_grad = False
        for i, block in enumerate(self.vit.encoder.layer):
            for param in block.parameters():
                param.requires_grad = (i >= freeze_blocks)

        self.norm = nn.LayerNorm(768, eps=1e-6)
        self.dropout = nn.Dropout(0.1)

        trainable = sum(p.numel() for p in self.parameters() if p.requires_grad)
        total = sum(p.numel() for p in self.parameters())
        print(f'ViT  | trainable: {trainable:,} / {total:,}')

    def forward(self, x):
        out = self.vit(pixel_values=x)
        cls = out.last_hidden_state[:, 0, :]
        cls = self.norm(cls)
        cls = self.dropout(cls)
        return cls