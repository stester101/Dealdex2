# Testing

## Automatic (CI)
Each push runs `godot --headless --path . -- --selftest`. It loads every map, runs dialog, plays real battle turns, a catch, XP, the AI, menus data, save and load. CI fails if the log has a script error or no `SELFTEST OK`. Logs go to the `ci-logs` branch.

## On the phone
1. New game: watch the intro, pick a starter, battle Oli.
2. Walk to the cargo nets. Catch a Stowaweed (weaken it first).
3. Beat Deckhand Des. Talk to Kettle and go ashore.
4. On the quay: check the lamps light up, the canal shimmers, the bridge works.
5. Enter the hostel and rest. Battle Backpacker Bram in the park.
6. Save from the menu, close the app, CONTINUE.
