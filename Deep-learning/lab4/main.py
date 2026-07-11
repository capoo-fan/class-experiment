from __future__ import annotations

import argparse
import csv
import json
import math
import os
import random
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable

os.environ.setdefault(
    "MPLCONFIGDIR",
    str(Path(__file__).resolve().parent / ".matplotlib-cache"),
)

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import torch
from torch import Tensor, nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, Dataset, Subset
from tqdm import tqdm


ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "dataset_for_DL_course" / "dataset"
DEFAULT_OUTPUT_DIR = ROOT / "outputs"


@dataclass
class RunConfig:
    dataset_dir: str
    output_dir: str
    epochs: int
    batch_size: int
    learning_rate: float
    weight_decay: float
    val_split: float
    base_channels: int
    scale: float
    seed: int
    device: str


class DualEnergyDataset(Dataset):
    """Memory-mapped paired noisy/target images for efficient local training."""

    def __init__(
        self,
        input_path: Path,
        target_path: Path | None = None,
        *,
        scale: float = 1.5,
        augment: bool = False,
    ) -> None:
        self.inputs = np.load(input_path, mmap_mode="r")
        self.targets = np.load(target_path, mmap_mode="r") if target_path else None
        self.scale = scale
        self.augment = augment

    def __len__(self) -> int:
        return int(self.inputs.shape[0])

    def __getitem__(self, idx: int) -> tuple[Tensor, Tensor] | Tensor:
        # 原始数据是 float64，这里转为 float32 并归一化到较稳定的训练范围。
        x = torch.from_numpy(np.asarray(self.inputs[idx], dtype=np.float32))
        x = torch.clamp(x / self.scale, 0.0, 1.0)

        if self.targets is None:
            return x

        y = torch.from_numpy(np.asarray(self.targets[idx], dtype=np.float32))
        y = torch.clamp(y / self.scale, 0.0, 1.0)

        if self.augment:
            x, y = random_flip_and_rotate(x, y)

        return x, y


def random_flip_and_rotate(x: Tensor, y: Tensor) -> tuple[Tensor, Tensor]:

    if random.random() < 0.5:
        x = torch.flip(x, dims=[1])
        y = torch.flip(y, dims=[1])
    if random.random() < 0.5:
        x = torch.flip(x, dims=[2])
        y = torch.flip(y, dims=[2])
    k = random.randint(0, 3)
    if k:
        x = torch.rot90(x, k, dims=[1, 2])
        y = torch.rot90(y, k, dims=[1, 2])
    return x.contiguous(), y.contiguous()


class ConvBlock(nn.Module):
    def __init__(self, in_channels: int, out_channels: int) -> None:
        super().__init__()
        groups = min(8, out_channels)
        # 两层 3x3 卷积提取局部图像特征，GroupNorm 对小 batch 更稳定。
        self.block = nn.Sequential(
            nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1),
            nn.GroupNorm(groups, out_channels),
            nn.SiLU(inplace=True),
            nn.Conv2d(out_channels, out_channels, kernel_size=3, padding=1),
            nn.GroupNorm(groups, out_channels),
            nn.SiLU(inplace=True),
        )

    def forward(self, x: Tensor) -> Tensor:
        return self.block(x)


class ResidualUNet(nn.Module):
    """Small residual U-Net for two-channel image correction."""

    def __init__(self, base_channels: int = 32) -> None:
        super().__init__()
        c1, c2, c3 = base_channels, base_channels * 2, base_channels * 4

        # 编码器逐步下采样，提取不同尺度的图像结构信息。
        self.enc1 = ConvBlock(2, c1)
        self.enc2 = ConvBlock(c1, c2)
        self.bottleneck = ConvBlock(c2, c3)
        self.pool = nn.MaxPool2d(2)

        # 解码器上采样，并通过跳跃连接找回边缘和细节。
        self.up2 = nn.ConvTranspose2d(c3, c2, kernel_size=2, stride=2)
        self.dec2 = ConvBlock(c2 + c2, c2)
        self.up1 = nn.ConvTranspose2d(c2, c1, kernel_size=2, stride=2)
        self.dec1 = ConvBlock(c1 + c1, c1)
        self.residual_head = nn.Conv2d(c1, 2, kernel_size=1)

    def forward(self, x: Tensor) -> Tensor:
        e1 = self.enc1(x)
        e2 = self.enc2(self.pool(e1))
        b = self.bottleneck(self.pool(e2))

        d2 = self.up2(b)
        d2 = self.dec2(torch.cat([d2, e2], dim=1))
        d1 = self.up1(d2)
        d1 = self.dec1(torch.cat([d1, e1], dim=1))

        # 模型学习噪声，最终用输入减去残差得到校正图像。
        residual = self.residual_head(d1)
        return x - residual


