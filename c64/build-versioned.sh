#!/bin/bash

# C64 build wrapper that injects version tokens into generated sources
# without mutating any file under c64/src.

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

VERSION=$(grep -o '"version": "[^"]*' "$REPO_ROOT/config.json" | grep -o '[^"]*$')
if [ -z "$VERSION" ]; then
    echo "Error: version not found in config.json" >&2
    exit 1
fi

echo "Building C64 with version $VERSION"

VS64_DIR=$(ls -d "$HOME"/.vscode/extensions/rosc.vs64-* 2>/dev/null | sort -V | tail -n 1)

# Try to find a working Python - prefer system Python on macOS
if command -v python3 &> /dev/null; then
    PYTHON_EXE=$(command -v python3)
elif [ -n "$VS64_DIR" ] && [ -f "$VS64_DIR/resources/python/python.exe" ]; then
    PYTHON_EXE="$VS64_DIR/resources/python/python.exe"
else
    echo "Error: Python not found" >&2
    exit 1
fi

if [ -z "$VS64_DIR" ]; then
    echo "Error: VS64 extension not found" >&2
    exit 1
fi

BC_EXE="$VS64_DIR/tools/bc.py"

if [ ! -f "$BC_EXE" ]; then
    echo "Error: VS64 compiler not found at: $BC_EXE" >&2
    exit 1
fi

GENERATED_DIR="$SCRIPT_DIR/build/generated"
GENERATED_MAIN="$GENERATED_DIR/main.generated.bas"
GENERATED_SPLASH_CANONICAL="$GENERATED_DIR/splash.bas"

mkdir -p "$GENERATED_DIR"
rm -f "$GENERATED_DIR"/*.generated.bas "$GENERATED_DIR"/alias-map.json "$GENERATED_DIR"/splash.bas

ESCAPED_VERSION=$(printf '%s' "$VERSION" | sed 's/[&/]/\\&/g')

for src_file in "$SCRIPT_DIR"/src/*.bas; do
    name=$(basename "$src_file" .bas)
    out_file="$GENERATED_DIR/$name.generated.bas"
    tmp_file="$out_file.tmp"

    sed "s/{version}/$ESCAPED_VERSION/g" "$src_file" > "$tmp_file"

    # Process include directives using portable sed
    # Convert "filename.bas" to "filename.generated.bas" in #include statements
    sed -e 's/\(#include[[:space:]]*"\)\([A-Za-z0-9_]*\)\.bas\("\)/\1\2.generated.bas\3/g' \
        "$tmp_file" > "$out_file"

    rm -f "$tmp_file"
done

if [ -f "$PYTHON_EXE" ]; then
    "$PYTHON_EXE" "$SCRIPT_DIR/tools/apply_aliases.py" "$GENERATED_DIR"
else
    if grep -qE "@[a-z][A-Za-z0-9]*([$%])?" "$GENERATED_DIR"/*.generated.bas; then
        echo "Error: @aliases found, but Python alias preprocessor runtime is unavailable." >&2
        exit 1
    fi
    echo "Python runtime not found; skipping alias preprocessing (no @aliases detected)."
fi

"$PYTHON_EXE" "$SCRIPT_DIR/tools/join_let_lines.py" "$GENERATED_DIR" 76

# Keep canonical splash filename available for nested includes that still
# reference splash.bas directly.
if [ -f "$GENERATED_DIR/splash.generated.bas" ]; then
    cp "$GENERATED_DIR/splash.generated.bas" "$GENERATED_SPLASH_CANONICAL"
fi

PRG_FILE="$SCRIPT_DIR/build/Methane Mayhem.prg"
BMAP_FILE="$SCRIPT_DIR/build/Methane Mayhem.bmap"

"$PYTHON_EXE" "$BC_EXE" --crunch --map "$BMAP_FILE" \
    -I "$SCRIPT_DIR" -I "$SCRIPT_DIR/build" -I "$GENERATED_DIR" \
    -o "$PRG_FILE" "$GENERATED_MAIN"

echo "Built: $PRG_FILE"
