#!/usr/bin/env python3
"""Install the original Allied Assault sniper overlay from a user's MOHAA files.

Usage: python3 tools/install_mohaa_scope.py /path/to/zoomoverlay.tga ../game
"""

import argparse
import struct
from pathlib import Path


def read_tga_rgba(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    if len(data) < 18:
        raise ValueError("TGA header is incomplete")
    id_length, color_map_type, image_type = data[:3]
    width, height, bits_per_pixel, descriptor = struct.unpack_from("<HHBB", data, 12)
    if color_map_type or image_type != 2 or bits_per_pixel != 32 or descriptor & 0x10:
        raise ValueError("expected an uncompressed, left-origin 32-bit TGA")
    if (width, height) != (256, 256):
        raise ValueError("expected the original 256x256 Allied Assault zoomoverlay.tga")

    start = 18 + id_length
    pixels = data[start : start + width * height * 4]
    if len(pixels) != width * height * 4:
        raise ValueError("TGA pixel data is incomplete")

    rgba = bytearray(len(pixels))
    for y in range(height):
        source_y = y if descriptor & 0x20 else height - 1 - y
        for x in range(width):
            src = 4 * (source_y * width + x)
            dst = 4 * (y * width + x)
            blue, green, red, alpha = pixels[src : src + 4]
            rgba[dst : dst + 4] = bytes((red, green, blue, alpha))
    return width, height, bytes(rgba)


def make_vtf(width: int, height: int, rgba: bytes) -> bytes:
    # VTF 7.1, a single RGBA8888 mip. This older header works with the game's
    # Source material loader and needs no external conversion tool.
    header = bytearray(64)
    struct.pack_into("<4sIII", header, 0, b"VTF\0", 7, 1, 64)
    struct.pack_into("<HHIHH", header, 16, width, height, 0x210C, 1, 0)
    struct.pack_into("<f", header, 48, 1.0)  # bump scale
    struct.pack_into("<IBiBB", header, 52, 0, 1, -1, 0, 0)
    return bytes(header) + rgba


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zoomoverlay_tga", type=Path)
    parser.add_argument("game_dir", type=Path)
    args = parser.parse_args()

    if not (args.game_dir / "csgo").is_dir():
        parser.error("game_dir must contain a csgo directory")

    width, height, rgba = read_tga_rgba(args.zoomoverlay_tga)
    output_dir = args.game_dir / "csgo" / "materials" / "vgui" / "hud"
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "mohaa_scope.vtf").write_bytes(make_vtf(width, height, rgba))
    (output_dir / "mohaa_scope.vmt").write_text(
        '"UnlitGeneric"\n{\n'
        '\t"$basetexture" "vgui/hud/mohaa_scope"\n'
        '\t"$translucent" "1"\n'
        '\t"$vertexcolor" "1"\n'
        '\t"$vertexalpha" "1"\n'
        '}\n'
    )
    print(f"Installed Allied Assault scope in {output_dir}")


if __name__ == "__main__":
    main()
