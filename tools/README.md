# Tools

---

# Background Remover Tool

Batch removes a specific background color from images using flood-fill from the edges.
Only removes the outer background — preserves the central subject and any matching color inside it.

## Setup

```bash
cd tools

python3 -m venv .venv
.venv/bin/pip install --upgrade pip setuptools
.venv/bin/pip install -r requirements.txt
```

## Usage

1. Place your images in `images-to-remove-background/`
2. Run the script
3. Find results in `images-to-remove-background/output/`

### Remove white background (default)

```bash
.venv/bin/python3 remove_background.py
```

### Remove a specific color by name

```bash
.venv/bin/python3 remove_background.py --color blue
.venv/bin/python3 remove_background.py --color green
.venv/bin/python3 remove_background.py --color black
```

### Remove a specific color by hex

```bash
.venv/bin/python3 remove_background.py --color "#F0F0F0"
.venv/bin/python3 remove_background.py --color "#87CEEB"
```

### Adjust tolerance

Lower = stricter matching, higher = more aggressive removal.

```bash
.venv/bin/python3 remove_background.py --color white --tolerance 15
.venv/bin/python3 remove_background.py --color white --tolerance 50
```

### Remove color everywhere (not just outer background)

By default, only the outer background is removed (flood-fill from edges).
Use `--everywhere` to remove the color from the entire image, including inside the subject.

```bash
.venv/bin/python3 remove_background.py --color white --everywhere
.venv/bin/python3 remove_background.py --color white --everywhere --tolerance 20
```

### Custom input/output directories

```bash
.venv/bin/python3 remove_background.py --input /path/to/images --output /path/to/results
```

## How it works

1. Scans all edges of the image for pixels matching the target color (within tolerance)
2. Flood-fills inward from those edge pixels, marking connected matching pixels as background
3. Sets all background pixels to transparent
4. Saves as PNG (to preserve transparency)

Original images are never modified. Output is always a new file in the output directory.

## Supported formats

Input: PNG, JPG, JPEG, BMP, WebP, TIFF

Output: always PNG (transparency requires it)

---

# Autocrop Tool

Batch crops images by removing the outer empty space around the image core.
Detects content boundaries automatically — using alpha transparency if present, or by sampling the background color from the corners — then cuts only the exterior boundaries, leaving the core intact.

## Usage

1. Place your images in `images-to-cut/`
2. Run the script
3. Find results in `images-to-cut/output/`

### Autocrop with auto-detection (default)

```bash
.venv/bin/python3 autocrop.py
```

### Keep a padding margin around the core

```bash
.venv/bin/python3 autocrop.py --padding 5
.venv/bin/python3 autocrop.py --padding 10
```

### Force a specific background color to crop against

```bash
.venv/bin/python3 autocrop.py --color white
.venv/bin/python3 autocrop.py --color "#F0F0F0"
```

### Adjust color tolerance

Lower = stricter match, higher = more aggressive crop.

```bash
.venv/bin/python3 autocrop.py --color white --tolerance 15
.venv/bin/python3 autocrop.py --color white --tolerance 50
```

### Adjust alpha threshold (for images with transparency)

Pixels with alpha below this value are treated as transparent (and cropped).

```bash
.venv/bin/python3 autocrop.py --alpha-threshold 25
```

### Custom input/output directories

```bash
.venv/bin/python3 autocrop.py --input /path/to/images --output /path/to/results
```

## How it works

1. If the image has an alpha channel with meaningful transparency → finds the bounding box of non-transparent pixels
2. Otherwise → samples the four corners to detect the background color, then finds the bounding box of pixels that differ from it
3. `--color` overrides auto-detection and forces a specific background color
4. Crops to the detected bounding box, with optional padding
5. Saves as PNG

Original images are never modified. Output is always a new file in the output directory.

## Supported formats

Input: PNG, JPG, JPEG, BMP, WebP, TIFF

Output: always PNG
