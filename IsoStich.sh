#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

command -v convert >/dev/null 2>&1 || {
    echo "ImageMagick not installed"
    exit 1
}

echo
echo "=========================="
echo " TILE STENCIL TOOL"
echo "=========================="
echo
echo "1) Stencil only"
echo "2) Atlas only"
echo "3) Full pipeline"
echo

read -p "Select mode (1/2/3): " MODE

read -p "Tile width (px): " TW
read -p "Tile height (px): " TH

read -p "Map width (tiles): " MW
read -p "Map height (tiles): " MH

W=$((MW * TW))
H=$((MH * TH))

# -----------------------------
# DOT SEGMENT FUNCTION IDEA
# (implemented inline via loops)
# -----------------------------

draw_dotted_v() {
    local x=$1
    local y1=0
    local y2=$H
    local step=8
    local gap=6

    local y=$y1
    while [ $y -lt $y2 ]; do
        convert stencil.png -stroke "rgba(255,0,0,0.25)" \
        -draw "line $x,$y $x,$((y+step))" stencil.png
        y=$((y + step + gap))
    done
}

draw_dotted_h() {
    local y=$1
    local x1=0
    local x2=$W
    local step=8
    local gap=6

    local x=$x1
    while [ $x -lt $x2 ]; do
        convert stencil.png -stroke "rgba(255,0,0,0.25)" \
        -draw "line $x,$y $((x+step)),$y" stencil.png
        x=$((x + step + gap))
    done
}

# -----------------------------
# MODE 1: STENCIL ONLY
# -----------------------------
if [[ "$MODE" == "1" ]]; then

    convert -size ${W}x${H} xc:none stencil.png

    # GRID (solid)
    for ((x=0; x<=W; x+=TW)); do
        convert stencil.png -stroke "rgba(0,255,0,0.35)" \
        -draw "line $x,0 $x,$H" stencil.png
    done

    for ((y=0; y<=H; y+=TH)); do
        convert stencil.png -stroke "rgba(0,255,0,0.35)" \
        -draw "line 0,$y $W,$y" stencil.png
    done

    # CENTER LINES (dotted simulation)
    for ((y=0; y<H; y+=TH)); do
        cy=$((y + TH/2))
        draw_dotted_h $cy
    done

    for ((x=0; x<W; x+=TW)); do
        cx=$((x + TW/2))
        draw_dotted_v $cx
    done

    echo
    echo "DONE: stencil.png"
    exit 0
fi

# -----------------------------
# MODE 2: ATLAS ONLY
# -----------------------------
if [[ "$MODE" == "2" ]]; then

    mapfile -t FILES < <(find . -maxdepth 1 -type f -iname "*.png" | sort)

    read -p "Atlas direction (h/v): " DIR

    if [[ "$DIR" == "v" ]]; then
        convert "${FILES[@]}" -append atlas.png
    else
        convert "${FILES[@]}" +append atlas.png
    fi

    echo "DONE: atlas.png"
    exit 0
fi

# -----------------------------
# MODE 3: FULL PIPELINE
# -----------------------------
if [[ "$MODE" == "3" ]]; then

    mapfile -t FILES < <(find . -maxdepth 1 -type f -iname "*.png" | sort)

    read -p "Atlas direction (h/v): " DIR

    if [[ "$DIR" == "v" ]]; then
        convert "${FILES[@]}" -append atlas.png
    else
        convert "${FILES[@]}" +append atlas.png
    fi

    convert -size ${W}x${H} xc:none stencil.png

    # GRID
    for ((x=0; x<=W; x+=TW)); do
        convert stencil.png -stroke "rgba(0,255,0,0.35)" \
        -draw "line $x,0 $x,$H" stencil.png
    done

    for ((y=0; y<=H; y+=TH)); do
        convert stencil.png -stroke "rgba(0,255,0,0.35)" \
        -draw "line 0,$y $W,$y" stencil.png
    done

    # CENTER LINES (dotted)
    for ((y=0; y<H; y+=TH)); do
        cy=$((y + TH/2))
        draw_dotted_h $cy
    done

    for ((x=0; x<W; x+=TW)); do
        cx=$((x + TW/2))
        draw_dotted_v $cx
    done

    convert atlas.png stencil.png -compose over -composite atlas_with_stencil.png

    echo
    echo "DONE:"
    echo " atlas.png"
    echo " stencil.png"
    echo " atlas_with_stencil.png"
    exit 0
fi

echo "Invalid mode"
