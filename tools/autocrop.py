import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


NAMED_COLORS = {
    "white": (255, 255, 255),
    "black": (0, 0, 0),
    "red": (255, 0, 0),
    "green": (0, 255, 0),
    "blue": (0, 0, 255),
    "yellow": (255, 255, 0),
    "cyan": (0, 255, 255),
    "magenta": (255, 0, 255),
    "gray": (128, 128, 128),
    "grey": (128, 128, 128),
}

SUPPORTED_EXTENSIONS = {".png", ".jpg", ".jpeg", ".bmp", ".webp", ".tiff"}


def parse_color(color_str: str) -> tuple[int, int, int]:
    color_lower = color_str.lower().strip()

    if color_lower in NAMED_COLORS:
        return NAMED_COLORS[color_lower]

    hex_str = color_lower.lstrip("#")
    if len(hex_str) == 6 and all(c in "0123456789abcdef" for c in hex_str):
        return (
            int(hex_str[0:2], 16),
            int(hex_str[2:4], 16),
            int(hex_str[4:6], 16),
        )

    raise ValueError(
        f"Invalid color '{color_str}'. Use a name (white, blue, green...) or hex (#FF00AA)."
    )


def sample_background_color(pixels: np.ndarray) -> tuple[int, int, int]:
    """Sample the background color from the four corners of the image."""
    h, w = pixels.shape[:2]
    corners = [
        pixels[0, 0, :3],
        pixels[0, w - 1, :3],
        pixels[h - 1, 0, :3],
        pixels[h - 1, w - 1, :3],
    ]
    avg = np.mean(corners, axis=0).astype(int)
    return (int(avg[0]), int(avg[1]), int(avg[2]))


def compute_color_distance(pixels: np.ndarray, target: tuple[int, int, int]) -> np.ndarray:
    target_arr = np.array(target, dtype=np.float32)
    return np.sqrt(np.sum((pixels[:, :, :3].astype(np.float32) - target_arr) ** 2, axis=2))


def find_core_bbox_by_alpha(pixels: np.ndarray, alpha_threshold: int) -> tuple[int, int, int, int] | None:
    """Find bounding box of non-transparent pixels."""
    alpha = pixels[:, :, 3]
    mask = alpha > alpha_threshold

    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)

    if not rows.any():
        return None

    top = int(np.argmax(rows))
    bottom = int(len(rows) - 1 - np.argmax(rows[::-1]))
    left = int(np.argmax(cols))
    right = int(len(cols) - 1 - np.argmax(cols[::-1]))

    return (left, top, right + 1, bottom + 1)


def find_core_bbox_by_color(
    pixels: np.ndarray,
    bg_color: tuple[int, int, int],
    tolerance: float,
) -> tuple[int, int, int, int] | None:
    """Find bounding box of pixels that differ from the background color."""
    distance_map = compute_color_distance(pixels, bg_color)
    mask = distance_map > tolerance

    rows = np.any(mask, axis=1)
    cols = np.any(mask, axis=0)

    if not rows.any():
        return None

    top = int(np.argmax(rows))
    bottom = int(len(rows) - 1 - np.argmax(rows[::-1]))
    left = int(np.argmax(cols))
    right = int(len(cols) - 1 - np.argmax(cols[::-1]))

    return (left, top, right + 1, bottom + 1)


