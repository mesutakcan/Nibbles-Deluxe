# Nibbles Deluxe

[![Language](https://img.shields.io/badge/Language-QuickBasic-blue.svg)](https://en.wikipedia.org/wiki/QuickBASIC)
[![Platform](https://img.shields.io/badge/Platform-DOS%20%7C%20Windows-lightgrey.svg)](https://www.dosbox.com/)
[![GitHub stars](https://img.shields.io/github/stars/mesutakcan/Nibbles-Deluxe?style=social)](https://github.com/mesutakcan/Nibbles-Deluxe/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/mesutakcan/Nibbles-Deluxe?style=social)](https://github.com/mesutakcan/Nibbles-Deluxe/forks)
[![GitHub issues](https://img.shields.io/github/issues/mesutakcan/Nibbles-Deluxe)](https://github.com/mesutakcan/Nibbles-Deluxe/issues)
[![Downloads](https://img.shields.io/github/downloads/mesutakcan/Nibbles-Deluxe/total)](https://github.com/mesutakcan/Nibbles-Deluxe/releases)

An improved version of the classic **Microsoft QBasic Nibbles** (1990), written in
**QuickBASIC 4.5**. One or two players steer snakes around an arena, collect all the eggs
and try to stay alive.

The game runs in DOS / DOSBox (compiled with QuickBASIC 4.5), and also natively on
**Windows** (32 bit and 64 bit), compiled with
[QB64 Phoenix Edition](https://github.com/QB64-Phoenix-Edition/QB64pe).

![Nibbles Deluxe SS 1](docs/screenshot_1.png)

The game is published version by version; every version has its own release. The BASIC source
consists of two modules for QuickBASIC 4.5, always called `NIBBLESD.BAS` (the main module) and
`NIBBLEUI.BAS`, and of `NIBBLESD_ALL.BAS`, the same code in one file for QB64-PE.

## Features

- Direct video memory graphics: fast, flicker free, exact colours
- Settings menu: players, speed, colour theme, start level, sound, mines, doors, walls, ending, player names
- Five colour themes: Classic, Night, Forest, Ocean, Desert
- Stone walls (grey check pattern) or plain coloured walls
- Animated title screen with a big logo
- Eggs to collect on every level (8 + level number, at most 25)
- Eggs, hearts, bonus stars and mines are drawn as filled shapes (redefined characters; the
  normal characters are used if the video card does not accept the new shapes, which is always
  the case in QB64-PE, see **Known differences in QB64-PE**)
- The next level is built while the message box is on the screen, so you hardly ever wait
- A heart appears when only one egg is left: catch it for an extra life
- Bright snake heads; the snakes are visible before a round starts
- Two-tone striped snake bodies
- Red mines: random mines pop up during play, fixed mines are placed when a level starts
  (the game checks that every egg stays reachable); mode OFF / RANDOM / FIXED / BOTH
- Three death animations, chosen at random
- The egg counter in the status line blinks when only 1 or 2 eggs are left
- Side doors: now and then the walls open on both sides; go through one and come out on the other side
- Turn buffer: fast key presses are never lost, and a snake can no longer reverse into itself
- Flashing bonus stars and a bonus for completing a level
- Lives that really count down (the heart in the status line blinks on the last life),
  game over screen with the winner
- Player names can be changed in the menu
- Top 10 high score table with names, scores and levels; the live high score is shown in the
  status line during play
- Settings and names are saved to `NIBBLES.CFG`; the high score table is saved to `NIBBLES.HI`
- The game can end after level 25 with a victory screen and a life bonus, or go on endlessly
- The game speed is calibrated at start-up, so it plays the same on any computer
- 25 levels (the 10 original levels plus 15 new ones), including 5 divided arenas that can only be crossed through the side doors
- Runs in DOS / DOSBox and natively on Windows (32 bit and 64 bit)

![Nibbles Deluxe SS 2](docs/screenshot_2.png)

## Download

Go to the [Releases](https://github.com/mesutakcan/Nibbles-Deluxe/releases) page. Each
release offers these stand-alone programs:

| File | For |
| --- | --- |
| `NIBBLESD.EXE` | DOS or DOSBox (compiled with QuickBASIC 4.5) |
| `Nibbles-Deluxe-x64.exe` | Windows, 64 bit (compiled with QB64-PE) |
| `Nibbles-Deluxe-x86.exe` | Windows, 32 bit (compiled with QB64-PE) |

No emulator is needed for the two Windows files: download one and double-click it. On a
64 bit Windows (for example Windows 11) use the x64 file; the x86 file is for 32 bit
systems. Windows may show a SmartScreen warning for a program that is downloaded from the
internet and is not signed; the source code of the game is in the [`src`](src) folder, and you
can compile it yourself (see below).

The BASIC source (`NIBBLESD.BAS`, `NIBBLEUI.BAS` and `NIBBLESD_ALL.BAS`) is in the [`src`](src)
folder.

## Requirements

- **Windows version:** Windows with the x86 or x64 file; nothing else is needed.
- **DOS version:** a VGA colour display (DOS, or an emulator such as DOSBox).
- **To run or build the source:** QuickBASIC 4.5 (QB45) or QB64-PE

The game was developed and tested with QuickBASIC 4.5 in DOSBox. The source also builds with QB64-PE. The Windows builds are compiled with QB64-PE on Windows 11 and run there without an emulator.

## How to run

**The Windows EXE (QB64-PE build)**

1. Download `Nibbles-Deluxe-x64.exe` (or `Nibbles-Deluxe-x86.exe`) from the Releases page.
2. Copy it to a folder where you may write files, and start it.

The game saves `NIBBLES.CFG` and `NIBBLES.HI` in the current directory, so do not run it from
a folder that is write-protected.

**The DOS EXE**

1. Copy `NIBBLESD.EXE` to a folder.
2. Start it in DOS, or in DOSBox:

   ```
   mount c C:\games\nibbles
   c:
   NIBBLESD
   ```

**The source in QB45**

1. Copy `src/NIBBLESD.BAS` and `src/NIBBLEUI.BAS` to your QB45 folder.
2. Start QB45 and open `NIBBLESD.BAS`, then load the second module with **File > Load File...**
   (`NIBBLEUI.BAS`). `NIBBLESD.BAS` has to be the main module.
3. Press **F5** to run the game.
4. Choose **File > Save All**. QB45 creates `NIBBLESD.MAK`, so the next time you can start both
   modules at once with `QB NIBBLESD.MAK`.

**The source in QB64-PE**

1. Open `src/NIBBLESD_ALL.BAS` in the QB64-PE editor (this one file holds the whole game).
2. Press **F5** (**Run > Start**).

## Controls

| Key | Action |
| --- | --- |
| Arrow keys (or keypad 8 2 4 6) | Player 1 steers |
| W A S D | Player 2 steers (in one player mode they steer player 1, too) |
| P | Pause |
| ESC | Quit to the menu (asks Yes / No: arrow keys + ENTER, or Y / N; the default is No) |
| SPACE or ENTER | Close a message box (ESC in a message box also offers to quit to the menu) |

Menus: UP / DOWN select a line, LEFT / RIGHT (or SPACE) change a setting, ENTER starts the
game (on the two name lines ENTER lets you type a name, on the **High scores** line it shows the
table), ESC quits. The game over screen has three buttons, **PLAY AGAIN**, **MENU** and **QUIT**:
select with the arrow keys or TAB and press ENTER, or press P, M or Q (ESC quits). The box is only
as high as its content.

## How to play

Steer your snake and collect **all the eggs** of the level. The number of eggs is shown in
the status line and grows with the level: 8 + the level number, at most 25. You lose a life
if your snake hits a wall, the other snake, its own tail or a mine. If both heads meet, both
snakes die.

- **Egg**: 100 points, and your snake grows by 3 pixels.
- **Flashing star**: 500 points. It shows up now and then after you eat an egg and
  disappears after a few seconds.
- **Heart**: appears when only one egg is left, on the reachable spot that is farthest from
  the snakes. It flashes faster and faster; catch it in time for one extra life (at most 9
  lives). There is one heart per level. If you take the last egg first, the level ends and
  the heart is lost.
- **Level complete**: 500 bonus points.
- **Last level**: with **After last level** set to ENDING, finishing level 25 ends the game with a
  victory screen and a bonus of 1000 points for every life you have left.
- **Lives**: 5 for every player. The heart in the status line blinks when only one life is
  left. The game is over when a player has no life left. With two players the higher score
  wins.
- **Speed**: gets about 7 percent faster with every level (can be switched off).

**Side doors** open now and then in the left and right walls (a gap four text rows high). They
blink twice as a warning, open and stay open for about 10 seconds, then blink again and close.
A snake that enters an open door leaves the arena on the other side, like in Pac-Man. The doors
never open in front of walls, snakes, eggs or mines, and they wait to close while a snake is
still inside the gap. They can be switched off with the **Doors** setting, except on the divided
levels 21 to 25, where they always work (see Levels).

If a snake crashes, the level starts again with the same walls. Red mines may appear
randomly after an egg is eaten. There can be up to three mines on screen at once, never
close to a snake head; each stays steady and disappears after about 12 seconds. Hitting one costs
a life.

**Fixed mines** are placed when a level starts (from level 2: level number / 2, at most 6;
with two players they come in point symmetric pairs, so neither side has an advantage) and
stay until the level ends. A path search makes sure that every egg can still be reached.
Which kinds of mines appear is set with the **Mines** setting (default BOTH).

When a snake dies, one of three death animations is played (the two body shades blink away
in turn, the snake is wiped out from head to tail, or both one after the other).

## Levels

25 levels with different walls, played from easy to hard. Ten of them are the original
Nibbles levels, fifteen are new. The number is the play order (the **Start level** setting uses it
too).

| Level | Walls | Origin |
| --- | --- | --- |
| 1 | Empty arena | original |
| 2 | Centre bar | original |
| 3 | Two columns | original |
| 4 | Fence | original |
| 5 | Bunkers: four corner pockets | new |
| 6 | A box with four gates | new |
| 7 | Pinwheel | new |
| 8 | Diamond | new |
| 9 | Crossed diagonals | new |
| 10 | Offset bars | original |
| 11 | A big plus sign | new |
| 12 | Fortress | new |
| 13 | Corridors | original |
| 14 | Diagonals | original |
| 15 | Pillars | new |
| 16 | Comb | original |
| 17 | Inner box | original |
| 18 | Serpentine | new |
| 19 | Nested boxes | new |
| 20 | Dotted columns | original |
| 21 | Divide: a wall splits the arena | new |
| 22 | Zigzag: a zigzag wall splits the arena | new |
| 23 | Bulge: a wall with a bulge splits the arena | new |
| 24 | Crossbars: a thick wall with crossbars | new |
| 25 | Citadel: a very thick wall with bunkers | new |

On the **divided levels 21 to 25** a wall splits the arena into a left and a right half, and
the side doors are the only way over. The doors work on these levels even when the **Doors**
setting is OFF, and they open much more often (every 5 to 11 seconds instead of every 10 to 25).
The game moves any egg that could not be reached, even through the doors, to a reachable spot.

After level 25 the game ends with a victory screen (**After last level**: ENDING), or the levels
start again (ENDLESS) and, with "Faster each level" switched on, the game keeps getting faster.

## Settings

| Setting | Values |
| --- | --- |
| Players | 1 or 2 |
| Speed | 1 to 10 |
| Faster each level | ON / OFF |
| Start level | 1 to 25 |
| Colors | CLASSIC, NIGHT, FOREST, OCEAN, DESERT |
| Sound | ON / OFF |
| Mines | OFF, RANDOM, FIXED, BOTH |
| Doors | ON / OFF |
| Walls | STONE / PLAIN |
| After last level | ENDING / ENDLESS |
| Player 1 name | up to 8 characters (default SAMMY) |
| Player 2 name | up to 8 characters (default JAKE) |
| High scores | shows the top 10 table |

The settings and the names are saved when you leave the menu and are loaded the next time
the game starts.

![Nibbles Deluxe SS 3](docs/screenshot_3.png)

## Files the game creates

| File | Content |
| --- | --- |
| `NIBBLES.CFG` | The player names and all menu settings (including Doors, Walls and After last level) |
| `NIBBLES.HI` | The top 10 high score table (name, score, level) |

Both files are written to the current directory and keep these names in every version,
whatever the program file is called. Delete them to start fresh. A `NIBBLES.HI` file from
an earlier version (a single score) can still be read.

## Source files

| File | Content |
| --- | --- |
| `NIBBLESD.BAS` | QuickBASIC 4.5, main module: game logic, sound, file access (settings and high scores) |
| `NIBBLEUI.BAS` | QuickBASIC 4.5, second module: screens, menus, drawing helpers and the 25 level layouts |
| `NIBBLESD_ALL.BAS` | QB64-PE: the code of both modules merged into one file |

**Why two modules for QuickBASIC 4.5?** The only reason is memory. Compiled as a single file,
the game is too big for the QuickBASIC 4.5 compiler: `BC.EXE` stops with the error
"Out of memory" (and the linker then reports `L1101`, which is only a follow-up error). This
happens even with plenty of free DOS memory, because the compiler's own internal tables overflow,
not the memory of the machine (QuickBASIC 7.1 compiles the single file without problems). So the
source is split into two modules that are compiled separately and then linked. Both modules
declare the variables they share with identical `COMMON SHARED` blocks, and both are needed to
run or build the game.

**Why one merged file for QB64-PE?** QB64-PE builds a program from a single source file; it has
no way to link separate modules, and it has no memory problem with the big file.
`NIBBLESD_ALL.BAS` is the same code as the two modules, put into one file (the `COMMON SHARED`
lines became `DIM SHARED`). QB64-PE always compiles the program, so the file is compiled to an
EXE file (see **Building the EXE**) or built and started from the editor. `NIBBLESD.BAS` alone
does not work in QB64-PE. If you change the game, change both versions.

**Running without compiling in QB45:** the memory problem only occurs in the `BC` compiler. In
the QuickBASIC 4.5 environment the merged file `NIBBLESD_ALL.BAS` can be loaded and run directly
(**F5**), without being compiled, so you can also try the game with this single file.

**Compiled or run in the IDE?** A compiled program (`NIBBLESD.EXE`) runs faster than the same
code run from inside the QuickBASIC IDE, because the IDE interprets the code. For normal play,
use the compiled EXE file; running from the IDE is meant for trying and editing the source.

### Known differences in QB64-PE

The game redefines four characters of the VGA font (the filled shapes of the egg, the heart, the
bonus star and the mine). QuickBASIC 4.5 does this by writing to the video card's character
generator memory. QB64-PE does not support this: the change does not take place and the standard
characters are displayed instead of the redefined ones. The game detects this and uses the normal
characters. This is only a cosmetic difference; everything else works the same.

## Building the EXE

You can build the game yourself in two ways: with QuickBASIC 4.5 for DOS, or with QB64-PE
for Windows.

### DOS EXE with QuickBASIC 4.5

In QB45: open `NIBBLESD.BAS` and load `NIBBLEUI.BAS` with **File > Load** (or open `NIBBLESD.MAK`,
see above), choose **Run > Make EXE File**, select **Stand-Alone EXE File** and press **Make EXE**.
QB45 compiles both modules and links them.

![Make EXE File SS](docs/ss_make_exe_file.png)

From the command line (QB45 tools): compile each module with `BC`, then link the two object
files. The main module uses `ON ERROR ... RESUME NEXT` for the file access, so it has to be
compiled with `/E` and `/X`:

```
BC NIBBLESD.BAS /E/X/O/T/C:512;
BC NIBBLEUI.BAS /O/T/C:512;
LINK /EX NIBBLESD.OBJ+NIBBLEUI.OBJ,NIBBLESD.EXE,NUL,BCOM45.LIB;
```

`/E` and `/X` support `ON ERROR` and `RESUME` (only `NIBBLESD.BAS` needs them), `/O` makes a
stand-alone program, `/T` suppresses warning messages, `/C:512` sets the communications buffer
size, the `+` in the `LINK` line joins the two modules, and `LINK /EX` packs the EXE file. Run the
commands in the folder that holds both `.BAS` files and `BCOM45.LIB` (or give full paths).

In DOSBox you can start the same commands from the `mount`ed QB45 folder, for example
`C:\QB45\BC.EXE C:\QB45\NIBBLES\SRC\NIBBLESD.BAS/E/X/O/T/C:512;` and
`C:\QB45\BC.EXE C:\QB45\NIBBLES\SRC\NIBBLEUI.BAS/O/T/C:512;`, followed by
`C:\QB45\LINK.EXE /EX NIBBLESD.OBJ+NIBBLEUI.OBJ,NIBBLESD.EXE,NUL,C:\QB45\LIB\BCOM45.LIB;`.

### Windows EXE (32 bit and 64 bit) with QB64-PE

[QB64 Phoenix Edition](https://github.com/QB64-Phoenix-Edition/QB64pe) is a modern compiler
that accepts QuickBASIC code and creates native Windows programs. Compile the merged file
`NIBBLESD_ALL.BAS`.

1. Download QB64-PE from its
   [releases page](https://github.com/QB64-Phoenix-Edition/QB64pe/releases) and unpack it to
   a folder, for example `C:\qb64pe`.
2. Open PowerShell and compile the source from the command line. `-c` compiles without
   starting the program, `-f:TargetBits=` selects 32 or 64 bit, `-o` is the output file.
   Change the three paths to your own folders.

   **64 bit:**

   ```powershell
   $QB64 = "C:\qb64pe\qb64pe.exe"
   $SRC  = "C:\nibbles\src\NIBBLESD_ALL.BAS"
   $OUT  = "C:\nibbles\Nibbles-Deluxe-x64.exe"
   & $QB64 -c "$SRC" "-f:TargetBits=64" -o "$OUT"
   ```

   **32 bit:**

   ```powershell
   $QB64 = "C:\qb64pe\qb64pe.exe"
   $SRC  = "C:\nibbles\src\NIBBLESD_ALL.BAS"
   $OUT  = "C:\nibbles\Nibbles-Deluxe-x86.exe"
   & $QB64 -c "$SRC" "-f:TargetBits=32" -o "$OUT"
   ```

3. Start the new EXE file with a double-click.

Instead of the command line you can also open `NIBBLESD_ALL.BAS` in the QB64-PE editor and use
**Run > Make EXE Only**. The command line version is handy for building both files in one go.

## History

Newest version first.

### Version 15 - 2026-10-21

- The levels are sorted again from easy to hard (the level numbers changed; see the table in
  the Levels section). Places that can only be reached through a narrow gap (plus sign, inner
  box, dotted columns, nested boxes) now count as harder

### Version 14 - 2026-10-20

- The bonus diamond is now a **star** (new shape, text updated)
- Mines no longer flash: they stay steady and disappear after a while
- The game over screen is only as high as its content and is centred
- The high score screen in the menu is a little smaller

### Version 13 - 2026-10-19

- Hearts, bonus diamonds and mines get filled shapes like the eggs (all four are redefined
  characters, read back and checked; if the card refuses them the old shapes are restored and the
  normal characters are used); the original shapes are put back when the game ends
- A new level is built while the "level complete" or "crashed" message box is shown. The arena is
  drawn when the box is closed; "PLEASE WAIT" only appears if you press SPACE or ENTER before the
  level is ready, and an ESC pressed meanwhile is kept for the box
- The game over screen has three buttons (PLAY AGAIN, MENU, QUIT): arrow keys or TAB and ENTER,
  or P, M, Q

### Version 12 - 2026-10-18

- Eggs are now drawn as a filled egg shape: the game redefines one character of the VGA font
  (read back and checked; if the card does not accept it, the old hollow circle is used) and puts
  the original shape back when the game ends
- Building a level is much faster: the path search (eggs, fixed mines, heart) uses a flat array,
  redrawing the playfield and choosing a door row are quicker, and fewer attempts are made to
  place fixed mines
- A "PLEASE WAIT - preparing the arena..." message is shown while a level is built; after a
  crash there is a short pause before the level starts again

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

### Version 10 - 2026-10-16

- The Yes / No question (quit to the menu) is now a small menu: select with the arrow keys or
  TAB and confirm with ENTER, or press Y / N; ESC means No, and No is preselected
- ESC now also works in the message boxes (level start, pause, level complete ...): it asks
  "Quit to the menu?" and, if you say No, shows the box again
- The **START GAME** line of the settings menu is green

### Version 9 - 2026-10-15

- The 20 levels are now played in order from easy to hard (the level numbers changed; see the
  table in the Levels section)
- The settings menu no longer flickers: only the lines that change are redrawn, and each line
  is written in one piece
- Typing a player name no longer flickers either

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

### Version 7 - 2026-10-13

- 8 new levels, for 20 levels in total: bunkers (13), pinwheel (14), diamond (15), pillars
  (16), serpentine (17), crossed diagonals (18), fortress (19) and nested boxes (20)
- The **Start level** setting now goes from 1 to 20
- The levels start again after level 20

### Version 6 - 2026-10-12

- New **side doors**: gaps open in the left and right walls now and then; a snake that goes
  through leaves on the opposite side (warning blink before opening and closing, a door never
  closes on a snake)
- New **Doors** setting (ON / OFF), saved in `NIBBLES.CFG`
- Items and mines are never placed in the door lanes while a door is active
- The intro text explains the doors

### Version 5 - 2026-10-11

- Three death animations (blinking body shades, wipe from head to tail, or both), picked at
  random
- Fixed mines placed at the start of a level (symmetric pairs with two players); a path
  search checks that every egg stays reachable
- New **Mines** setting: OFF, RANDOM, FIXED or BOTH
- The egg counter in the status line blinks when only 1 or 2 eggs are left
- The version number is shown on the title screen

### Version 4 - 2026-10-10

- Eggs replace the numbers 1 to 9: collect all the eggs of a level (8 + level number, at
  most 25); every egg gives 100 points and makes the snake 3 pixels longer
- The status line shows the number of eggs that are left
- A heart appears when one egg is left; catching it gives an extra life (at most 9)
- The heart in the status line blinks when a player has only one life left
- Player names can be edited in the menu
- Menu settings and names are saved to `NIBBLES.CFG`
- The high score file also stores the name of the high score owner

### Version 3 - 2026-10-09

- Added red mines that appear randomly as numbers are eaten; mines can be switched off
- Added alternating two-tone stripes to the snake bodies
- Windows builds (32 bit and 64 bit), compiled with QB64-PE: the game now runs on Windows
  without an emulator; README describes how to build them

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

## Credits

Based on **Microsoft QBasic Nibbles**, Copyright (C) Microsoft Corporation 1990. This version
changes and extends the original game; the original levels 1 to 10 and the basic idea of the
game come from it.

The Windows builds are made with
[QB64 Phoenix Edition](https://github.com/QB64-Phoenix-Edition/QB64pe).
