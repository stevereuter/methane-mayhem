#!/usr/bin/env python3
"""Build configured binary PRG assets and add them to a D64 image."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROLE_PRIORITY = {
    "background": 0,
    "shared1": 1,
    "shared2": 2,
    "multicolor": 3,
    "standard": 4,
    "character": 4,
    "regular": 5,
    "hires": 6,
    "hi-res": 6,
}


def canonical_role(role: str) -> str:
    normalized = role.strip().lower()
    if normalized in {"regular", "character"}:
        return "character"
    if normalized == "standard":
        return "standard"
    if normalized == "hi-res":
        return "hires"
    return normalized


def fail(message: str) -> None:
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)


def parse_load_address(value: object) -> int:
    if isinstance(value, int):
        addr = value
    elif isinstance(value, str):
        cleaned = value.strip()

        # Supports "00 C0" (little-endian bytes), "0xC000", and "C000".
        parts = cleaned.split()
        if len(parts) == 2:
            low = int(parts[0], 16)
            high = int(parts[1], 16)
            addr = (high << 8) | low
        elif cleaned.lower().startswith("0x"):
            addr = int(cleaned, 16)
        else:
            addr = int(cleaned, 16)
    else:
        fail(f"Unsupported loadAddress type: {type(value).__name__}")

    if addr < 0 or addr > 0xFFFF:
        fail(f"loadAddress out of range: {addr}")
    return addr


def resolve_d64_path(config: dict[str, Any], repo_root: Path, build_dir: Path) -> Path:
    configured_path = config.get("d64Path") or config.get("diskImagePath") or config.get("d64Image")
    if configured_path:
        d64_path = Path(str(configured_path))
        if not d64_path.is_absolute():
            d64_path = repo_root / d64_path
        if not d64_path.exists():
            fail(f"Configured D64 image not found: {d64_path}")
        return d64_path

    candidates = sorted(build_dir.glob("*.d64"))
    if len(candidates) == 1:
        return candidates[0]
    if not candidates:
        fail(
            "No D64 image found in build directory. Set config.json d64Path or create a .d64 in "
            f"{build_dir}"
        )

    listed = ", ".join(str(path.name) for path in candidates)
    fail(
        "Multiple D64 images found in build directory. Set config.json d64Path to disambiguate. "
        f"Candidates: {listed}"
    )


def normalize_hex(value: str) -> str:
    cleaned = value.strip().upper()
    if not cleaned.startswith("#"):
        cleaned = "#" + cleaned
    if len(cleaned) == 7:
        cleaned = cleaned + "FF"
    if len(cleaned) != 9:
        fail(f"Invalid hex color '{value}'. Expected #RRGGBB or #RRGGBBAA")
    return cleaned


def parse_basic_data_bytes(source_file: Path) -> bytes:
    text = source_file.read_text(encoding="utf-8", errors="replace")
    out = bytearray()

    for line_no, line in enumerate(text.splitlines(), start=1):
        # Remove BASIC line number prefix and comments.
        line = re.sub(r"^\s*\d+\s*", "", line)
        line = line.split("rem", 1)[0]
        line = line.split("REM", 1)[0]

        if "data" not in line.lower():
            continue

        match = re.search(r"\bdata\b(.*)$", line, flags=re.IGNORECASE)
        if not match:
            continue

        payload = match.group(1)
        if payload.strip() == "":
            continue

        for token in payload.split(","):
            value = token.strip()
            if value == "":
                continue

            try:
                number = int(value)
            except ValueError:
                fail(f"Invalid DATA value '{value}' in {source_file} line {line_no}")

            if number < 0 or number > 255:
                fail(f"DATA value out of byte range '{number}' in {source_file} line {line_no}")

            out.append(number)

    if not out:
        fail(f"No DATA bytes found in {source_file}")

    return bytes(out)


def parse_color_map(config: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    entries = config.get("asepriteColorMap", [])
    if not isinstance(entries, list):
        fail("config.json field 'asepriteColorMap' must be an array")

    by_hex: dict[str, list[dict[str, Any]]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            fail("Each asepriteColorMap entry must be an object")

        raw_hex = entry.get("hex")
        c64_index = entry.get("c64Index")
        role = str(entry.get("role", "")).strip().lower()
        if not raw_hex:
            fail("asepriteColorMap entry missing 'hex'")
        if c64_index is None:
            fail(f"asepriteColorMap entry '{raw_hex}' missing 'c64Index'")
        if role not in {
            "background",
            "shared1",
            "shared2",
            "character",
            "regular",
            "multicolor",
            "hi-res",
            "hires",
            "standard",
        }:
            fail(
                f"asepriteColorMap entry '{raw_hex}' has invalid role '{entry.get('role')}'. "
                "Expected one of: background, shared1, shared2, multicolor, hi-res, standard"
            )

        try:
            c64_val = int(c64_index)
        except (TypeError, ValueError):
            fail(f"asepriteColorMap entry '{raw_hex}' has invalid c64Index '{c64_index}'")
        if c64_val < 0 or c64_val > 15:
            fail(f"asepriteColorMap entry '{raw_hex}' c64Index out of range 0-15: {c64_val}")

        key = normalize_hex(str(raw_hex))
        by_hex.setdefault(key, []).append({"hex": key, "c64Index": c64_val, "role": role})

    return by_hex


def pick_preferred_rule(rules: list[dict[str, Any]]) -> dict[str, Any]:
    return sorted(rules, key=lambda rule: ROLE_PRIORITY.get(str(rule["role"]), 999))[0]


def build_multicolor_slot_indexes(by_hex: dict[str, list[dict[str, Any]]]) -> dict[str, int]:
    slots: dict[str, int] = {}
    for rules in by_hex.values():
        for rule in rules:
            role = str(rule.get("role", "")).strip().lower()
            if role in {"background", "shared1", "shared2"} and role not in slots:
                slots[role] = int(rule["c64Index"])
    return slots


def resolve_rule_for_hex(
    hex_key: str, by_hex: dict[str, list[dict[str, Any]]], multicolor_slots: dict[str, int]
) -> dict[str, Any]:
    rules = by_hex.get(hex_key)
    if not rules:
        fail(f"No asepriteColorMap mapping for colorReference hex {hex_key}")

    explicit = [rule for rule in rules if str(rule["role"]).strip().lower() in {"background", "shared1", "shared2"}]
    if explicit:
        chosen = pick_preferred_rule(explicit)
        return {"hex": hex_key, "c64Index": int(chosen["c64Index"]), "role": canonical_role(str(chosen["role"]))}

    usable = [
        rule
        for rule in rules
        if canonical_role(str(rule.get("role", ""))) in {"multicolor", "hires", "character"}
    ]
    if not usable:
        fail(
            f"Color {hex_key} is mapped only to ignored role(s) (such as 'standard'). "
            "Provide at least one of: multicolor, hi-res, shared1/shared2/background."
        )

    preferred = pick_preferred_rule(usable)

    # multicolor role = per-cell character color (11 bits); does not need to match a shared slot.
    return {
        "hex": hex_key,
        "c64Index": int(preferred["c64Index"]),
        "role": canonical_role(str(preferred["role"])),
    }


def build_raw_to_color_rule(
    screen_json: dict[str, Any], by_hex: dict[str, list[dict[str, Any]]]
) -> dict[int, dict[str, Any]]:
    color_ref = screen_json.get("colorReference")
    if not isinstance(color_ref, dict):
        fail("Screen JSON is missing 'colorReference' object")

    entries = color_ref.get("entries", [])
    if not isinstance(entries, list):
        fail("Screen JSON field 'colorReference.entries' must be an array")

    multicolor_slots = build_multicolor_slot_indexes(by_hex)
    raw_to_rule: dict[int, dict[str, Any]] = {}
    for entry in entries:
        if not isinstance(entry, dict):
            fail("Each colorReference entry must be an object")
        raw_value = entry.get("rawValue")
        raw_hex = entry.get("hex")
        if raw_value is None or raw_hex is None:
            fail("colorReference entry requires both 'rawValue' and 'hex'")

        try:
            raw_key = int(raw_value)
        except (TypeError, ValueError):
            fail(f"Invalid rawValue in colorReference: {raw_value}")

        hex_key = normalize_hex(str(raw_hex))
        resolved = resolve_rule_for_hex(hex_key, by_hex, multicolor_slots)

        # Flag whether this color also has a hi-res mapping in the config.
        # Used for single-color hires character detection.
        candidates = by_hex.get(hex_key, [])
        if any(canonical_role(str(c.get("role", ""))) == "hires" for c in candidates):
            resolved["hasHiresMapping"] = True
        if any(canonical_role(str(c.get("role", ""))) == "multicolor" for c in candidates):
            resolved["hasMulticolorMapping"] = True

        raw_to_rule[raw_key] = resolved

    return raw_to_rule


def generate_screen_map_bytes(screen_json: dict[str, Any]) -> bytes:
    cells = screen_json.get("cells", [])
    if not isinstance(cells, list):
        fail("Screen JSON field 'cells' must be an array")

    out = bytearray()
    for i, value in enumerate(cells):
        try:
            byte_val = int(value)
        except (TypeError, ValueError):
            fail(f"Screen cell #{i} is not an integer: {value}")
        if byte_val < 0 or byte_val > 255:
            fail(f"Screen cell #{i} out of byte range 0-255: {byte_val}")
        out.append(byte_val)
    return bytes(out)


def generate_character_bytes(screen_json: dict[str, Any], raw_to_rule: dict[int, dict[str, Any]]) -> bytes:
    tiles_obj = screen_json.get("tiles")
    if not isinstance(tiles_obj, dict):
        fail("Screen JSON is missing 'tiles' object")
    tiles = tiles_obj.get("tiles", [])
    if not isinstance(tiles, list):
        fail("Screen JSON field 'tiles.tiles' must be an array")

    role_to_bits = {
        "background": 0b00,
        "shared1": 0b01,
        "shared2": 0b10,
        "character": 0b11,
    }

    out = bytearray()
    for tile in tiles:
        if not isinstance(tile, dict):
            fail("Each tile entry must be an object")
        tile_index = tile.get("tileIndex", "?")
        rows = tile.get("rows", [])
        if not isinstance(rows, list):
            fail(f"Tile {tile_index} rows must be an array")
        if len(rows) != 8:
            fail(f"Tile {tile_index} must contain 8 rows, found {len(rows)}")

        for row_idx, row in enumerate(rows):
            if not isinstance(row, list):
                fail(f"Tile {tile_index} row {row_idx} must be an array")
            if len(row) != 4:
                fail(f"Tile {tile_index} row {row_idx} must contain 4 logical pixels")

            packed = 0
            for col_idx, raw_value in enumerate(row):
                try:
                    raw_key = int(raw_value)
                except (TypeError, ValueError):
                    fail(f"Tile {tile_index} row {row_idx} col {col_idx} invalid raw value: {raw_value}")

                rule = raw_to_rule.get(raw_key)
                if not rule:
                    fail(
                        f"Tile {tile_index} row {row_idx} col {col_idx} raw value {raw_key} "
                        "has no asepriteColorMap mapping"
                    )

                bits = role_to_bits[rule["role"]]
                packed |= bits << (6 - (col_idx * 2))

            out.append(packed)

    return bytes(out)


def generate_mixed_charset_bytes(source_json: dict[str, Any], raw_to_rule: dict[int, dict[str, Any]]) -> bytes:
    chars = source_json.get("characters")
    if not isinstance(chars, list):
        fail("Mixed charset JSON field 'characters' must be an array")
    if len(chars) < 256:
        fail(f"Mixed charset JSON must contain at least 256 characters, found {len(chars)}")

    role_to_bits = {
        "background": 0b00,
        "shared1": 0b01,
        "shared2": 0b10,
        "multicolor": 0b11,
    }

    out = bytearray()
    for char_index in range(256):
        char_entry = chars[char_index]
        if not isinstance(char_entry, dict):
            fail(f"Character {char_index} entry must be an object")

        pair_rows = char_entry.get("rowPairs")
        if not isinstance(pair_rows, list) or len(pair_rows) != 8:
            fail(f"Character {char_index} field 'rowPairs' must contain 8 rows")

        row_bytes_hires = char_entry.get("rowBytesHiRes")
        if not isinstance(row_bytes_hires, list) or len(row_bytes_hires) != 8:
            fail(f"Character {char_index} field 'rowBytesHiRes' must contain 8 bytes")

        # Determine used non-background colors/roles for this character.
        non_bg_raw_values: set[int] = set()
        for pair_row in pair_rows:
            if not isinstance(pair_row, list):
                continue
            for pair_info in pair_row:
                if not isinstance(pair_info, dict):
                    continue
                for side in ("left", "right"):
                    raw_side = pair_info.get(side)
                    if raw_side is None:
                        continue
                    try:
                        raw_key = int(raw_side)
                    except (TypeError, ValueError):
                        continue
                    rule = raw_to_rule.get(raw_key)
                    if rule and str(rule.get("role")) != "background":
                        non_bg_raw_values.add(raw_key)

        # Empty character: emit 8x8 row bytes.
        if not non_bg_raw_values:
            for row_idx, byte_val in enumerate(row_bytes_hires):
                try:
                    value = int(byte_val)
                except (TypeError, ValueError):
                    fail(f"Character {char_index} rowBytesHiRes[{row_idx}] is not an integer: {byte_val}")
                if value < 0 or value > 255:
                    fail(f"Character {char_index} rowBytesHiRes[{row_idx}] out of byte range: {value}")
                out.append(value)
            continue

        non_bg_roles = {str(raw_to_rule[rv]["role"]) for rv in non_bg_raw_values}

        # Rule 1: exactly one non-background color.
        # - multicolor -> emit 8x8 bytes.
        # - shared1/shared2 -> emit 4x8 pair-encoded bytes.
        if len(non_bg_raw_values) == 1:
            only_raw = next(iter(non_bg_raw_values))
            only_rule = raw_to_rule[only_raw]
            only_role = str(only_rule.get("role"))

            # If the color has both shared and multicolor mappings, prefer
            # multicolor for single-color characters (8x8 path).
            if bool(only_rule.get("hasMulticolorMapping")):
                for row_idx, byte_val in enumerate(row_bytes_hires):
                    try:
                        value = int(byte_val)
                    except (TypeError, ValueError):
                        fail(f"Character {char_index} rowBytesHiRes[{row_idx}] is not an integer: {byte_val}")
                    if value < 0 or value > 255:
                        fail(f"Character {char_index} rowBytesHiRes[{row_idx}] out of byte range: {value}")
                    out.append(value)
                continue

            if only_role == "multicolor":
                for row_idx, byte_val in enumerate(row_bytes_hires):
                    try:
                        value = int(byte_val)
                    except (TypeError, ValueError):
                        fail(f"Character {char_index} rowBytesHiRes[{row_idx}] is not an integer: {byte_val}")
                    if value < 0 or value > 255:
                        fail(f"Character {char_index} rowBytesHiRes[{row_idx}] out of byte range: {value}")
                    out.append(value)
                continue

            if only_role in {"shared1", "shared2"}:
                for row_idx, pair_row in enumerate(pair_rows):
                    if not isinstance(pair_row, list) or len(pair_row) != 4:
                        fail(f"Character {char_index} rowPairs row {row_idx} must contain 4 pairs")

                    packed = 0
                    for pair_idx, pair_info in enumerate(pair_row):
                        if not isinstance(pair_info, dict):
                            fail(f"Character {char_index} row {row_idx} pair {pair_idx} must be an object")

                        left_raw = pair_info.get("left")
                        right_raw = pair_info.get("right")
                        if left_raw is None or right_raw is None:
                            fail(f"Character {char_index} row {row_idx} pair {pair_idx} missing left/right values")

                        try:
                            left_key = int(left_raw)
                            right_key = int(right_raw)
                        except (TypeError, ValueError):
                            fail(
                                f"Character {char_index} row {row_idx} pair {pair_idx} has non-integer color values"
                            )

                        left_rule = raw_to_rule.get(left_key)
                        right_rule = raw_to_rule.get(right_key)
                        if not left_rule:
                            fail(
                                f"Character {char_index} row {row_idx} pair {pair_idx} left color {left_key} "
                                "has no asepriteColorMap mapping"
                            )
                        if not right_rule:
                            fail(
                                f"Character {char_index} row {row_idx} pair {pair_idx} right color {right_key} "
                                "has no asepriteColorMap mapping"
                            )

                        left_role = str(left_rule.get("role"))
                        right_role = str(right_rule.get("role"))
                        if left_role != right_role:
                            fail(
                                f"Character {char_index} row {row_idx} pair {pair_idx} has mismatched roles "
                                f"{left_role}/{right_role}. Each 2-pixel pair must use the same role."
                            )

                        bits = role_to_bits.get(left_role)
                        if bits is None:
                            fail(
                                f"Character {char_index} row {row_idx} pair {pair_idx} unsupported role '{left_role}'"
                            )

                        packed |= bits << (6 - (pair_idx * 2))

                    out.append(packed)
                continue

            fail(
                f"Character {char_index} has a single color {only_rule.get('hex')} with role '{only_role}'. "
                "Single-color characters must be either role 'multicolor' (8x8) or shared1/shared2 (4x8)."
            )

        # Rule 2: multi-color characters may only contain multicolor/shared roles.
        invalid_roles = sorted(role for role in non_bg_roles if role not in {"multicolor", "shared1", "shared2"})
        if invalid_roles:
            fail(
                f"Character {char_index} uses unsupported role(s) {invalid_roles} for a multi-color character. "
                "Multi-color characters can only contain: multicolor, shared1, shared2."
            )

        multicolor_raw_values = [rv for rv in non_bg_raw_values if str(raw_to_rule[rv]["role"]) == "multicolor"]
        if len(multicolor_raw_values) > 1:
            fail(
                f"Character {char_index} has {len(multicolor_raw_values)} distinct multicolor color(s). "
                "Multi-color characters can contain at most 1 multicolor color."
            )

        if "shared1" not in non_bg_roles and "shared2" not in non_bg_roles:
            fail(
                f"Character {char_index} is multi-color but roles present are {sorted(non_bg_roles)}. "
                "Multi-color characters must include shared1 or shared2."
            )

        # Multicolor character: encode as 2-bit pairs.
        for row_idx, pair_row in enumerate(pair_rows):
            if not isinstance(pair_row, list) or len(pair_row) != 4:
                fail(f"Character {char_index} rowPairs row {row_idx} must contain 4 pairs")

            packed = 0
            for pair_idx, pair_info in enumerate(pair_row):
                if not isinstance(pair_info, dict):
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} must be an object")

                left_raw = pair_info.get("left")
                right_raw = pair_info.get("right")
                if left_raw is None or right_raw is None:
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} missing left/right values")

                try:
                    left_key = int(left_raw)
                    right_key = int(right_raw)
                except (TypeError, ValueError):
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} has non-integer color values")

                left_rule = raw_to_rule.get(left_key)
                right_rule = raw_to_rule.get(right_key)
                if not left_rule:
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} left color {left_key} has no asepriteColorMap mapping")
                if not right_rule:
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} right color {right_key} has no asepriteColorMap mapping")

                left_role = str(left_rule["role"])
                right_role = str(right_rule["role"])

                if left_role != right_role:
                    fail(
                        f"Character {char_index} row {row_idx} pair {pair_idx} has mismatched roles "
                        f"{left_role}/{right_role}. Each 2-pixel pair must use the same role."
                    )

                bits = role_to_bits.get(left_role)
                if bits is None:
                    fail(f"Character {char_index} row {row_idx} pair {pair_idx} unsupported role '{left_role}'")

                packed |= bits << (6 - (pair_idx * 2))

            out.append(packed)

    return bytes(out)


def build_tile_character_colors(screen_json: dict[str, Any], raw_to_rule: dict[int, dict[str, Any]]) -> list[int]:
    tiles_obj = screen_json.get("tiles")
    if not isinstance(tiles_obj, dict):
        fail("Screen JSON is missing 'tiles' object")
    tiles = tiles_obj.get("tiles", [])
    if not isinstance(tiles, list):
        fail("Screen JSON field 'tiles.tiles' must be an array")

    tile_char_colors: list[int] = []
    for tile in tiles:
        if not isinstance(tile, dict):
            fail("Each tile entry must be an object")

        tile_index = tile.get("tileIndex", "?")
        rows = tile.get("rows", [])
        if not isinstance(rows, list):
            fail(f"Tile {tile_index} rows must be an array")

        char_colors: set[int] = set()
        for row in rows:
            if not isinstance(row, list):
                fail(f"Tile {tile_index} row must be an array")
            for raw_value in row:
                try:
                    raw_key = int(raw_value)
                except (TypeError, ValueError):
                    fail(f"Tile {tile_index} contains invalid raw value: {raw_value}")

                rule = raw_to_rule.get(raw_key)
                if not rule:
                    fail(f"Tile {tile_index} raw value {raw_key} has no asepriteColorMap mapping")
                if rule["role"] == "character":
                    try:
                        char_index = int(rule["c64Index"])
                    except (TypeError, ValueError):
                        fail(f"Tile {tile_index} has invalid character c64Index '{rule['c64Index']}'")

                    # Accept character colors as either logical 0-7 or direct color RAM 8-15.
                    if 0 <= char_index <= 7:
                        char_colors.add(char_index + 8)
                    elif 8 <= char_index <= 15:
                        char_colors.add(char_index)
                    else:
                        fail(
                            f"Tile {tile_index} character color index out of range 0-15: {char_index}"
                        )

        if len(char_colors) > 1:
            fail(
                f"Tile {tile_index} contains multiple character colors {sorted(char_colors)}. "
                "Each tile must resolve to a single character color."
            )

        # Background-only tiles can use multicolor color RAM value 8 (color code 0 + multicolor flag).
        color_val = next(iter(char_colors)) if char_colors else 8
        if color_val < 8 or color_val > 15:
            fail(
                f"Tile {tile_index} character color must be in 8-15 for C64 multicolor text chars, "
                f"got {color_val}"
            )
        tile_char_colors.append(color_val)

    return tile_char_colors


def generate_color_ram_bytes(screen_json: dict[str, Any], raw_to_rule: dict[int, dict[str, Any]]) -> bytes:
    cells = screen_json.get("cells", [])
    if not isinstance(cells, list):
        fail("Screen JSON field 'cells' must be an array")

    tile_char_colors = build_tile_character_colors(screen_json, raw_to_rule)
    out = bytearray()
    for i, cell in enumerate(cells):
        try:
            tile_index = int(cell)
        except (TypeError, ValueError):
            fail(f"Screen cell #{i} is not an integer: {cell}")

        if tile_index < 0 or tile_index >= len(tile_char_colors):
            fail(
                f"Screen cell #{i} references tile index {tile_index}, "
                f"but only {len(tile_char_colors)} tiles are available"
            )

        out.append(tile_char_colors[tile_index])

    return bytes(out)


def generate_asset_bytes(
    entry: dict[str, Any], repo_root: Path, by_hex: dict[str, list[dict[str, Any]]], json_cache: dict[Path, dict[str, Any]]
) -> bytes:
    asset_type = str(entry.get("type") or "raw-bin").strip().lower()
    path = entry.get("path")
    if not path:
        fail("binaries entry is missing 'path'")

    source_file = repo_root / str(path)
    if not source_file.exists() and asset_type in {"json", "mixed-charset-source", "mixed-charset"}:
        alt = source_file.with_suffix(".json")
        if alt.exists():
            source_file = alt
    if not source_file.exists():
        fail(f"Source file not found: {source_file}")

    if asset_type == "raw-bin":
        if source_file.suffix.lower() == ".bas":
            return parse_basic_data_bytes(source_file)
        return source_file.read_bytes()

    if asset_type not in {"screen-map", "screen-chars", "screen-colors", "json", "mixed-charset-source", "mixed-charset"}:
        fail(f"Unsupported binaries entry type '{asset_type}' for path {path}")

    screen_json = json_cache.get(source_file)
    if screen_json is None:
        with source_file.open("r", encoding="utf-8") as handle:
            screen_json = json.load(handle)
        json_cache[source_file] = screen_json

    raw_to_rule = build_raw_to_color_rule(screen_json, by_hex)

    if asset_type in {"json", "mixed-charset-source", "mixed-charset"}:
        return generate_mixed_charset_bytes(screen_json, raw_to_rule)

    if asset_type == "screen-map":
        return generate_screen_map_bytes(screen_json)
    if asset_type == "screen-chars":
        return generate_character_bytes(screen_json, raw_to_rule)

    return generate_color_ram_bytes(screen_json, raw_to_rule)


def main() -> None:
    repo_root = Path(__file__).resolve().parents[2]
    c64_root = repo_root / "c64"
    build_dir = c64_root / "build"
    config_path = repo_root / "config.json"

    if not config_path.exists():
        fail(f"Missing config file: {config_path}")

    with config_path.open("r", encoding="utf-8") as handle:
        config = json.load(handle)

    d64_path = resolve_d64_path(config, repo_root, build_dir)

    binaries = config.get("binaries", [])
    if not isinstance(binaries, list):
        fail("config.json field 'binaries' must be an array")
    if not binaries:
        print("No configured binaries found; nothing to add.")
        return

    by_hex = parse_color_map(config)
    json_cache: dict[Path, dict[str, Any]] = {}

    build_dir.mkdir(parents=True, exist_ok=True)

    for entry in binaries:
        if not isinstance(entry, dict):
            fail("Each binaries entry must be an object")

        if entry.get("enabled", True) is False:
            print(f"Skipping disabled entry: {entry.get('name', entry.get('path', '<unknown>'))}")
            continue

        load_address = entry.get("loadAddress")
        disk_name = entry.get("discName") or entry.get("diskName")

        if load_address is None:
            fail(f"binaries entry '{entry.get('path')}' is missing 'loadAddress'")
        if not disk_name:
            fail(f"binaries entry '{entry.get('path')}' is missing 'discName' or 'diskName'")

        data = generate_asset_bytes(entry, repo_root, by_hex, json_cache)
        addr = parse_load_address(load_address)
        prg_name = f"{str(disk_name).lower()}.prg"
        prg_path = build_dir / prg_name

        # PRG payload starts with little-endian load address.
        prg_path.write_bytes(bytes((addr & 0xFF, (addr >> 8) & 0xFF)) + data)

        cmd = [
            "c1541",
            str(d64_path),
            "-delete",
            str(disk_name),
            "-write",
            str(prg_path),
            str(disk_name),
        ]

        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError:
            # File might not exist yet; retry without delete.
            write_cmd = [
                "c1541",
                str(d64_path),
                "-write",
                str(prg_path),
                str(disk_name),
            ]
            subprocess.run(write_cmd, check=True)

        print(
            f"Added {entry.get('path')} ({entry.get('type', 'raw-bin')}) -> "
            f"{prg_path.name} @ ${addr:04X} as '{disk_name}'"
        )


if __name__ == "__main__":
    main()
