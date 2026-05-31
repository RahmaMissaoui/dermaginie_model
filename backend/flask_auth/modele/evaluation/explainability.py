# evaluation/explainability.py
import numpy as np
import cv2
import torch
import torch.nn.functional as F
import matplotlib.pyplot as plt
from config import IMAGENET_MEAN, IMAGENET_STD, DEVICE, CLASS_NAMES


class GradCAM:
    """Gradient-weighted Class Activation Mapping."""
    
    def __init__(self, model):
        self.model = model
        self.activations = None
        self.gradients = None

        target_layer = model.cnn_branch.features.denseblock4
        self._fwd_hook = target_layer.register_forward_hook(self._save_activation)
        self._bwd_hook = target_layer.register_full_backward_hook(self._save_gradient)

    def _save_activation(self, module, input, output):
        self.activations = output.detach()

    def _save_gradient(self, module, grad_input, grad_output):
        self.gradients = grad_output[0].detach()

    def __call__(self, img_tensor, class_idx=None):
        self.model.eval()
        self.model.zero_grad()

        logits = self.model(img_tensor)
        if class_idx is None:
            class_idx = logits.argmax(dim=-1).item()

        logits[0, class_idx].backward()

        pooled_grads = self.gradients[0].mean(dim=(-2, -1))
        act_map = self.activations[0]

        heatmap = (pooled_grads[:, None, None] * act_map).sum(dim=0)
        heatmap = F.relu(heatmap)
        heatmap = heatmap / (heatmap.max() + 1e-8)
        heatmap = heatmap.cpu().numpy()
        return cv2.resize(heatmap, (224, 224))

    def remove_hooks(self):
        self._fwd_hook.remove()
        self._bwd_hook.remove()


def get_vit_attention_rollout(model, img_tensor):
    """Extract attention rollout from ViT."""
    model.eval()
    
    with torch.no_grad():
        vit_model = model.vit_branch.vit
        outputs = vit_model(
            pixel_values=img_tensor,
            output_attentions=True,
            return_dict=True
        )

        if outputs.attentions is None:
            print("Warning: Attentions not returned. Using fallback.")
            return np.ones((224, 224), dtype=np.float32) * 0.5

    rollout = torch.eye(197, device=img_tensor.device)
    
    for attn in outputs.attentions:
        attn_avg = attn[0].mean(dim=0)
        attn_res = 0.5 * attn_avg + 0.5 * torch.eye(197, device=img_tensor.device)
        attn_res = attn_res / attn_res.sum(dim=-1, keepdim=True)
        rollout = attn_res @ rollout

    cls_attn = rollout[0, 1:].cpu().numpy().reshape(14, 14)
    heatmap = cv2.resize(cls_attn, (224, 224))
    heatmap = (heatmap - heatmap.min()) / (heatmap.max() - heatmap.min() + 1e-8)
    
    return heatmap


def _denormalize(tensor):
    """Denormalize image tensor for visualization."""
    mean = torch.tensor(IMAGENET_MEAN).view(3, 1, 1)
    std = torch.tensor(IMAGENET_STD).view(3, 1, 1)
    img = tensor.cpu() * std + mean
    img = img.permute(1, 2, 0).numpy()
    return np.clip(img * 255, 0, 255).astype(np.uint8)


def _overlay_heatmap(img_rgb, heatmap, alpha=0.4):
    """Overlay heatmap on image."""
    h_uint8 = np.uint8(255 * heatmap)
    h_color = cv2.applyColorMap(h_uint8, cv2.COLORMAP_JET)
    h_rgb = cv2.cvtColor(h_color, cv2.COLOR_BGR2RGB)
    return cv2.addWeighted(img_rgb, 1 - alpha, h_rgb, alpha, 0)


def explain_sample(model, df_subset, dataset, sample_idx=0, save=True):
    """Generate explanation visualization for a sample."""
    img_tensor, label = dataset[sample_idx]
    true_label = CLASS_NAMES[label.item()]
    img_tensor = img_tensor.unsqueeze(0).to(DEVICE)

    # Prediction
    model.eval()
    with torch.no_grad():
        logits = model(img_tensor)
        probs = F.softmax(logits, dim=-1)[0].cpu().numpy()
    pred_idx = probs.argmax()
    pred_label = CLASS_NAMES[pred_idx]
    pred_conf = probs[pred_idx]

    # Grad-CAM
    gradcam = GradCAM(model)
    gc_heatmap = gradcam(img_tensor, class_idx=pred_idx)
    gradcam.remove_hooks()

    # Attention Rollout
    ar_heatmap = get_vit_attention_rollout(model, img_tensor)

    img_disp = _denormalize(img_tensor[0])

    fig, axes = plt.subplots(1, 4, figsize=(22, 6))
    axes[0].imshow(img_disp)
    axes[0].set_title(f'Original\nTrue: {true_label}', fontsize=12)
    axes[1].