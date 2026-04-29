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
GENERATED_SPLASH="$GENERATED_DIR/splash.generated.bas"
GENERATED_CHARACTERS="$GENERATED_DIR/characters.generated.bas"
GENERATED_SPLASH_CANONICAL="$GENERATED_DIR/splash.bas"

mkdir -p "$GENERATED_DIR"

ESCAPED_VERSION=$(printf '%s' "$VERSION" | sed 's/[&/]/\\&/g')

sed "s/{version}/$ESCAPED_VERSION/g" "$SCRIPT_DIR/src/splash.bas" > "$GENERATED_SPLASH"
cp "$SCRIPT_DIR/src/characters.bas" "$GENERATED_CHARACTERS"

# Keep canonical filenames in generated output so nested includes like
# #include "splash.bas" resolve to generated, versioned content.
cp "$GENERATED_SPLASH" "$GENERATED_SPLASH_CANONICAL"

awk '
    {
        if (match($0, /^#include "([^"]+)"$/, m)) {
            f = m[1]
            if (f == "splash.bas") {
                print "#include \"splash.generated.bas\""
            } else if (f == "characters.bas") {
                print "#include \"characters.generated.bas\""
            } else {
                print "#include \"../../src/" f "\""
            }
        } else {
            print $0
        }
    }
' "$SCRIPT_DIR/src/main.bas" > "$GENERATED_MAIN"

PRG_FILE="$SCRIPT_DIR/build/Methane Mayhem.prg"
BMAP_FILE="$SCRIPT_DIR/build/Methane Mayhem.bmap"

"$PYTHON_EXE" "$BC_EXE" --crunch --map "$BMAP_FILE" \
    -I "$SCRIPT_DIR" -I "$SCRIPT_DIR/build" -I "$GENERATED_DIR" \
    -o "$PRG_FILE" "$GENERATED_MAIN"

echo "Built: $PRG_FILE"
