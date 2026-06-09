#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

mapfile -t FILES < <(find . -maxdepth 1 -type f -iname "*.png" | sort)

if [ ${#FILES[@]} -eq 0 ]; then
    echo "No PNG files found."
    exit 1
fi

echo
echo "Found ${#FILES[@]} PNG files:"
echo

for file in "${FILES[@]}"; do
    echo "  $(basename "$file")"
done

echo
read -p "Continue? (y/n): " CONFIRM

[[ "$CONFIRM" =~ ^[Yy]$ ]] || exit 0

read -p "Horizontal or Vertical? (h/v): " MODE

if [[ "$MODE" == "v" ]]; then
    convert "${FILES[@]}" -append atlas.png
else
    convert "${FILES[@]}" +append atlas.png
fi

echo
echo "Created atlas.png"
