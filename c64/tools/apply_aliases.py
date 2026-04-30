#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: apply_aliases.py <generated-dir>", file=sys.stderr)
        return 1

    generated_dir = Path(sys.argv[1])
    if not generated_dir.exists():
        print(f"Generated dir not found: {generated_dir}", file=sys.stderr)
        return 1

    generated_files = sorted(generated_dir.glob("*.generated.bas"))
    if not generated_files:
        print("No generated BASIC files found for alias processing.")
        return 0

    declaration_pattern = re.compile(
        r"@([a-z][A-Za-z0-9]*[$%]?)(?=\s*(?:=|\())"
    )
    declaration_order: list[str] = []
    declaration_locations: dict[str, str] = {}
    label_locations: dict[str, str] = {}

    for file_path in generated_files:
        lines = file_path.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, 1):
            label = extract_label_name(line)
            if label:
                label_key = label.lower()
                if label_key not in label_locations:
                    label_locations[label_key] = f"{file_path.name}:{idx}"

            for m in declaration_pattern.finditer(line):
                alias = m.group(1)
                loc = f"{file_path.name}:{idx}"
                existing = declaration_locations.get(alias)

                if existing and existing != loc:
                    print(
                        f"Duplicate alias declaration '{alias}' at {loc}; first seen at {existing}",
                        file=sys.stderr,
                    )
                    return 1

                if not existing:
                    alias_key = alias.rstrip("$%").lower()
                    label_loc = label_locations.get(alias_key)
                    if label_loc:
                        print(
                            f"Alias '{alias}' at {loc} collides with label '{alias_key}:' at {label_loc}",
                            file=sys.stderr,
                        )
                        return 1

                    declaration_locations[alias] = loc
                    declaration_order.append(alias)

    if not declaration_order:
        print("No alias declarations found.")
        return 0

    reserved_roots: set[str] = set()
    for file_path in generated_files:
        lines = file_path.read_text(encoding="utf-8").splitlines()
        for line in lines:
            for token in tokenize_line(line):
                name = token[1:] if token.startswith("@") else token
                root = variable_root(name)
                if len(root) == 2:
                    reserved_roots.add(root)

    alias_map: dict[str, str] = {}
    pool = build_root_pool()

    for alias in declaration_order:
        assigned_root = None
        for root in pool:
            if root not in reserved_roots:
                assigned_root = root
                reserved_roots.add(root)
                break

        if not assigned_root:
            print(
                f"Could not allocate short variable root for alias '{alias}'",
                file=sys.stderr,
            )
            return 1

        suffix = alias[-1] if alias.endswith("$") or alias.endswith("%") else ""
        alias_map[alias] = f"{assigned_root}{suffix}"

    for file_path in generated_files:
        lines = file_path.read_text(encoding="utf-8").splitlines()
        out_lines = [replace_aliases_in_line(line, alias_map) for line in lines]
        file_path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")

    map_output_path = generated_dir / "alias-map.json"
    map_output = {alias: alias_map[alias] for alias in declaration_order}
    map_output_path.write_text(json.dumps(map_output, indent=2) + "\n", encoding="utf-8")

    print(f"Applied {len(declaration_order)} alias mappings.")
    print(f"Wrote alias map: {map_output_path}")
    return 0


def build_root_pool() -> list[str]:
    first_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    second_chars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return [a + b for a in first_chars for b in second_chars]


def variable_root(name: str) -> str:
    no_suffix = re.sub(r"[$%]$", "", name)
    return no_suffix[:2].upper()


def extract_label_name(line: str) -> str | None:
    if line.lstrip().startswith("#"):
        return None

    match = re.match(r"^\s*([A-Za-z][A-Za-z0-9]*)\s*:", line)
    if not match:
        return None

    return match.group(1)


def replace_aliases_in_line(line: str, alias_map: dict[str, str]) -> str:
    if line.lstrip().startswith("#"):
        return line

    out: list[str] = []
    i = 0
    in_string = False
    n = len(line)

    while i < n:
        ch = line[i]

        if ch == '"':
            in_string = not in_string
            out.append(ch)
            i += 1
            continue

        if not in_string:
            if ch == "'":
                out.append(line[i:])
                break

            if (ch == "@" and i + 1 < n and is_letter(line[i + 1])) or is_letter(ch):
                token, next_i = read_token(line, i)

                if not token.startswith("@") and token.lower() == "rem":
                    out.append(line[i:])
                    break

                if token.startswith("@"):
                    name = token[1:]
                    out.append(alias_map.get(name, token))
                else:
                    out.append(alias_map.get(token, token))

                i = next_i
                continue

        out.append(ch)
        i += 1

    return "".join(out)


def tokenize_line(line: str) -> list[str]:
    if line.lstrip().startswith("#"):
        return []

    tokens: list[str] = []
    i = 0
    in_string = False
    n = len(line)

    while i < n:
        ch = line[i]

        if ch == '"':
            in_string = not in_string
            i += 1
            continue

        if not in_string:
            if ch == "'":
                break

            if (ch == "@" and i + 1 < n and is_letter(line[i + 1])) or is_letter(ch):
                token, next_i = read_token(line, i)
                if not token.startswith("@") and token.lower() == "rem":
                    break
                tokens.append(token)
                i = next_i
                continue

        i += 1

    return tokens


def read_token(line: str, start: int) -> tuple[str, int]:
    i = start
    n = len(line)
    text = []

    if i < n and line[i] == "@":
        text.append("@")
        i += 1

    if i >= n:
        return "".join(text), i

    text.append(line[i])
    i += 1

    while i < n and is_alnum(line[i]):
        text.append(line[i])
        i += 1

    if i < n and line[i] in ("$", "%"):
        text.append(line[i])
        i += 1

    return "".join(text), i


def is_letter(ch: str) -> bool:
    return len(ch) == 1 and ch.isalpha()


def is_alnum(ch: str) -> bool:
    return len(ch) == 1 and ch.isalnum()


if __name__ == "__main__":
    raise SystemExit(main())
