#!/usr/bin/env python3
"""
Extract sprite bounding boxes from a sprite sheet with transparent background.

Usage:
    python3 tools/extract_sprites.py

Output:
    assets/images/PetMobileGameAsset/furnitures_sprites.json
    assets/images/PetMobileGameAsset/furnitures_sprites_debug.png
"""

import json
import os
from collections import deque
from PIL import Image, ImageDraw

# --- Config ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ASSET_DIR = os.path.join(PROJECT_ROOT, "assets", "images", "Assets")

INPUT_IMAGE = os.path.join(ASSET_DIR, "Furnitures,Playgrounds,Toys.png")
OUTPUT_JSON = os.path.join(ASSET_DIR, "furnitures_sprites.json")
OUTPUT_DEBUG = os.path.join(ASSET_DIR, "furnitures_sprites_debug.png")

ALPHA_THRESHOLD = 0   # pixels with alpha <= this are treated as transparent
MERGE_GAP = 0          # merge bounding boxes within this many pixels
MIN_SIZE = 4           # discard regions smaller than this in either dimension


def load_alpha_mask(path, threshold):
    """Load image and return a binary mask: True where pixel is opaque."""
    img = Image.open(path).convert("RGBA")
    alpha = img.split()[3]  # alpha channel
    width, height = img.size
    pixels = alpha.load()
    mask = [[pixels[x, y] > threshold for x in range(width)] for y in range(height)]
    return img, mask, width, height


def find_connected_components(mask, width, height):
    """BFS flood-fill to find connected regions of opaque pixels."""
    visited = [[False] * width for _ in range(height)]
    boxes = []

    for y in range(height):
        for x in range(width):
            if mask[y][x] and not visited[y][x]:
                # BFS from this pixel
                min_x, min_y = x, y
                max_x, max_y = x, y
                queue = deque([(x, y)])
                visited[y][x] = True

                while queue:
                    cx, cy = queue.popleft()
                    min_x = min(min_x, cx)
                    min_y = min(min_y, cy)
                    max_x = max(max_x, cx)
                    max_y = max(max_y, cy)

                    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1),
                                   (-1, -1), (-1, 1), (1, -1), (1, 1)]:
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < width and 0 <= ny < height:
                            if mask[ny][nx] and not visited[ny][nx]:
                                visited[ny][nx] = True
                                queue.append((nx, ny))

                boxes.append((min_x, min_y, max_x, max_y))

    return boxes


def merge_nearby_boxes(boxes, gap):
    """Merge bounding boxes that are within `gap` pixels of each other."""
    def overlaps(a, b):
        return not (a[2] + gap < b[0] or b[2] + gap < a[0] or
                    a[3] + gap < b[1] or b[3] + gap < a[1])

    def merge(a, b):
        return (min(a[0], b[0]), min(a[1], b[1]),
                max(a[2], b[2]), max(a[3], b[3]))

    merged = list(boxes)
    changed = True
    while changed:
        changed = False
        new_merged = []
        used = [False] * len(merged)
        for i in range(len(merged)):
            if used[i]:
                continue
            current = merged[i]
            for j in range(i + 1, len(merged)):
                if used[j]:
                    continue
                if overlaps(current, merged[j]):
                    current = merge(current, merged[j])
                    used[j] = True
                    changed = True
            new_merged.append(current)
        merged = new_merged

    return merged


def filter_small(boxes, min_size):
    """Remove boxes smaller than min_size in either dimension."""
    return [b for b in boxes
            if (b[2] - b[0] + 1) >= min_size and (b[3] - b[1] + 1) >= min_size]


def sort_boxes(boxes, row_band=200):
    """Sort top-to-bottom by row, same-sized sprites adjacent within each row.

    1. Bucket sprites into rows by y-center (bands of row_band pixels)
    2. Rows ordered top-to-bottom
    3. Within each row, sort by (width, height, x) so same-sized sprites cluster
    """
    if not boxes:
        return boxes

    # Sort by y-center band, then by size within each band, then by x
    def sort_key(b):
        y_center = (b[1] + b[3]) // 2
        row = y_center // row_band
        w = b[2] - b[0] + 1
        h = b[3] - b[1] + 1
        return (row, w, h, b[0])

    return sorted(boxes, key=sort_key)


def draw_debug_image(img, boxes, output_path):
    """Draw red bounding boxes on the sprite sheet and save."""
    debug = img.copy()
    draw = ImageDraw.Draw(debug)
    for i, (x1, y1, x2, y2) in enumerate(boxes):
        draw.rectangle([x1, y1, x2, y2], outline="red", width=1)
        draw.text((x1, y1 - 10), str(i), fill="red")
    debug.save(output_path)
    print(f"Debug image saved to {output_path}")


def main():
    print(f"Loading {INPUT_IMAGE}...")
    img, mask, width, height = load_alpha_mask(INPUT_IMAGE, ALPHA_THRESHOLD)
    print(f"Image size: {width}x{height}")

    print("Finding connected components...")
    boxes = find_connected_components(mask, width, height)
    print(f"Found {len(boxes)} raw regions")

    print(f"Merging nearby boxes (gap={MERGE_GAP}px)...")
    boxes = merge_nearby_boxes(boxes, MERGE_GAP)
    print(f"After merge: {len(boxes)} regions")

    print(f"Filtering small regions (<{MIN_SIZE}px)...")
    boxes = filter_small(boxes, MIN_SIZE)
    print(f"After filter: {len(boxes)} sprites")

    boxes = sort_boxes(boxes)

    # Build JSON output
    sprites = []
    for i, (x1, y1, x2, y2) in enumerate(boxes):
        sprites.append({
            "id": i,
            "x": x1,
            "y": y1,
            "width": x2 - x1 + 1,
            "height": y2 - y1 + 1,
        })

    output = {
        "source": "Furnitures,Playgrounds,Toys.png",
        "sprites": sprites,
    }

    with open(OUTPUT_JSON, "w") as f:
        json.dump(output, f, indent=2)
    print(f"JSON saved to {OUTPUT_JSON}")

    draw_debug_image(img, boxes, OUTPUT_DEBUG)
    print("Done!")


if __name__ == "__main__":
    main()
