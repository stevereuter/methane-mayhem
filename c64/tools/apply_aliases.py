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

    alias_order_keys: list[str] = []
    alias_first_seen: dict[str, str] = {}
    alias_canonical_name: dict[str, str] = {}

    for file_path in generated_files:
        lines = file_path.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, 1):
            for token in tokenize_line(line):
                if not token.startswith("@"):
                    continue

                alias = token[1:]
                if not alias:
                    continue

                alias_key = alias.lower()
                if alias_key not in alias_first_seen:
                    alias_first_seen[alias_key] = f"{file_path.name}:{idx}"
                    alias_canonical_name[alias_key] = alias
                    alias_order_keys.append(alias_key)

    if not alias_order_keys:
        print("No @aliases found.")
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

    for alias_key in alias_order_keys:
        alias = alias_canonical_name[alias_key]
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
        alias_map[alias_key] = f"{assigned_root}{suffix}"

    for file_path in generated_files:
        lines = file_path.read_text(encoding="utf-8").splitlines()
        out_lines = [replace_aliases_in_line(line, alias_map) for line in lines]
        file_path.write_text("\n".join(out_lines) + "\n", encoding="utf-8")

    map_output_path = generated_dir / "alias-map.json"
    map_output = {
        alias_canonical_name[k]: alias_map[k] for k in alias_order_keys
    }
    map_output_path.write_text(json.dumps(map_output, indent=2) + "\n", encoding="utf-8")

    print(f"Applied {len(alias_order_keys)} alias mappings.")
    print(f"Wrote alias map: {map_output_path}")
    return 0


def build_root_pool() -> list[str]:
    first_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    second_chars = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return [a + b for a in first_chars for b in second_chars]


def variable_root(name: str) -> str:
    no_suffix = re.sub(r"[$%]$", "", name)
    return no_suffix[:2].upper()


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
                    out.append(alias_map.get(name.lower(), token))
                else:
                    out.append(token)

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
