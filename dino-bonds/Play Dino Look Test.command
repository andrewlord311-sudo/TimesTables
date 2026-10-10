#!/bin/bash
# Felix's dinosaur number-bonds game — look test. Double-click to play.
# Click the ground to walk the T. rex; arrow keys walk too; space = roar.
cd "$(dirname "$0")"
open -n "$HOME/Projects/godot-games/tools/Godot.app" --args --path "$PWD"
