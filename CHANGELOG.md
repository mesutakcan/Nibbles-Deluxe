## Changelog

Version 1 is the original QBasic `NIBBLES.BAS`, used as the starting point for this project.
The changelog begins with Version 2, the first version developed here.

### Version 2 - 2026-10-08

- Direct video memory graphics for fast, flicker-free drawing with exact colours
- Settings menu for players, speed, colour theme, start level and sound
- Three colour themes: Classic, Night and Mono
- Animated title screen with a large logo
- Bright snake heads, visible before a round starts
- Buffered turns so quick key presses are not lost and snakes cannot reverse into themselves
- Flashing bonus diamonds and a level-complete bonus
- Lives count down correctly; the game-over screen shows the winner
- High score saved to `NIBBLES.HI`
- Game speed calibrated to play consistently on different computers
- Two extra levels, for 12 levels in total

### Version 3 - 2026-10-09

- Added red mines that appear randomly as numbers are eaten; mines can be switched off
- Added alternating two-tone stripes to the snake bodies
- Windows builds (32 bit and 64 bit), compiled with QB64-PE: the game now runs on Windows
  without an emulator; README describes how to build them

### Version 4 - 2026-10-10

- Eggs replace the numbers 1 to 9: collect all the eggs of a level (8 + level number, at
  most 25); every egg gives 100 points and makes the snake 3 pixels longer
- The status line shows the number of eggs that are left
- A heart appears when one egg is left; catching it gives an extra life (at most 9)
- The heart in the status line blinks when a player has only one life left
- Player names can be edited in the menu
- Menu settings and names are saved to `NIBBLES.CFG`
- The high score file also stores the name of the high score owner

### Version 5 - 2026-10-11

- Three death animations (blinking body shades, wipe from head to tail, or both), picked at
  random
- Fixed mines placed at the start of a level (symmetric pairs with two players); a path
  search checks that every egg stays reachable
- New **Mines** setting: OFF, RANDOM, FIXED or BOTH
- The egg counter in the status line blinks when only 1 or 2 eggs are left
- The version number is shown on the title screen

### Version 6 - 2026-10-12

- New **side doors**: gaps open in the left and right walls now and then; a snake that goes
  through leaves on the opposite side (warning blink before opening and closing, a door never
  closes on a snake)
- New **Doors** setting (ON / OFF), saved in `NIBBLES.CFG`
- Items and mines are never placed in the door lanes while a door is active
- The intro text explains the doors

### Version 7 - 2026-10-13

- 8 new levels, for 20 levels in total: bunkers (13), pinwheel (14), diamond (15), pillars
  (16), serpentine (17), crossed diagonals (18), fortress (19) and nested boxes (20)
- The **Start level** setting now goes from 1 to 20
- The levels start again after level 20

### Version 8 - 2026-10-14

- New **top 10 high score table** (name, score and level) shown on the game over screen, with
  your rank; also available from the menu (**High scores**); the high score in the status line
  updates live; old `NIBBLES.HI` files are still read
- New game over screen: results, winner or draw, the table, and ENTER / M / ESC to play again,
  go to the menu or quit
- New **After last level** setting: ENDING (victory screen after level 20 with a bonus of 1000
  points per life left) or ENDLESS (levels repeat)
- New **Walls** setting: STONE (grey check pattern) or PLAIN
- Colour themes: Mono replaced by Forest, Ocean and Desert (five themes in total)
- The new settings are saved in `NIBBLES.CFG`
- Snakes can no longer start inside a wall: the starting body is checked cell by cell, and the
  start positions of player 1 on levels 6, 7, 8 and 10 were moved
- The settings menu has more lines and the help line moved to the bottom row of the screen

### Version 9 - 2026-10-15

- The 20 levels are now played in order from easy to hard (the level numbers changed; see the
  table in the Levels section)
- The settings menu no longer flickers: only the lines that change are redrawn, and each line
  is written in one piece
- Typing a player name no longer flickers either

### Version 10 - 2026-10-16

- The Yes / No question (quit to the menu) is now a small menu: select with the arrow keys or
  TAB and confirm with ENTER, or press Y / N; ESC means No, and No is preselected
- ESC now also works in the message boxes (level start, pause, level complete ...): it asks
  "Quit to the menu?" and, if you say No, shows the box again
- The **START GAME** line of the settings menu is green

### Version 11 - 2026-10-17

- 5 new levels, for 25 levels in total: the divided arenas 21 (divide), 22 (zigzag), 23 (bulge),
  24 (crossbars) and 25 (citadel); a wall splits the arena in two halves and the side doors are
  the only way over
- On divided levels the doors always work (even with **Doors** OFF) and open much sooner
- Eggs that nobody could reach are moved to a reachable spot; the path search for the eggs and
  the fixed mines now counts routes through the side doors