def autocrop(
    image: Image.Image,
    tolerance: float,
    padding: int,
    bg_color: tuple[int, int, int] | None,
    alpha_threshold: int,
) -> Image.Image:
    """
    Crop the outer boundaries of an image, keeping the core content intact.

    Strategy:
    1. If image has an alpha channel with meaningful transparency → crop by alpha.
    2. Otherwise → detect background color from corners (or use the provided one)
       and crop by color distance.
    """
    rgba = image.convert("RGBA")
    pixels = np.array(rgba)

    # Decide strategy: alpha-based or color-based
    alpha = pixels[:, :, 3]
    has_transparency = (alpha < 255).any() and (alpha > 0).any()

    if has_transparency and bg_color is None:
        bbox = find_core_bbox_by_alpha(pixels, alpha_threshold)
        strategy = "alpha"
    else:
        if bg_color is None:
            bg_color = sample_background_color(pixels)
        bbox = find_core_bbox_by_color(pixels, bg_color, tolerance)
        strategy = f"color RGB{bg_color}"

    if bbox is None:
        # Nothing to crop — return as-is
        return image

    left, top, right, bottom = bbox
    h, w = pixels.shape[:2]

    # Apply padding (expanding the bbox outward, clamped to image bounds)
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(w, right + padding)
    bottom = min(h, bottom + padding)

    cropped = image.crop((left, top, right, bottom))

    orig_w, orig_h = image.size
    new_w, new_h = cropped.size
    removed_x = orig_w - new_w
    removed_y = orig_h - new_h

    return cropped, strategy, removed_x, removed_y


def process_batch(
    input_dir: Path,
    output_dir: Path,
    tolerance: float,
    padding: int,
    bg_color: tuple[int, int, int] | None,
    alpha_threshold: int,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    image_files = sorted(
        f for f in input_dir.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
    )

    if not image_files:
        print(f"No images found in {input_dir}")
        return

    print(f"Found {len(image_files)} image(s) in {input_dir}")
    print(f"Tolerance: {tolerance}, Padding: {padding}px, Alpha threshold: {alpha_threshold}")
    print(f"Output directory: {output_dir}")
    print()

    for filepath in image_files:
        stem = filepath.stem
        output_path = output_dir / f"{stem}.png"

        try:
            image = Image.open(filepath)
            result, strategy, removed_x, removed_y = autocrop(
                image, tolerance, padding, bg_color, alpha_threshold
            )
            result.save(output_path, "PNG")
            print(f"  [OK] {filepath.name} -> {output_path.name}  "
                  f"({image.size[0]}x{image.size[1]} -> {result.size[0]}x{result.size[1]}, "
                  f"removed {removed_x}px wide / {removed_y}px tall, strategy: {strategy})")
        except Exception as e:
            print(f"  [FAIL] {filepath.name}: {e}")

    print()
    print("Done.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Autocrop images by removing outer empty space around the image core.\n"
            "Detects content boundaries using alpha transparency or background color,\n"
            "then cuts the unused exterior while leaving the core intact."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "-t", "--tolerance",
        type=float,
        default=30.0,
        help="Color distance tolerance for background detection (0-255). Higher = more aggressive crop. Default: 30",
    )
    parser.add_argument(
        "-p", "--padding",
        type=int,
        default=0,
        help="Extra pixels to keep around the detected core. Default: 0",
    )
    parser.add_argument(
        "-c", "--color",
        default=None,
        help=(
            "Force a specific background color to crop against. "
            "Name (white, black, green...) or hex (#FF00AA). "
            "If omitted: uses alpha channel if present, else samples corners."
        ),
    )
    parser.add_argument(
        "-a", "--alpha-threshold",
        type=int,
        default=10,
        dest="alpha_threshold",
        help="Alpha value below which a pixel is considered transparent (0-255). Default: 10",
    )
    parser.add_argument(
        "-i", "--input",
        default=None,
        help="Input directory. Default: tools/images-to-cut/",
    )
    parser.add_argument(
        "-o", "--output",
        default=None,
        help="Output directory. Default: <input>/output/",
    )

    args = parser.parse_args()

    bg_color = None
    if args.color is not None:
        try:
            bg_color = parse_color(args.color)
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    script_dir = Path(__file__).parent
    input_dir = Path(args.input) if args.input else script_dir / "images-to-cut"
    output_dir = Path(args.output) if args.output else input_dir / "output"

    if not input_dir.exists():
        print(f"Error: Input directory does not exist: {input_dir}", file=sys.stderr)
        sys.exit(1)

    process_batch(input_dir, output_dir, args.tolerance, args.padding, bg_color, args.alpha_threshold)


if __name__ == "__main__":
    main()
