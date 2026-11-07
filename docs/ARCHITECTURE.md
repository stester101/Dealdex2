# Architecture

## Scene tree (all built in code from `src/main.tscn`)
```
Main (main.gd)
├── World (Node2D)                  canvas layer 0, lit by CanvasModulate + PointLight2D
│   ├── backdrop ColorRect
│   ├── water GroundLayer (water.gdshader)
│   ├── ground GroundLayer
│   ├── YSort Node2D  -> props (Sprite2D) + Actors
│   ├── PointLight2D lamps/windows, CanvasModulate tint, particles, gulls
│   └── Camera2D (manual clamp, keeps the player centred above the control deck)
├── CanvasLayer 2  battle (battle.gd)
├── CanvasLayer 3  TouchPanel (D-pad, A, B, MENU)
├── CanvasLayer 5  overlays (title, lists, summary, starter picker, banners)
├── CanvasLayer 6  DialogBox + ChoiceBox
└── CanvasLayer 10 fades and flashes
```

## Screen layout
The viewport is 270 px wide. The bottom `Game.PANEL_H` (196 px) is the control deck. The "screen" is everything above it. In battle, the deck shows the battle buttons.

## Data flow
- `Game.state` is one Dictionary. It is saved as JSON. Strains are Dictionaries: `{sp, lvl, xp, hp, stats[6], moves[], pp[], status, nick}`.
- Maps are ASCII grids plus prop/NPC/door/warp lists (`maps.gd`). Props have footprints that block movement and may carry lights.
- Story scripts are `await` chains in `story.gd`.

## Assets
`tools/build_assets.py` generates every PNG and WAV and writes `src/gen/tile_ids.gd`. Art helpers: `tools/pix.py` (cel shading with hue-shifted ramps + outlines).
