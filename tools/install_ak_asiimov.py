#!/usr/bin/env python3
"""Install an AK-47 Asiimov VTF from legally acquired CS:GO content.

Usage: python3 tools/install_ak_asiimov.py /path/to/ak47_asiimov.vtf ../game
"""

import argparse
import shutil
from pathlib import Path


KIT = '''\t"paint_kits"
\t{
\t\t"801"
\t\t{
\t\t\t"name" "cu_ak47_asiimov"
\t\t\t"description_string" "#PaintKit_cu_ak47_asiimov"
\t\t\t"description_tag" "#PaintKit_cu_ak47_asiimov_Tag"
\t\t\t"style" "7"
\t\t\t"pattern" "workshop/ak47_asiimov"
\t\t\t"pattern_scale" "1.000000"
\t\t\t"phongexponent" "200"
\t\t\t"phongintensity" "255"
\t\t\t"ignore_weapon_size_scale" "1"
\t\t\t"only_first_material" "0"
\t\t\t"pattern_offset_x_start" "0.000000"
\t\t\t"pattern_offset_x_end" "0.000000"
\t\t\t"pattern_offset_y_start" "0.000000"
\t\t\t"pattern_offset_y_end" "0.000000"
\t\t\t"pattern_rotate_start" "0.000000"
\t\t\t"pattern_rotate_end" "0.000000"
\t\t\t"wear_remap_min" "0.050000"
\t\t\t"wear_remap_max" "0.700000"
\t\t}
\t}
'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ak47_asiimov_vtf", type=Path)
    parser.add_argument("game_dir", type=Path)
    args = parser.parse_args()

    if not (args.game_dir / "csgo").is_dir():
        parser.error("game_dir must contain a csgo directory")
    if args.ak47_asiimov_vtf.read_bytes()[:4] != b"VTF\0":
        parser.error("expected a Valve Texture Format file")

    csgo = args.game_dir / "csgo"
    texture = csgo / "materials/models/weapons/customization/paints/custom/workshop/ak47_asiimov.vtf"
    texture.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(args.ak47_asiimov_vtf, texture)

    schema = csgo / "scripts/items/items_game.txt"
    data = schema.read_bytes()
    if b'"name"\t\t"cu_ak47_asiimov"' not in data and b'"name" "cu_ak47_asiimov"' not in data:
        newline = b"\r\n" if b"\r\n" in data else b"\n"
        if not data.rstrip().endswith(b"}"):
            parser.error("items_game.txt does not end with a closing brace")
        closing = data.rfind(b"}")
        entry = KIT.replace("\n", newline.decode()).encode()
        schema.write_bytes(data[:closing] + entry + data[closing:])
    print(f"Installed AK-47 Asiimov in {csgo}")


if __name__ == "__main__":
    main()
