#!/usr/bin/env python3
"""Reproduce the geometric app icon; requires Pillow only for asset generation."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "SpelunkrTV/Resources/Assets.xcassets"
BRAND = ROOT / "App Icon & Top Shelf Image.brandassets"


def contents(path, **values):
    path.mkdir(parents=True, exist_ok=True)
    (path / "Contents.json").write_text(json.dumps({**values, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")


def artwork(size, layer):
    width, height = size
    image = Image.new("RGBA", size)
    draw = ImageDraw.Draw(image)
    if layer == "Back":
        for y in range(height):
            t = y / height
            draw.line((0, y, width, y), fill=(int(35 - 20*t), int(25 - 15*t), int(75 - 42*t), 255))
    elif layer == "Middle":
        for y in range(0, height, max(4, height // 48)):
            draw.line((0, y, width, y), fill=(125, 100, 195, 22), width=1)
    else:
        side = height * 0.66
        x = (width - side) / 2
        y = (height - side) / 2
        stroke = max(2, round(height * 0.025))
        draw.rounded_rectangle((x, y, x+side, y+side), radius=side*0.16, outline=(230, 242, 129), width=stroke)
        left, right = x + side*0.26, x + side*0.75
        top, bottom = y + side*0.25, y + side*0.75
        points = [(right, top), (left, top), (left, y+side*0.5), (right, y+side*0.5), (right, bottom), (left, bottom)]
        draw.line(points, fill=(230, 242, 129), width=round(side*0.12), joint="curve")
    return image


def stack(name, sizes):
    destination = BRAND / name
    layers = ["Front", "Middle", "Back"]
    contents(destination, layers=[{"filename": f"{layer}.imagestacklayer"} for layer in layers])
    for layer in layers:
        layer_path = destination / f"{layer}.imagestacklayer"
        contents(layer_path)
        image_path = layer_path / "Content.imageset"
        images = []
        for scale, size in sizes:
            filename = f"{layer}-{scale}.png"
            image_path.mkdir(parents=True, exist_ok=True)
            artwork(size, layer).save(image_path / filename)
            images.append({"filename": filename, "idiom": "tv", "scale": scale})
        contents(image_path, images=images)


def shelf(name, width):
    top_shelf = BRAND / name
    top_shelf.mkdir(parents=True, exist_ok=True)
    images = []
    for factor in (1, 2):
        scale = f"{factor}x"
        size = (width * factor, 720 * factor)
        result = artwork(size, "Back")
        for layer in ["Middle", "Front"]:
            result = Image.alpha_composite(result, artwork(size, layer))
        filename = f"top-shelf-{scale}.png"
        result.convert("RGB").save(top_shelf / filename)
        images.append({"filename": filename, "idiom": "tv", "scale": scale})
    contents(top_shelf, images=images)


def main():
    shelves = [("Top Shelf.imageset", "top-shelf-image", 1920),
               ("Top Shelf Wide.imageset", "top-shelf-image-wide", 2320)]
    contents(ROOT)
    contents(BRAND, assets=[
        {"filename": "App Icon.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "400x240"},
        {"filename": "App Store Icon.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "1280x768"},
        *({"filename": name, "idiom": "tv", "role": role, "size": f"{width}x720"} for name, role, width in shelves),
    ])
    stack("App Icon.imagestack", [("1x", (400, 240)), ("2x", (800, 480))])
    stack("App Store Icon.imagestack", [("1x", (1280, 768))])
    for name, _, width in shelves:
        shelf(name, width)


if __name__ == "__main__":
    main()
