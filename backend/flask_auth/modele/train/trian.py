# training/train.py
import torch
import torch.nn.functional as F
from torchmetrics import AUROC
from config import DEVICE, CHECKPOINT_PATH, EARLY_STOP_PATIENCE
from .callbacks import GradualUnfreeze


def run_epoch(model, loader, criterion, optimizer, device, training=True):
    """Run a single training or validation epoch."""
    model.train(training)
    total_loss, correct, total = 0.0, 0, 0
    auc_metric = AUROC(task='multiclass', num_classes=7).to(device)
    num_batches = len(loader)
    phase = 'Train' if training else 'Val  '

    for batch_idx, (imgs, labels) in enumerate(loader, 1):
        imgs = imgs.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        with torch.set_grad_enabled(training):
            logits = model(imgs)
            loss = criterion(logits, labels)

        if training:
            optimizer.zero_grad()
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()

        probs = F.softmax(logits.detach(), dim=-1)
        preds = probs.argmax(dim=-1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)
        total_loss += loss.item() * labels.size(0)
        auc_metric.update(probs, labels)

        # Progress bar
        running_loss = total_loss / total
        running_acc = correct / total
        filled = int(30 * batch_idx / num_batches)
        bar = '#' * filled + '.' * (30 - filled)
        msg = '  {} [{}] {}/{} loss={:.4f} acc={:.4f}'.format(
            phase, bar, batch_idx, num_batches, running_loss, running_acc
        )
        print(msg, end='\r', flush=True)

    print()
    return {
        'loss': total_loss / total,
        'accuracy': correct / total,
        'auc': auc_metric.compute().item(),
    }


def train(model, train_loader, val_loader, criterion, optimizer, scheduler,
          epochs, device):
    """Main training loop."""
    history = {'train_loss': [], 'train_acc': [], 'train_auc': [],
               'val_loss': [], 'val_acc': [], 'val_auc': []}
    best_auc = 0.0
    wait = 0
    prev_lr = optimizer.param_groups[0]['lr']
    unfreezer = GradualUnfreeze(model, optimizer, patience=4)

    for epoch in range(1, epochs + 1):
        current_lr = optimizer.param_groups[0]['lr']
        print('\nEpoch {:03d}/{}  lr={:.2e}  {}'.format(epoch, epochs, current_lr, '-' * 50))

        train_m = run_epoch(model, train_loader, criterion, optimizer, device, training=True)
        val_m = run_epoch(model, val_loader, criterion, optimizer, device, training=False)

        for key in ['loss', 'accuracy', 'auc']:
            history[f'train_{key}'].append(train_m[key])
            history[f'val_{key}'].append(val_m[key])

        print('  train  loss={:.4f}  acc={:.4f}  auc={:.4f}'.format(
            train_m['loss'], train_m['accuracy'], train_m['auc']))
        print('  val    loss={:.4f}  acc={:.4f}  auc={:.4f}'.format(
            val_m['loss'], val_m['accuracy'], val_m['auc']))

        current_auc = val_m['auc']

        if current_auc > best_auc:
            best_auc = current_auc
            torch.save(model.state_dict(), CHECKPOINT_PATH)
            print('  > New best  val_auc={:.4f}  checkpoint saved'.format(best_auc))
            wait = 0
        else:
            wait += 1
            print('  No improvement ({}/{})  best={:.4f}'.format(
                wait, EARLY_STOP_PATIENCE, best_auc))

        scheduler.step(current_auc)
        new_lr = optimizer.param_groups[0]['lr']
        if new_lr < prev_lr:
            print('  LR reduced  {:.2e} -> {:.2e}'.format(prev_lr, new_lr))
        prev_lr = new_lr

        unfreezer.step(current_auc)

        if wait >= EARLY_STOP_PATIENCE:
            print('\n  Early stopping. Best val_auc={:.4f}'.format(best_auc))
            break

    model.load_state_dict(torch.load(CHECKPOINT_PATH, map_location=device))
    print('\nTraining complete. Best val_auc={:.4f}'.format(best_auc))
    return history