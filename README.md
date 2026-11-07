# Deal Dex 2: Amsterdam & Back

The sequel to [Deal Dex](https://github.com/stester101/DealDex). A Pokémon-style strain-collecting RPG for Android, built in Godot 4.3. It is a private gift game for the friend group.

- **Act 1:** the ferry to Amsterdam, then 8 coffee-shop gyms.
- **Act 2:** back to a new, rebuilt Deal, with 8 TPT chips and the Masters.

## Install on the phone (Galaxy Z Flip 6)

1. Open the repo's **Releases** page on the phone.
2. Download `DealDex2.apk` from the newest build.
3. Open the file. Allow "Install unknown apps" for your browser if Android asks.
4. When you install a newer build, the save stays.

Each push to `main` builds a new APK with GitHub Actions (`.github/workflows/build.yml`).

## Controls

| Control | World | Battle |
|---|---|---|
| D-pad | Walk (hold B to run) | Move the cursor |
| A | Talk / check / confirm | Confirm |
| B | Run (hold) / back | Back |
| MENU | Strains, Bag, Dex, Save | - |

You can also tap menus, dialog boxes and battle buttons directly.

## Develop

- Open the folder in Godot 4.3 (Compatibility renderer).
- All art and audio are generated from code: `python3 tools/build_assets.py` (needs Pillow and numpy).
- Read `CLAUDE.md` first if you are an AI agent.

## Docs

`docs/SPEC.md` · `docs/ARCHITECTURE.md` · `docs/ROADMAP.md` · `docs/STATUS.md` · `docs/TESTING.md` · `CHANGELOG.md`
