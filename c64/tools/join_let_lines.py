#!/usr/bin/env python3

import re
import sys
from pathlib import Path


LET_ASSIGN_RE = re.compile(
    r"^\s*let\s+(@?[A-Za-z][A-Za-z0-9]*[$%]?)\s*=.*$",
    re.IGNORECASE,
)


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("Usage: join_let_lines.py <generated-dir> [max-line-len]", file=sys.stderr)
        return 1

    generated_dir = Path(sys.argv[1])
    if not generated_dir.exists():
        print(f"Generated dir not found: {generated_dir}", file=sys.stderr)
        return 1

    max_line_len = 37
    if len(sys.argv) == 3:
        try:
            max_line_len = int(sys.argv[2])
        except ValueError:
            print(f"Invalid max line length: {sys.argv[2]}", file=sys.stderr)
            return 1

        if max_line_len < 1:
            print(f"Max line length must be >= 1: {max_line_len}", file=sys.stderr)
            return 1

    generated_files = sorted(generated_dir.glob("*.generated.bas"))
    if not generated_files:
        print("No generated BASIC files found for LET join processing.")
        return 0

    files_changed = 0
    groups_joined = 0

    for file_path in generated_files:
        original_lines = file_path.read_text(encoding="utf-8").splitlines()
        new_lines, file_groups_joined = join_let_groups(original_lines, max_line_len)
        if new_lines != original_lines:
            file_path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
            files_changed += 1
        groups_joined += file_groups_joined

    print(
        f"LET join complete. Groups joined: {groups_joined}. Files changed: {files_changed}."
    )
    return 0


def join_let_groups(lines: list[str], max_line_len: int) -> tuple[list[str], int]:
    out: list[str] = []
    let_group: list[str] = []
    groups_joined = 0

    def flush_group() -> None:
        nonlocal let_group
        nonlocal groups_joined

        if not let_group:
            return

        if len(let_group) == 1:
            out.append(strip_let(let_group[0]))
        else:
            statements = [strip_let(line).strip() for line in let_group]
            out.extend(pack_statements(statements, max_line_len))
            groups_joined += 1

        let_group = []

    for line in lines:
        if is_let_assignment(line):
            let_group.append(line)
            continue

        flush_group()
        out.append(line)

    flush_group()
    return out, groups_joined


def is_let_assignment(line: str) -> bool:
    return bool(LET_ASSIGN_RE.match(line))


def strip_let(line: str) -> str:
    return re.sub(r"^(\s*)let\s+", r"\1", line, flags=re.IGNORECASE)


def pack_statements(statements: list[str], max_line_len: int) -> list[str]:
    out: list[str] = []
    current = ""

    for statement in statements:
        if not current:
            current = statement
            continue

        candidate = f"{current}:{statement}"
        if len(candidate) <= max_line_len:
            current = candidate
            continue

        out.append(current)
        current = statement

    if current:
        out.append(current)

    return out


if __name__ == "__main__":
    raise SystemExit(main())