def choose_device(requested: str) -> torch.device:
    if requested != "auto":
        if requested == "mps" and not torch.backends.mps.is_available():
            raise RuntimeError(
                "MPS was requested, but torch.backends.mps.is_available() is False. "
                "Use --device auto/cpu here, or run on a macOS environment where MPS is available."
            )
        return torch.device(requested)
    if torch.backends.mps.is_available():
        return torch.device("mps")
    if torch.cuda.is_available():
        return torch.device("cuda")
    return torch.device("cpu")


def seed_everything(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)


def gradient_loss(pred: Tensor, target: Tensor) -> Tensor:
    # 约束横向和纵向梯度，帮助预测结果保留边缘结构。
    pred_dx = pred[..., :, 1:] - pred[..., :, :-1]
    target_dx = target[..., :, 1:] - target[..., :, :-1]
    pred_dy = pred[..., 1:, :] - pred[..., :-1, :]
    target_dy = target[..., 1:, :] - target[..., :-1, :]
    return F.l1_loss(pred_dx, target_dx) + F.l1_loss(pred_dy, target_dy)


def denoise_loss(pred: Tensor, target: Tensor) -> Tensor:
    # L1 保证整体灰度接近，MSE 惩罚较大误差，梯度损失保护边缘。
    l1 = F.l1_loss(pred, target)
    mse = F.mse_loss(pred, target)
    edge = gradient_loss(pred, target)
    return l1 + 0.25 * mse + 0.05 * edge


def split_indices(length: int, val_split: float, seed: int) -> tuple[list[int], list[int]]:
    rng = np.random.default_rng(seed)
    indices = rng.permutation(length).tolist()
    val_count = max(1, int(length * val_split))
    return indices[val_count:], indices[:val_count]


def build_loaders(args: argparse.Namespace) -> tuple[DataLoader, DataLoader]:
    dataset_dir = Path(args.dataset_dir)
    input_path = dataset_dir / "phantom_input_train.npy"
    target_path = dataset_dir / "phantom_target_train.npy"

    # 训练集开启简单几何增强；验证集保持原图，便于稳定评估。
    train_dataset = DualEnergyDataset(input_path, target_path, scale=args.scale, augment=True)
    val_dataset = DualEnergyDataset(input_path, target_path, scale=args.scale, augment=False)
    train_idx, val_idx = split_indices(len(train_dataset), args.val_split, args.seed)

    train_loader = DataLoader(
        Subset(train_dataset, train_idx),
        batch_size=args.batch_size,
        shuffle=True,
        num_workers=args.num_workers,
        drop_last=False,
    )
    val_loader = DataLoader(
        Subset(val_dataset, val_idx),
        batch_size=args.batch_size,
        shuffle=False,
        num_workers=args.num_workers,
        drop_last=False,
    )
    return train_loader, val_loader


def run_epoch(
    model: nn.Module,
    loader: DataLoader,
    device: torch.device,
    optimizer: torch.optim.Optimizer | None = None,
) -> float:
    training = optimizer is not None
    model.train(training)
    total_loss = 0.0
    total_seen = 0

    with torch.set_grad_enabled(training):
        for x, y in tqdm(loader, leave=False, desc="train" if training else "valid"):
            x = x.to(device, non_blocking=True)
            y = y.to(device, non_blocking=True)
            pred = model(x)
            loss = denoise_loss(pred, y)

            if training:
                # 标准反向传播流程；梯度裁剪用于避免偶发梯度过大。
                optimizer.zero_grad(set_to_none=True)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()

            batch_size = int(x.shape[0])
            total_loss += float(loss.detach().cpu()) * batch_size
            total_seen += batch_size

    return total_loss / max(1, total_seen)


def save_checkpoint(
    path: Path,
    model: nn.Module,
    optimizer: torch.optim.Optimizer,
    config: RunConfig,
    epoch: int,
    val_loss: float,
) -> None:
    payload = {
        "model_state": model.state_dict(),
        "optimizer_state": optimizer.state_dict(),
        "config": asdict(config),
        "epoch": epoch,
        "val_loss": val_loss,
    }
    torch.save(payload, path)


def write_history(history_path: Path, history: list[dict[str, float]]) -> None:
    with history_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["epoch", "train_loss", "val_loss", "lr"])
        writer.writeheader()
        writer.writerows(history)