- The **Start level** setting goes from 1 to 25; the game ends after level 25 (ENDING)
- The **QUIT** line of the settings menu is red
- The source is split into two modules, `NIBBLESD.BAS` and `NIBBLEUI.BAS`, because the single
  file became too big for the QuickBASIC 4.5 compiler ("Out of memory"); QB64-PE uses the same
  code merged into one file, `NIBBLESD_ALL.BAS` (see **Source files** and **Building the EXE**)

### Version 12 - 2026-10-18

- Eggs are now drawn as a filled egg shape: the game redefines one character of the VGA font
  (read back and checked; if the card does not accept it, the old hollow circle is used) and puts
  the original shape back when the game ends
- Building a level is much faster: the path search (eggs, fixed mines, heart) uses a flat array,
  redrawing the playfield and choosing a door row are quicker, and fewer attempts are made to
  place fixed mines
- A "PLEASE WAIT - preparing the arena..." message is shown while a level is built; after a
  crash there is a short pause before the level starts again

### Version 13 - 2026-10-19

- Hearts, bonus diamonds and mines get filled shapes like the eggs (all four are redefined
  characters, read back and checked; if the card refuses them the old shapes are restored and the
  normal characters are used); the original shapes are put back when the game ends
- A new level is built while the "level complete" or "crashed" message box is shown. The arena is
  drawn when the box is closed; "PLEASE WAIT" only appears if you press SPACE or ENTER before the
  level is ready, and an ESC pressed meanwhile is kept for the box
- The game over screen has three buttons (PLAY AGAIN, MENU, QUIT): arrow keys or TAB and ENTER,
  or P, M, Q

### Version 14 - 2026-10-20

- The bonus diamond is now a **star** (new shape, text updated)
- Mines no longer flash: they stay steady and disappear after a while
- The game over screen is only as high as its content and is centred
- The high score screen in the menu is a little smaller

### Version 15 - 2026-10-21

- The levels are sorted again from easy to hard (the level numbers changed; see the table in
  the Levels section). Places that can only be reached through a narrow gap (plus sign, inner
  box, dotted columns, nested boxes) now count as harder

### Version 16 - 2026-10-22

- New **mine explosion**: when a snake hits a mine, a flash appears in the mine's cell and 16
  sparks fly out from it, slow down and change colour (white, yellow, red, dark red, grey),
  together with an explosion sound; then the usual death animation follows. A fixed mine that
  has exploded is not drawn again until the level is built anew
- New **title screen animation**: the egg, the bonus star, the mine and the heart travel around
  the screen edge and blink in turn. The pieces are spaced evenly and move at the same speed on
  the sides and on the top and bottom, although a text cell is twice as high as it is wide
- Every sound now sets its own tempo and note style, so a sound can no longer change the way
  the next one is played (the egg sound used to get faster after the explosion sound)
- Small speed-ups in the code that checks free cells and door lanes (placing hearts, mines and doors)

### Version 17 - 2026-10-27

- New **pill**: once per level (twice on the levels with more than 20 eggs) a flashing pill shows
  up on a random free spot, 2 to 12 seconds after the third egg is eaten, and a short alert sound
  announces it. It disappears after about 10 seconds. Eating it gives 250 points and shortens the
  snake by 3 pixels (one egg's worth, never below the starting length). Its pleasant eating sound
  is new, too
- The **heart** now appears at once: its places (the free corner places of the arena that the snakes
  can reach) are worked out when the level is built, and the heart is shown in the corner that is
  farthest from the nearest snake. The game no longer searches for a place while you play, which
  also removes a short stall that could delay the reaction to the arrow keys when the source was run
  inside the QuickBASIC editor
- New **opening music**, a cheerful four bar march that is played once on the title screen and
  stops almost at once when a key is pressed
- New sounds for the **start of a round**, for **eating an egg** and for a **crash**; random mines
  no longer play a sound when they appear
- The title screen animation shows the pill as well; new filled shapes for the egg, the heart, the
  bonus star and the mine, and one for the pill
- The "level complete" message boxes are dark green, so they cannot be mistaken for the "preparing
  the arena" message
- The source is checked in a code review: a path search result that still counted removed fixed
  mines is no longer reused

### Version 18 - 2026-10-28

- The two parts right behind a snake's head are drawn in a plain dark colour without stripes, so
  the bright head is easy to tell from the tail
- The sparks of a mine explosion are now characters (`*`, then `+`, then a small dot) that get
  smaller as they cool down
- The round start sound is no longer played when you quit to the menu from the message box before
  the round has started
- The declarations that both modules share (the user defined types, the constants and the
  `COMMON SHARED` variables) are now in one include file, `NIBBLES.BI`, which has to be in the
  same folder as `NIBBLESD.BAS` and `NIBBLEUI.BAS`; `NIBBLESD_ALL.BAS` for QB64-PE contains the
  same code merged into one file
