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


def compute_color_distance(pixels: np.ndarray, target: tuple[int, int, int]) -> np.ndarray:
    target_arr = np.array(target, dtype=np.float32)
    return np.sqrt(np.sum((pixels[:, :, :3].astype(np.float32) - target_arr) ** 2, axis=2))


def flood_fill_mask(distance_map: np.ndarray, tolerance: float) -> np.ndarray:
    h, w = distance_map.shape
    background = np.zeros((h, w), dtype=bool)
    visited = np.zeros((h, w), dtype=bool)
    queue = []

    for x in range(w):
        for y in [0, h - 1]:
            if distance_map[y, x] <= tolerance:
                queue.append((y, x))
                visited[y, x] = True
    for y in range(h):
        for x in [0, w - 1]:
            if distance_map[y, x] <= tolerance and not visited[y, x]:
                queue.append((y, x))
                visited[y, x] = True

    while queue:
        cy, cx = queue.pop(0)
        background[cy, cx] = True
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                visited[ny, nx] = True
                if distance_map[ny, nx] <= tolerance:
                    queue.append((ny, nx))

    return background


def remove_background(image: Image.Image, target_color: tuple[int, int, int], tolerance: float, everywhere: bool = False) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = np.array(rgba)

    distance_map = compute_color_distance(pixels, target_color)

    if everywhere:
        mask = distance_map <= tolerance
    else:
        mask = flood_fill_mask(distance_map, tolerance)

    pixels[mask, 3] = 0

    return Image.fromarray(pixels, "RGBA")


def process_batch(input_dir: Path, output_dir: Path, target_color: tuple[int, int, int], tolerance: float, everywhere: bool = False) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    image_files = sorted(
        f for f in input_dir.iterdir()
        if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
    )

    if not image_files:
        print(f"No images found in {input_dir}")
        return

    mode = "everywhere" if everywhere else "edges only (flood-fill)"
    print(f"Found {len(image_files)} image(s) in {input_dir}")
    print(f"Target color: RGB{target_color}, tolerance: {tolerance}, mode: {mode}")
    print(f"Output directory: {output_dir}")
    print()

    for filepath in image_files:
        stem = filepath.stem
        output_path = output_dir / f"{stem}.png"

        try:
            image = Image.open(filepath)
            result = remove_background(image, target_color, tolerance, everywhere)
            result.save(output_path, "PNG")
            print(f"  [OK] {filepath.name} -> {output_path.name}")
        except Exception as e:
            print(f"  [FAIL] {filepath.name}: {e}")

    print()
    print("Done.")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Remove background color from images in batch.",
    )
    parser.add_argument(
        "-c", "--color",
        default="white",
        help="Background color to remove. Name (white, blue, green...) or hex (#FF00AA). Default: white",
    )
    parser.add_argument(
        "-t", "--tolerance",
        type=float,
        default=30.0,
        help="Color distance tolerance (0-255). Higher = more aggressive removal. Default: 30",
    )
    parser.add_argument(
        "-e", "--everywhere",
        action="store_true",
        default=False,
        help="Remove the color everywhere in the image, not just the outer background. Default: off",
    )
    parser.add_argument(
        "-i", "--input",
        default=None,
        help="Input directory. Default: tools/images-to-remove-background/",
    )
    parser.add_argument(
        "-o", "--output",
        default=None,
        help="Output directory. Default: <input>/output/",
    )

    args = parser.parse_args()

    try:
        target_color = parse_color(args.color)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    script_dir = Path(__file__).parent
    input_dir = Path(args.input) if args.input else script_dir / "images-to-remove-background"
    output_dir = Path(args.output) if args.output else input_dir / "output"

    if not input_dir.exists():
        print(f"Error: Input directory does not exist: {input_dir}", file=sys.stderr)
        sys.exit(1)

    process_batch(input_dir, output_dir, target_color, args.tolerance, args.everywhere)


if __name__ == "__main__":
    main()