def plot_history(history: list[dict[str, float]], out_path: Path) -> None:
    epochs = [row["epoch"] for row in history]
    train_loss = [row["train_loss"] for row in history]
    val_loss = [row["val_loss"] for row in history]

    fig, ax = plt.subplots(figsize=(6, 4), dpi=160)
    ax.plot(epochs, train_loss, marker="o", label="train")
    ax.plot(epochs, val_loss, marker="o", label="valid")
    ax.set_xlabel("epoch")
    ax.set_ylabel("loss")
    ax.set_title("Training curve")
    ax.grid(alpha=0.25)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)


def train(args: argparse.Namespace) -> Path:
    seed_everything(args.seed)
    output_dir = Path(args.output_dir)
    checkpoint_dir = output_dir / "checkpoints"
    figure_dir = output_dir / "figures"
    checkpoint_dir.mkdir(parents=True, exist_ok=True)
    figure_dir.mkdir(parents=True, exist_ok=True)

    device = choose_device(args.device)
    print(f"Using device: {device}")

    train_loader, val_loader = build_loaders(args)
    model = ResidualUNet(base_channels=args.base_channels).to(device)
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=args.learning_rate,
        weight_decay=args.weight_decay,
    )
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
        optimizer,
        T_max=max(1, args.epochs),
        eta_min=args.learning_rate * 0.05,
    )

    config = RunConfig(
        dataset_dir=str(Path(args.dataset_dir).resolve()),
        output_dir=str(output_dir.resolve()),
        epochs=args.epochs,
        batch_size=args.batch_size,
        learning_rate=args.learning_rate,
        weight_decay=args.weight_decay,
        val_split=args.val_split,
        base_channels=args.base_channels,
        scale=args.scale,
        seed=args.seed,
        device=str(device),
    )

    best_loss = math.inf
    best_path = checkpoint_dir / "best_model.pt"
    last_path = checkpoint_dir / "last_model.pt"
    history: list[dict[str, float]] = []

    for epoch in range(1, args.epochs + 1):
        print(f"\nEpoch {epoch}/{args.epochs}")
        train_loss = run_epoch(model, train_loader, device, optimizer)
        val_loss = run_epoch(model, val_loader, device)
        scheduler.step()

        row = {
            "epoch": epoch,
            "train_loss": train_loss,
            "val_loss": val_loss,
            "lr": scheduler.get_last_lr()[0],
        }
        history.append(row)
        print(
            f"epoch={epoch} train_loss={train_loss:.6f} "
            f"val_loss={val_loss:.6f} lr={row['lr']:.2e}"
        )

        save_checkpoint(last_path, model, optimizer, config, epoch, val_loss)
        # 按验证集损失保存最优模型，后续预测使用 best_model.pt。
        if val_loss < best_loss:
            best_loss = val_loss
            save_checkpoint(best_path, model, optimizer, config, epoch, val_loss)
            print(f"Saved new best checkpoint: {best_path}")

    write_history(output_dir / "training_history.csv", history)
    plot_history(history, figure_dir / "training_curve.png")

    with (output_dir / "metrics.json").open("w", encoding="utf-8") as f:
        json.dump(
            {
                "best_val_loss": best_loss,
                "best_checkpoint": str(best_path),
                "history": history,
                "config": asdict(config),
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    return best_path


def load_model(checkpoint_path: Path, device: torch.device) -> tuple[nn.Module, dict]:
    checkpoint = torch.load(checkpoint_path, map_location=device)
    config = checkpoint["config"]
    model = ResidualUNet(base_channels=int(config["base_channels"])).to(device)
    model.load_state_dict(checkpoint["model_state"])
    model.eval()
    return model, config


def tensor_from_numpy(sample: np.ndarray, scale: float, device: torch.device) -> Tensor:
    x = torch.from_numpy(np.asarray(sample, dtype=np.float32)).unsqueeze(0)
    x = torch.clamp(x / scale, 0.0, 1.0)
    return x.to(device)


def save_prediction_figure(prediction: np.ndarray, out_path: Path, title: str) -> None:
    # 每个样本保存一张图，左右分别显示 f 和 g 两个预测通道。
    vmax = max(1.0, float(np.percentile(prediction, 99.5)))
    fig, axes = plt.subplots(1, 2, figsize=(6.2, 3.0), dpi=160)
    for ax, channel, name in zip(axes, prediction, ["f", "g"]):
        image = ax.imshow(channel, cmap="viridis", vmin=0.0, vmax=vmax)
        ax.set_title(f"{title}_{name}")
        ax.set_xticks([])
        ax.set_yticks([])
        fig.colorbar(image, ax=ax, fraction=0.046, pad=0.04)
    fig.tight_layout()
    fig.savefig(out_path)
    plt.close(fig)


def predict(args: argparse.Namespace) -> Path:
    output_dir = Path(args.output_dir)
    prediction_dir = output_dir / "predictions"
    prediction_dir.mkdir(parents=True, exist_ok=True)

    checkpoint_path = Path(args.checkpoint)
    device = choose_device(args.device)
    model, config = load_model(checkpoint_path, device)
    scale = float(config["scale"])

    dataset_dir = Path(args.dataset_dir)
    test_sets = [
        ("phantom", dataset_dir / "phantom_input_test.npy"),
        ("real", dataset_dir / "real_input_test.npy"),
    ]

    manifest: list[str] = []
    all_predictions: list[np.ndarray] = []

    with torch.no_grad():
        # 两个测试集各 25 张，合计输出实验要求的 50 张预测图片。
        for prefix, path in test_sets:
            data = np.load(path, mmap_mode="r")
            for idx in tqdm(range(int(data.shape[0])), desc=f"predict {prefix}"):
                x = tensor_from_numpy(data[idx], scale, device)
                pred = model(x).squeeze(0).detach().cpu().numpy()
                # 反归一化回原始强度范围，并裁剪掉不合理的负值。
                pred = np.clip(pred * scale, 0.0, None).astype(np.float32)
                all_predictions.append(pred)

                png_path = prediction_dir / f"{prefix}_pred_{idx:02d}.png"
                save_prediction_figure(pred, png_path, f"{prefix}_pred_{idx:02d}")
                manifest.append(str(png_path.relative_to(output_dir)))

    np.save(output_dir / "predictions_50.npy", np.stack(all_predictions, axis=0))
    with (output_dir / "prediction_manifest.txt").open("w", encoding="utf-8") as f:
        f.write("\n".join(manifest) + "\n")

    print(f"Saved {len(manifest)} prediction images to {prediction_dir}")
    return prediction_dir


def inspect_dataset(args: argparse.Namespace) -> None:
    dataset_dir = Path(args.dataset_dir)
    for path in sorted(dataset_dir.glob("*.npy")):
        arr = np.load(path, mmap_mode="r")
        print(
            f"{path.name}: shape={arr.shape}, dtype={arr.dtype}, "
            f"min={float(arr.min()):.6f}, max={float(arr.max()):.6f}, "
            f"mean={float(arr.mean()):.6f}, std={float(arr.std()):.6f}"
        )


def add_shared_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--dataset-dir", type=Path, default=DATA_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--device", default="auto", help="auto, mps, cuda, or cpu")
    parser.add_argument("--scale", type=float, default=1.5)
    parser.add_argument("--seed", type=int, default=2026)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect_parser = subparsers.add_parser("inspect", help="Print dataset metadata.")
    add_shared_args(inspect_parser)

    train_parser = subparsers.add_parser("train", help="Train the correction model.")
    add_shared_args(train_parser)
    train_parser.add_argument("--epochs", type=int, default=12)
    train_parser.add_argument("--batch-size", type=int, default=8)
    train_parser.add_argument("--learning-rate", type=float, default=2e-4)
    train_parser.add_argument("--weight-decay", type=float, default=1e-4)
    train_parser.add_argument("--val-split", type=float, default=0.1)
    train_parser.add_argument("--base-channels", type=int, default=32)
    train_parser.add_argument("--num-workers", type=int, default=0)

    predict_parser = subparsers.add_parser("predict", help="Save 50 prediction images.")
    add_shared_args(predict_parser)
    predict_parser.add_argument(
        "--checkpoint",
        type=Path,
        default=DEFAULT_OUTPUT_DIR / "checkpoints" / "best_model.pt",
    )

    all_parser = subparsers.add_parser("all", help="Train, then save all predictions.")
    add_shared_args(all_parser)
    all_parser.add_argument("--epochs", type=int, default=12)
    all_parser.add_argument("--batch-size", type=int, default=8)
    all_parser.add_argument("--learning-rate", type=float, default=2e-4)
    all_parser.add_argument("--weight-decay", type=float, default=1e-4)
    all_parser.add_argument("--val-split", type=float, default=0.1)
    all_parser.add_argument("--base-channels", type=int, default=32)
    all_parser.add_argument("--num-workers", type=int, default=0)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "inspect":
        inspect_dataset(args)
    elif args.command == "train":
        train(args)
    elif args.command == "predict":
        predict(args)
    elif args.command == "all":
        checkpoint = train(args)
        args.checkpoint = checkpoint
        predict(args)
    else:
        raise ValueError(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
