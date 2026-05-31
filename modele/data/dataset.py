# data/dataset.py
import os
import numpy as np
import torch
from torch.utils.data import Dataset
import torchvision.transforms as T
from config import IMG_SIZE, IMAGENET_MEAN, IMAGENET_STD, PREPROCESSED_PATH


class SkinLesionDataset(Dataset):
    """Dataset for skin lesion images."""
    
    def __init__(self, df, transform=None):
        self.image_ids = df['image_id'].values
        self.labels = df['label'].values.astype(np.int64)
        self.transform = transform
        self.base_dir = PREPROCESSED_PATH

    def __len__(self):
        return len(self.labels)

    def __getitem__(self, idx):
        img_path = os.path.join(self.base_dir, f"{self.image_ids[idx]}.npy")
        img_uint8 = np.load(img_path)
        
        if self.transform:
            img = self.transform(img_uint8)
        else:
            img = torch.from_numpy(img_uint8).permute(2, 0, 1).float() / 255.0
            
        label = torch.tensor(self.labels[idx], dtype=torch.long)
        return img, label


def get_transforms():
    """Get training and evaluation transforms."""
    _normalise = T.Compose([
        T.ToTensor(),
        T.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
        T.RandomErasing(p=0.2, scale=(0.02, 0.1)),
    ])

    train_transform = T.Compose([
        T.ToPILImage(),
        T.RandomHorizontalFlip(),
        T.RandomVerticalFlip(),
        T.RandomRotation(degrees=45),
        T.RandomAffine(degrees=0, translate=(0.1, 0.1)),
        T.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2, hue=0.03),
        T.GaussianBlur(kernel_size=3, sigma=(0.1, 2.0)),
        _normalise,
    ])

    eval_transform = T.Compose([
        T.ToPILImage(),
        T.ToTensor(),
        T.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
    ])

    return train_transform, eval_transform