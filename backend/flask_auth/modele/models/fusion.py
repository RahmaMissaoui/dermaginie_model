# models/fusion.py
import torch.nn as nn


class BidirectionalCrossAttentionFusion(nn.Module):
    """Bidirectional cross-attention fusion module."""
    
    def __init__(self, fused_dim=512, num_heads=8, dropout_rate=0.1):
        super().__init__()
        self.proj_cnn = nn.Linear(1664, fused_dim)
        self.proj_vit = nn.Linear(768, fused_dim)

        self.attn_cnn2vit = nn.MultiheadAttention(
            embed_dim=fused_dim, num_heads=num_heads,
            dropout=dropout_rate, batch_first=True
        )
        self.attn_vit2cnn = nn.MultiheadAttention(
            embed_dim=fused_dim, num_heads=num_heads,
            dropout=dropout_rate, batch_first=True
        )

        self.norm = nn.LayerNorm(fused_dim, eps=1e-6)
        self.ffn = nn.Linear(fused_dim, fused_dim)
        self.norm_out = nn.LayerNorm(fused_dim, eps=1e-6)
        self.dropout = nn.Dropout(dropout_rate)
        self.act = nn.GELU()

    def forward(self, cnn_feat, vit_feat):
        f_cnn = self.proj_cnn(cnn_feat).unsqueeze(1)
        f_vit = self.proj_vit(vit_feat).unsqueeze(1)

        ctx_cnn2vit, _ = self.attn_cnn2vit(query=f_cnn, key=f_vit, value=f_vit)
        ctx_vit2cnn, _ = self.attn_vit2cnn(query=f_vit, key=f_cnn, value=f_cnn)

        combined = (f_cnn + f_vit + ctx_cnn2vit + ctx_vit2cnn).squeeze(1)
        combined = self.norm(combined)

        out = self.norm_out(combined + self.dropout(self.act(self.ffn(combined))))
        return out