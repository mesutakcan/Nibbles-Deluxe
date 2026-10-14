# Nibbles Deluxe

[![Language](https://img.shields.io/badge/Language-QuickBasic-blue.svg)](https://en.wikipedia.org/wiki/QBasic)
[![Platform](https://img.shields.io/badge/Platform-DOS%20%7C%20Windows-lightgrey.svg)](https://www.dosbox.com/)
[![GitHub stars](https://img.shields.io/github/stars/mesutakcan/Nibbles-Deluxe?style=social)](https://github.com/mesutakcan/Nibbles-Deluxe/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/mesutakcan/Nibbles-Deluxe?style=social)](https://github.com/mesutakcan/Nibbles-Deluxe/forks)
[![GitHub issues](https://img.shields.io/github/issues/mesutakcan/Nibbles-Deluxe)](https://github.com/mesutakcan/Nibbles-Deluxe/issues)
[![Downloads](https://img.shields.io/github/downloads/mesutakcan/Nibbles-Deluxe/total)](https://github.com/mesutakcan/Nibbles-Deluxe/releases)

An improved version of the classic **Microsoft QBasic Nibbles** (1990), written in
**QuickBASIC 4.5**. One or two players steer snakes around an arena, eat the numbers in
order and try to stay alive.

The game runs in DOS / DOSBox (QuickBASIC 4.5 or QBasic 1.1), and since version 3 also
natively on **Windows** (32 bit and 64 bit), compiled with
[QB64 Phoenix Edition](https://github.com/QB64-Phoenix-Edition/QB64pe).

![Nibbles Deluxe SS 1](docs/screenshot_1.png)

The game is published version by version; every version has its own release. The BASIC file is
always called `NIBBLESD.BAS`.

## Features

- Direct video memory graphics: fast, flicker free, exact colours
- Settings menu: players, speed, colour theme, start level, sound, mines
- Three colour themes: Classic, Night, Mono
- Animated title screen with a big logo
- Bright snake heads; the snakes are visible before a round starts
- Two-tone striped snake bodies
- Red mines that appear during play (can be switched off)
- Turn buffer: fast key presses are never lost, and a snake can no longer reverse into itself
- Flashing bonus diamonds and a bonus for completing a level
- Lives that really count down, game over screen with the winner
- The high score is saved to `NIBBLES.HI`
- The game speed is calibrated at start-up, so it plays the same on any computer
- 12 levels (the 10 original levels plus 2 new ones)
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

The BASIC source is in the [`src`](src) folder.

## Requirements

- **Windows version:** Windows with the x86 or x64 file; nothing else is needed.
- **DOS version:** a VGA colour display (DOS, or an emulator such as DOSBox).
- **To run the source:** QuickBASIC 4.5 (QB45), or compile it with QB64-PE.

The game was developed and tested with QuickBASIC 4.5 in DOSBox. The source is written to run
in QBasic 1.1 as well. The Windows builds were compiled with QB64-PE on Windows 11 and run
there without an emulator.

## How to run

**The Windows EXE (QB64-PE build)**

1. Download `Nibbles-Deluxe-x64.exe` (or `Nibbles-Deluxe-x86.exe`) from the Releases page.
2. Copy it to a folder where you may write files, and start it.

The game saves `NIBBLES.HI` in the current directory, so do not run it from a folder that
is write-protected.

**The DOS EXE**

1. Copy `NIBBLESD.EXE` to a folder.
2. Start it in DOS, or in DOSBox:

   ```
   mount c C:\games\nibbles
   c:
   NIBBLESD
   ```

**The source in QB45**

1. Copy `src/NIBBLESD.BAS` to your QB45 folder.
2. Start QB45, open the file and press **F5**, or run `QB NIBBLESD.BAS /RUN`.

## Controls

| Key | Action |
| --- | --- |
| Arrow keys (or keypad 8 2 4 6) | Player 1 steers |
| W A S D | Player 2 steers (in one player mode they steer player 1, too) |
| P | Pause |
| ESC | Quit to the menu (asks Yes / No) |
| SPACE or ENTER | Close a message box |

Menus: UP / DOWN select a line, LEFT / RIGHT (or SPACE) change a setting, ENTER starts the
game, ESC quits. On the game over screen ENTER plays again, M returns to the menu and ESC
quits.

## How to play

Steer your snake and eat the numbers **1 to 9 in order**. When you have eaten the 9, the
level is complete. You lose a life if your snake hits a wall, the other snake or its own
tail. If both heads meet, both snakes die.

- **Number n**: n x 100 points, and your snake grows by n x 4 pixels.
- **Flashing diamond**: 500 points. It shows up now and then after you eat a number and
  disappears after a few seconds.
- **Level complete**: 500 bonus points.
- **Lives**: 5 for every player. The game is over when a player has no life left. With two
  players the higher score wins.
- **Speed**: gets about 7 percent faster with every level (can be switched off).

If a snake crashes, the level starts again with the same walls. Red mines may appear
randomly after a number is eaten. There can be up to three mines on screen at once;
each flashes and disappears after about 12 seconds. Hitting one costs a life. Mines
are enabled by default and can be switched off in the settings.

## Levels

12 levels with different walls. Levels 1 to 10 are the original Nibbles levels; level 11 is a
box with four gates and level 12 is a big plus sign. After level 12 the levels start again
(and, with "Faster each level" switched on, the game keeps getting faster).

## Settings

| Setting | Values |
| --- | --- |
| Players | 1 or 2 |
| Speed | 1 to 10 |
| Faster each level | ON / OFF |
| Start level | 1 to 12 |
| Colors | CLASSIC, NIGHT, MONO |
| Sound | ON / OFF |
| Mines | ON / OFF |

The players are called SAMMY and JAKE.

![Nibbles Deluxe SS 3](docs/screenshot_3.png)

## Files the game creates

| File | Content |
| --- | --- |
| `NIBBLES.HI` | The high score |

The file is written to the current directory and keeps this name in every version, whatever
the program file is called. Delete it to reset the high score.

## Building the EXE

You can build the game yourself in two ways: with QuickBASIC 4.5 for DOS, or with QB64-PE
for Windows.

### DOS EXE with QuickBASIC 4.5

In QB45: open `NIBBLESD.BAS`, choose **Run > Make EXE File**, select **Stand-Alone EXE File**
and press **Make EXE**.

From the command line (QB45 tools):

```
BC /O NIBBLESD.BAS;
LINK NIBBLESD.OBJ,,,BCOM45.LIB;
```

### Windows EXE (32 bit and 64 bit) with QB64-PE

[QB64 Phoenix Edition](https://github.com/QB64-Phoenix-Edition/QB64pe) is a modern compiler
that accepts QuickBASIC code and creates native Windows programs. The source of Nibbles
Deluxe compiles unchanged.

1. Download QB64-PE from its
   [releases page](https://github.com/QB64-Phoenix-Edition/QB64pe/releases) and unpack it to
   a folder, for example `C:\qb64pe`.
2. Open PowerShell and compile the source from the command line. `-c` compiles without
   starting the program, `-f:TargetBits=` selects 32 or 64 bit, `-o` is the output file.
   Change the three paths to your own folders.

   **64 bit:**

   ```powershell
   $QB64 = "C:\qb64pe\qb64pe.exe"
   $SRC  = "C:\nibbles\src\NIBBLESD.BAS"
   $OUT  = "C:\nibbles\Nibbles-Deluxe-x64.exe"
   & $QB64 -c "$SRC" "-f:TargetBits=64" -o "$OUT"
   ```

   **32 bit:**

   ```powershell
   $QB64 = "C:\qb64pe\qb64pe.exe"
   $SRC  = "C:\nibbles\src\NIBBLESD.BAS"
   $OUT  = "C:\nibbles\Nibbles-Deluxe-x86.exe"
   & $QB64 -c "$SRC" "-f:TargetBits=32" -o "$OUT"
   ```

3. Start the new EXE file with a double-click.

Instead of the command line you can also open `NIBBLESD.BAS` in the QB64-PE editor and use
**Run > Make EXE Only**. The command line version is handy for building both files in one go.

## History

Newest version first.

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
