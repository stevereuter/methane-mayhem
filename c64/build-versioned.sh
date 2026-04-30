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
PYTHON_EXE="$VS64_DIR/resources/python/python.exe"
BC_EXE="$VS64_DIR/tools/bc.py"

if [ ! -f "$PYTHON_EXE" ] || [ ! -f "$BC_EXE" ]; then
    echo "Error: VS64 extension tools not found." >&2
    echo "Looked for python at: $PYTHON_EXE" >&2
    echo "Looked for compiler at: $BC_EXE" >&2
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

    awk '
        {
            if (match($0, /^([[:space:]]*#include[[:space:]]+")([^"]+)(".*)$/, m)) {
                include_path = m[2]
                new_path = include_path

                if (include_path ~ /^[A-Za-z0-9]+\.bas$/) {
                    sub(/\.bas$/, ".generated.bas", new_path)
                } else if (include_path ~ /^\.\.\/\.\.\/assets\//) {
                    sub(/^\.\.\/\.\.\/assets\//, "../../../assets/", new_path)
                }

                print m[1] new_path m[3]
            } else {
                print $0
            }
        }
    ' "$tmp_file" > "$out_file"

    rm -f "$tmp_file"
done

if [ -f "$PYTHON_EXE" ]; then
    "$PYTHON_EXE" "$SCRIPT_DIR/tools/apply_aliases.py" "$GENERATED_DIR"
else
    if grep -qE "@[a-z][A-Za-z0-9]*([$%])?[[:space:]]*(=|\\()" "$GENERATED_DIR"/*.generated.bas; then
        echo "Error: alias declarations found, but Python alias preprocessor runtime is unavailable." >&2
        exit 1
    fi
    echo "Python runtime not found; skipping alias preprocessing (no alias declarations detected)."
fi

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
