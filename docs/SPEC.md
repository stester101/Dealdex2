# Deal Dex 2 - Specification (agreed 2026-11-07)

## Platform
1. Android only. Native APK. Target device: Galaxy Z Flip 6.
2. Engine: Godot 4 (GPU shaders, 2D lighting, particles, tilemaps).
3. Build: GitHub Actions builds the APK on each push.
4. Offline. Saves on the device. Save export and import (planned).

## Story structure
5. **Opening: the ferry.** Starts at Dover Docks. Intro, then the player picks a starter on the ferry deck. Playable deck with tutorial trainers and the first wild strain.
6. **Act 1: Amsterdam.** Quay, canals, streets, parks, the city by night. 8 coffee-shop gyms give 8 chips. New rivals. Ends with the Amsterdam champion.
7. **Mid-point.** A story event sends the player home to Deal.
8. **Act 2: a new Deal.** All maps new, from real geography: seafront, pier, High Street, Middle Street, castles, Walmer, Kingsdown, Sandwich, golf links. Each major building has its own interior. Time has passed. 8 new TPT chips.
9. **Finale: the Masters.** A champion whose team covers both regions.
10. **Post-game.** Legends from both regions, rematches, a ferry for free travel between regions.

## Content
11. About 170 strains: about 60 new Amsterdam strains and about 110 Deal strains. 2 new types. Cross-region evolutions.
12. Battles: abilities, natures, double battles, smarter AI tiers, battle-speed setting.
13. World: running shoes, bikes, canal boats, ledges, cutscenes. Day and night from the real clock. Events on set weekdays.
14. Extras: golf, Bowden's Bets, the quiz, the honesty box, the Remind-Me notes, plus Amsterdam extras (canal-boat race).

## Visual standard
15. No emoji. Everything is pixel art, to one style guide and one palette.
16. Strains: front and back sprites, idle animation, variant palette. Characters: 4-direction walk and run cycles, emotes.
17. World: animated tiles, real lighting for day/dusk/night, weather, particles, shader water.
18. Battles: an animation for each move, an intro transition, camera movement.
19. UI: hand-made pixel menus, Dex, bag, trainer card, region maps.
20. Two looks: Amsterdam = brick, canals, neon. Deal = sea, shingle, pastel houses.

## Android features
21. Haptics only. (Bluetooth controllers and Flex mode are out of scope.)
22. Daily swarm notifications.
23. Trading and battles between friends' phones on the same Wi-Fi.

## Known limits
- Friends on iPhone cannot play.
- Cover-screen use is not guaranteed.
