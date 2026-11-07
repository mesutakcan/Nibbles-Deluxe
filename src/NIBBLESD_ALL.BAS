'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  An improved version of the classic Microsoft QBasic Nibbles (1990).
'
'  https://github.com/mesutakcan/Nibbles-Deluxe
'  Version 20
'  2026-11-07
'
'  NIBBLESD_ALL.BAS: the code of NIBBLESD.BAS and NIBBLEUI.BAS merged into one
'  file, for QB64-PE.  (QuickBASIC 4.5 uses the two modules.)
'  For detailed information, please refer to the README.md file.
'===========================================================================

'$DYNAMIC
DEFINT A-Z


'---- Declarations shared by both modules (types, constants, COMMON SHARED) ----
'---- User defined types ----------------------------------------------------
TYPE snakeBody
    row AS INTEGER
    col AS INTEGER
END TYPE

TYPE snakeType
    head AS INTEGER        'ring buffer index of the newest segment
    count AS INTEGER       'number of segments drawn on the screen
    length AS INTEGER      'wanted length of the snake
    row AS INTEGER
    col AS INTEGER
    direction AS INTEGER   '1=up 2=down 3=left 4=right
    lastDir AS INTEGER     'direction of the last real move
    lives AS INTEGER
    score AS LONG
    alive AS INTEGER
END TYPE

'---- Constants used by both modules ------------------------------------------
CONST TRUE = -1
CONST FALSE = 0
CONST STARTLEN = 5
CONST NECKLEN = 2          'plain (unstriped) body parts right behind the head
CONST LEVELREC = 3604     'size of one level record in the level file NIBBLES.LVL
CONST MAXMINE = 3         'mines on the screen at the same time
CONST MINECHAR = 15       'character used for a mine
CONST MAXFIX = 8          'fixed mines per level (at most)
CONST STARTOVER = 1       'parameters of the Level SUB
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

'---- Variables shared by both modules (DIM SHARED) -------------------------
DIM SHARED hiName$
DIM SHARED hsCount
DIM SHARED vidSeg AS LONG, highScore AS LONG, curLevel, numLevels, numPlayers
DIM SHARED speedSet, speedUp, startLevel, theme, soundOn, mineMode
DIM SHARED doorsOn, wallStone, endMode, bonOn, fxCount, heartOn
DIM SHARED heartDone, doorState, abortGame, victory, splitLevel
DIM SHARED prepWhat, spaceHit, pendingEsc, deferDraw
DIM SHARED eggChr
DIM SHARED pillOn, pillCnt
DIM SHARED dcN                 'number of prepared door rows (0 = no door on this level)
DIM SHARED dlgBg

'---- Sub declarations --------------------------------------------------------
DECLARE FUNCTION AddToTable (n$, sc&, lv)
DECLARE FUNCTION AskYesNo (msg$)
DECLARE FUNCTION BannerRow$ (i)
DECLARE FUNCTION BodyColor (a, idx)
DECLARE FUNCTION CellBusy (rr, cc)
DECLARE FUNCTION CleanName$ (n$, dflt$)
DECLARE FUNCTION DoorFree (mask)
DECLARE FUNCTION DoorPass (row)
DECLARE FUNCTION DoorRowOk (r)
DECLARE FUNCTION DoorsActive ()
DECLARE FUNCTION DoorTicks (ms)
DECLARE FUNCTION DoorWaitMs ()
DECLARE FUNCTION EggsReachable ()
DECLARE FUNCTION GameOverScreen ()
DECLARE FUNCTION GlyphData$ (k)
DECLARE FUNCTION IsWallColor (c)
DECLARE FUNCTION ItemInRect (r1, c1, r2, c2)
DECLARE FUNCTION LevelBand ()
DECLARE FUNCTION LevelFileInit ()
DECLARE FUNCTION LevelNo ()
DECLARE FUNCTION MainMenu ()
DECLARE FUNCTION MineSpotOk (r, c)
DECLARE FUNCTION Num7$ (v&)
DECLARE FUNCTION PointIsThere (row, col)
DECLARE FUNCTION TryChooseDoor ()
DECLARE FUNCTION WallColor (row, col)
DECLARE SUB AddScore (a, pts)
DECLARE SUB ApplyTheme ()
DECLARE SUB BlinkHud ()
DECLARE SUB BorderPos (u, r, c)
DECLARE SUB Calibrate ()
DECLARE SUB Center (row, text$, attr)
DECLARE SUB ChangeSetting (sel, d)
DECLARE SUB ClearScreen (attr)
DECLARE SUB DeathAnim (a, variant)
DECLARE SUB DelayMs (ms)
DECLARE SUB Dialog (t1$, t2$, hint$)
DECLARE SUB DoorBlink (kind, flag)
DECLARE SUB DoorReset ()
DECLARE SUB DoorSet (k, wallFlag)
DECLARE SUB DoorTick ()
DECLARE SUB DrawBanner (row, phase, withShadow)
DECLARE SUB DrawBox (r1, c1, r2, c2, attr)
DECLARE SUB DrawCell (r, c)
DECLARE SUB DrawHud ()
DECLARE SUB DrawHudCenter (eggFg)
DECLARE SUB DrawItems ()
DECLARE SUB DrawMenu (sel)
DECLARE SUB DrawMenuFrame ()
DECLARE SUB DrawMenuHint ()
DECLARE SUB DrawMenuRow (i, sel)
DECLARE SUB DrawTable (r0, hl1, hl2, baseAttr, hlAttr)
DECLARE SUB EditName (who)
DECLARE SUB EraseSnake (a)
DECLARE SUB FillRect (r1, c1, r2, c2, ch, attr)
DECLARE SUB FindCell (rr, cc, found)
DECLARE SUB FixEggs ()
DECLARE SUB FontClose ()
DECLARE SUB FontOpen ()
DECLARE SUB HeartSpawn ()
DECLARE SUB HudCenter (eggFg)
DECLARE SUB HudPutStr (col, s$, attr)
DECLARE SUB HudShow (c1, c2)
DECLARE SUB Intro ()
DECLARE SUB Level (what)
DECLARE SUB LoadConfig ()
DECLARE SUB LoadGlyphs ()
DECLARE SUB LoadHigh ()
DECLARE SUB LoadLevelRec (k, rec$)
DECLARE SUB MineBoom (rr, cc)
DECLARE SUB PlaceEggs ()
DECLARE SUB PlaceFixedMines ()
DECLARE SUB PlayNibbles ()
DECLARE SUB PollWait ()
DECLARE SUB PrepareDoors ()
DECLARE SUB PrepareHeart ()
DECLARE SUB PrepareMines ()
DECLARE SUB PutChar (row, col, ch, attr)
DECLARE SUB PutHeart (rr, cc, d)
DECLARE SUB PutPixel (row, col, c)
DECLARE SUB PutStr (row, col, s$, attr)
DECLARE SUB QueueTurn (who, d)
DECLARE SUB ReadKeys ()
DECLARE SUB RedrawRows (r1, r2)
DECLARE SUB RestoreGlyphs ()
DECLARE SUB RunBfs (useDoors)
DECLARE SUB SaveConfig ()
DECLARE SUB SaveHigh ()
DECLARE SUB SetBlink (flag)
DECLARE SUB Sfx (n)
DECLARE SUB ShowScores ()
DECLARE SUB ShowWait ()
DECLARE SUB ShrinkSnake (a, n)
DECLARE SUB SnakeDist (r, c, a, dx, dy)
DECLARE SUB SparklePause ()
DECLARE SUB SpawnBonus ()
DECLARE SUB SpawnMine ()
DECLARE SUB SpawnPill ()
DECLARE SUB Tick ()
DECLARE SUB Wall (row, col)

'---- Constants used in this module only --------------------------------------
CONST MAXSNAKELENGTH = 1000
CONST MAXEGG = 30         'eggs per level (at most)
CONST EGGGLYPH = 1        'character code redefined as a filled egg
CONST MAXLIVES = 9
CONST VERSIONTXT = "VERSION 20"   'shown on the title screen
'Level rules.  The levels (LevelNo 1 to numLevels, starting again at 1 in ENDLESS mode)
'are cut into LVBANDS equal bands (see LevelBand), so the rules follow numLevels
CONST LEVELFILE = "NIBBLES.LVL"   'the level data file (the layouts of all levels)
CONST LVBANDS = 5         'number of level bands
CONST PILLFIRSTBAND = 1   'first band with pills (band 0 is the first one)
CONST DOORFIRSTBAND = 1   'first band with side doors (divided levels always have them)
CONST PILLEGGS = 16       'one pill for every PILLEGGS eggs of a level (rounded up)
CONST EGGSTART = 10       'eggs on a level of band 0
CONST EGGSTEP = 3         'more eggs for every band
CONST PILLCUT = 3         'segments a pill takes off the snake (one egg gives 3)
CONST PILLPTS = 250       'points for a pill
CONST DOORCAND = 4        'door rows prepared per level (one is used at a time)
CONST MINECAND = 36       'places prepared for random mines per level
CONST FINDTRIES = 300     'random tries of FindCell before it checks every cell
CONST HEARTTRIES = 100    'random places tried for the heart when no corner place is free
'Times in milliseconds (converted to game steps with stepMs)
CONST DOORWARNMS = 1500   'a door blinks this long before it opens and before it closes
CONST DOORHALFMS = 250    'time between the two halves of a door opening or closing
CONST DOOROPENMS = 20000  'a door stays open
CONST DOORRETRYMS = 3000  'new try when no door row could be used
CONST DOORIDLEMS = 10000  'waiting time until a door opens: this plus a random part
CONST DOORIDLERND = 15000
CONST DOORSPLITMS = 5000  'the same on divided levels (the doors are the only way over)
CONST DOORSPLITRND = 6000
CONST BONUSMS = 10000     'a bonus star stays
CONST MINELIFEMS = 12000  'a random mine stays
CONST MINEAWAYMS = 700    'a random mine keeps this much travel time away from a head
CONST PILLMS = 10000      'a pill stays
CONST PILLDELAYMS = 2000  'a pill comes this long after the 3rd egg, plus a random part
CONST PILLDELAYRND = 10000

'---- Global variables of this module only ------------------------------------
'The playfield is 80 x 50 "pixels": every text character holds two pixels
'(upper and lower half block).  arena() stores the colour of each pixel.
DIM SHARED qd(1 TO 2, 1 TO 3)                      'buffered turns per snake
DIM SHARED minRow(1 TO MAXMINE), minCol(1 TO MAXMINE)
DIM SHARED hitMine(1 TO 2), mineHitRow(1 TO 2), mineHitCol(1 TO 2)
DIM SHARED eggRow(1 TO MAXEGG), eggCol(1 TO MAXEGG)
DIM SHARED fxRow(1 TO MAXFIX), fxCol(1 TO MAXFIX)     'fixed mines
DIM SHARED bfsD(0 TO 3999), bfsQ(0 TO 3999)        'path search (one entry per pixel)
DIM SHARED glyphsOn
DIM SHARED gCode(1 TO 5), gNew$(1 TO 5), gOld$(1 TO 5)
DIM SHARED loopsPerMs AS SINGLE
DIM SHARED bonRow, bonCol, bonTime, eggLeft, eggTotal
DIM SHARED pillRow, pillCol, pillTime, pillWait, pillClr   'the pill (shortens the snake)
DIM SHARED godMode, cheated                'hidden test switch (Ctrl+G) and its flag
DIM SHARED heartRow, heartCol, heartTime, heartMax, tickCnt
DIM SHARED hcN, hcRow(1 TO 4), hcCol(1 TO 4), hcRat(1 TO 4)   'heart places near the corners; hcRat = path / straight line (x16)
DIM SHARED bfsFresh                        'TRUE while bfsD holds the result for the arena just built
DIM SHARED doorTimer, doorRow                      'side doors
DIM SHARED dcRow(1 TO DOORCAND)                    'prepared door rows (dcN of them, see NIBBLES.BI)
DIM SHARED mcN, mcRow(1 TO MINECAND), mcCol(1 TO MINECAND)   'prepared places for random mines
DIM SHARED hudLn$, hudAt$                          'status line: characters and colours, put together in memory
DIM SHARED newHigh, anyDead, levelDone, stepMs
DIM SHARED fileFail, fileBusy

'---- Arrays shared with NIBBLEUI.BAS (dimensioned here, at program start) -----
DIM SHARED arena(1 TO 50, 1 TO 80)                       'colour of each pixel
DIM SHARED sammy(1 TO 2) AS snakeType
DIM SHARED sammyBody(0 TO MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
DIM SHARED qn(1 TO 2)
DIM SHARED pal(1 TO 18)                                   'colour table, see ApplyTheme
DIM SHARED minTime(1 TO MAXMINE)
DIM SHARED hsName$(1 TO 10)
DIM SHARED hsLevel(1 TO 10)
DIM SHARED rankOf(1 TO 2)
DIM SHARED hsScore(1 TO 10) AS LONG                       'high score table
DIM SHARED nm$(1 TO 2)
DIM SHARED fxGone(1 TO MAXFIX)                           'exploded fixed mines (not drawn)

'---- Main program --------------------------------------------------------------
RANDOMIZE TIMER
ON ERROR GOTO FileErr

SCREEN 0
WIDTH 80, 25

vidSeg = &HB800&              'colour text screen
DEF SEG = 0
IF PEEK(&H449) = 7 THEN vidSeg = &HB000&      'monochrome adapter
DEF SEG

nm$(1) = "SAMMY": nm$(2) = "JAKE"
numPlayers = 1: speedSet = 5: speedUp = TRUE
startLevel = 1: theme = 1: soundOn = TRUE: mineMode = 4: doorsOn = TRUE
wallStone = TRUE: endMode = 1

IF NOT LevelFileInit THEN
    PRINT
    PRINT "The level file "; LEVELFILE; " is missing or damaged."
    PRINT "Folder searched: "; CURDIR$
    PRINT "Put the original file into the game folder and start the game again."
    PRINT
    PRINT "Press any key to exit."
    DO WHILE INKEY$ = "": LOOP
    END
END IF
LoadConfig
ApplyTheme
LoadHigh
SetBlink FALSE                'allows 16 background colours
LOCATE , , 0                  'hide the cursor
eggChr = 9                    'hollow circle unless the special shapes can be loaded
LoadGlyphs

ClearScreen 7
Center 12, "Please wait...", 7
Calibrate

Intro
quitAll = FALSE
DO
    startIt = MainMenu
    SaveConfig
    IF NOT startIt THEN EXIT DO
    ApplyTheme
    DO
        PlayNibbles
        IF abortGame THEN EXIT DO
        choice = GameOverScreen
        IF choice = 3 THEN quitAll = TRUE
    LOOP WHILE choice = 1
LOOP UNTIL quitAll

RestoreGlyphs
SetBlink TRUE
COLOR 7, 0
CLS
LOCATE , , 1
PRINT "Thanks for playing Nibbles Deluxe!"
END

'Error handler: only used while the high score file is accessed
FileErr:
    IF fileBusy THEN
        fileFail = TRUE
        RESUME NEXT
    ELSE
        ON ERROR GOTO 0
    END IF

'AddScore:
'  Adds points to a player and keeps the live high score up to date
SUB AddScore (a, pts)
    sammy(a).score = sammy(a).score + pts
    IF sammy(a).score > highScore THEN
        highScore = sammy(a).score
        hiName$ = nm$(a)
    END IF
END SUB

'AddToTable:
'  Puts a score into the high score table.  Returns its rank (1 to 10),
'  0 if it did not make it.
FUNCTION AddToTable (n$, sc&, lv)
    AddToTable = 0
    IF sc& <= 0 THEN EXIT FUNCTION
    slot = hsCount + 1
    FOR i = 1 TO hsCount
        IF sc& > hsScore(i) THEN
            slot = i
            EXIT FOR
        END IF
    NEXT i
    IF slot > 10 THEN EXIT FUNCTION
    lastIdx = hsCount
    IF lastIdx > 9 THEN lastIdx = 9
    FOR i = lastIdx TO slot STEP -1
        hsName$(i + 1) = hsName$(i)
        hsScore(i + 1) = hsScore(i)
        hsLevel(i + 1) = hsLevel(i)
    NEXT i
    hsName$(slot) = n$
    hsScore(slot) = sc&
    hsLevel(slot) = lv
    IF hsCount < 10 THEN hsCount = hsCount + 1
    AddToTable = slot
END FUNCTION

'BlinkHud:
'  Blinking parts of the status line: the heart of a player with only one
'  life and the egg counter when only 1 or 2 eggs are left
SUB BlinkHud
    hb = pal(12) * 16
    hc = 12
    IF (tickCnt AND 4) = 0 THEN fc = hc ELSE fc = pal(12)
    IF sammy(1).lives = 1 THEN PutChar 1, 11, 3, fc + hb
    IF numPlayers = 2 THEN
        IF sammy(2).lives = 1 THEN PutChar 1, 66, 3, fc + hb
    END IF
    IF eggLeft >= 1 AND eggLeft <= 2 THEN
        IF (tickCnt AND 4) = 0 THEN DrawHudCenter pal(16) ELSE DrawHudCenter pal(12)
    END IF
END SUB

'BodyColor:
'  Body colour of a snake segment: two shades alternate along the body
FUNCTION BodyColor (a, idx)
    IF idx AND 1 THEN BodyColor = pal(a) ELSE BodyColor = pal(12 + a)
END FUNCTION

'Calibrate:
'  Measures how fast an empty loop runs, so delays are given in milliseconds
SUB Calibrate
    DIM n AS LONG, i AS LONG
    DIM t0 AS SINGLE, t1 AS SINGLE, el AS SINGLE
    n = 2000
    DO
        t0 = TIMER
        DO
            t1 = TIMER
        LOOP WHILE t1 = t0
        t0 = t1
        FOR i = 1 TO n: NEXT i
        t1 = TIMER
        el = t1 - t0
        IF el < 0 THEN el = el + 86400
        done = (el >= .4 OR n >= 500000000)
        IF NOT done THEN n = n * 2
    LOOP UNTIL done
    IF el < .01 THEN el = .01
    loopsPerMs = n / (el * 1000)
END SUB

'CellBusy:
'  TRUE if an item (egg, bonus, heart, pill, mine) already sits on the text cell
FUNCTION CellBusy (rr, cc)
    CellBusy = TRUE
    FOR e = 1 TO MAXEGG
        IF eggRow(e) = rr AND eggCol(e) = cc THEN EXIT FUNCTION
    NEXT e
    IF bonOn THEN
        IF bonRow = rr AND bonCol = cc THEN EXIT FUNCTION
    END IF
    IF heartOn THEN
        IF heartRow = rr AND heartCol = cc THEN EXIT FUNCTION
    END IF
    IF pillOn THEN
        IF pillRow = rr AND pillCol = cc THEN EXIT FUNCTION
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            IF minRow(m) = rr AND minCol(m) = cc THEN EXIT FUNCTION
        END IF
    NEXT m
    FOR m = 1 TO fxCount
        IF fxRow(m) = rr AND fxCol(m) = cc THEN EXIT FUNCTION
    NEXT m
    FOR k = 1 TO dcN                            'keep the lanes of the prepared doors free
        IF rr >= dcRow(k) AND rr <= dcRow(k) + 3 THEN
            IF cc <= 7 OR cc >= 74 THEN EXIT FUNCTION
        END IF
    NEXT k
    CellBusy = FALSE
END FUNCTION

'DeathAnim:
'  Death animation of snake a.  variant 1 = the two body shades blink
'  away in turn, 2 = the snake is wiped out from the head to the tail,
'  3 = both one after the other.
SUB DeathAnim (a, variant)
    IF variant = 1 THEN
        fr = 6
    ELSEIF variant = 3 THEN
        fr = 4
    ELSE
        fr = 0
    END IF

    FOR f = 1 TO fr
        FOR k = 0 TO sammy(a).count - 1
            idx = (sammy(a).head - k + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
            IF k = 0 THEN
                px = pal(6 + a)
            ELSEIF k <= NECKLEN THEN
                px = pal(12 + a)                      'the neck: dark, no stripes
            ELSEIF idx AND 1 THEN
                px = pal(a)
            ELSE
                px = pal(12 + a)
            END IF
            IF k > 0 THEN
                IF f AND 1 THEN
                    IF (idx AND 1) = 0 THEN px = pal(4)
                ELSE
                    IF (idx AND 1) = 1 THEN px = pal(4)
                END IF
            END IF
            PutPixel sammyBody(idx, a).row, sammyBody(idx, a).col, px
        NEXT k
        DelayMs 90
    NEXT f

    IF variant <> 1 THEN
        chunk = sammy(a).count \ 12 + 1
        k = 0
        DO WHILE k < sammy(a).count
            FOR j = 1 TO chunk
                IF k < sammy(a).count THEN
                    idx = (sammy(a).head - k + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
                    PutPixel sammyBody(idx, a).row, sammyBody(idx, a).col, pal(4)
                    k = k + 1
                END IF
            NEXT j
            DelayMs 60
        LOOP
    END IF
END SUB

'DelayMs:
'  Waits roughly the given number of milliseconds
SUB DelayMs (ms)
    DIM i AS LONG, n AS LONG
    n = ms * loopsPerMs
    IF n < 1 THEN n = 1
    FOR i = 1 TO n: NEXT i
END SUB

'DoorBlink:
'  Blink effect on the door cells (only drawn on the screen, the arena is
'  not changed).  kind 1 = solid block on the closed door, 2 = shaded block
'  in the open gap.  flag FALSE restores the normal picture.
SUB DoorBlink (kind, flag)
    IF kind = 1 THEN ch = 219 ELSE ch = 177
    FOR k = 0 TO 3
        r = doorRow + k
        FOR side = 1 TO 2
            IF side = 1 THEN cl = 1 ELSE cl = 80
            IF flag THEN
                t = arena(r * 2 - 1, cl)
                b = arena(r * 2, cl)
                IF t = b THEN
                    IF IsWallColor(t) OR t = pal(4) THEN PutChar r, cl, ch, pal(9) + pal(4) * 16
                END IF
            ELSE
                DrawCell r, cl
            END IF
        NEXT side
    NEXT k
END SUB

'DoorFree:
'  TRUE if no snake is inside the door cells selected by mask
'  (bits: 1 = cell 0, 2 = cell 1, 4 = cell 2, 8 = cell 3)
FUNCTION DoorFree (mask)
    DoorFree = FALSE
    bit = 1
    FOR k = 0 TO 3
        IF mask AND bit THEN
            r = doorRow + k
            IF arena(r * 2 - 1, 1) <> pal(4) OR arena(r * 2, 1) <> pal(4) THEN EXIT FUNCTION
            IF arena(r * 2 - 1, 80) <> pal(4) OR arena(r * 2, 80) <> pal(4) THEN EXIT FUNCTION
        END IF
        bit = bit + bit
    NEXT k
    DoorFree = TRUE
END FUNCTION

'DoorRowOk:
'  TRUE if a door can open at text rows r to r + 3: no wall in the three
'  pixel columns next to the edge, no egg, mine or other item in the lanes,
'  and none of the prepared heart places
FUNCTION DoorRowOk (r)
    DoorRowOk = FALSE
    FOR pr = r * 2 - 1 TO (r + 3) * 2
        IF arena(pr, 2) <> pal(4) OR arena(pr, 3) <> pal(4) OR arena(pr, 4) <> pal(4) THEN EXIT FUNCTION
        IF arena(pr, 77) <> pal(4) OR arena(pr, 78) <> pal(4) OR arena(pr, 79) <> pal(4) THEN EXIT FUNCTION
    NEXT pr
    IF ItemInRect(r, 2, r + 3, 7) THEN EXIT FUNCTION
    IF ItemInRect(r, 74, r + 3, 79) THEN EXIT FUNCTION
    FOR k = 1 TO hcN
        IF hcRow(k) >= r AND hcRow(k) <= r + 3 THEN
            IF hcCol(k) <= 7 OR hcCol(k) >= 74 THEN EXIT FUNCTION
        END IF
    NEXT k
    DoorRowOk = TRUE
END FUNCTION

'DoorPass:
'  TRUE if a snake may wrap around on this pixel row (door is not closed)
FUNCTION DoorPass (row)
    DoorPass = FALSE
    IF doorState >= 2 THEN
        IF row >= doorRow * 2 - 1 AND row <= (doorRow + 3) * 2 THEN DoorPass = TRUE
    END IF
END FUNCTION

'DoorReset:
'  Closes the doors and starts the waiting time (new round)
SUB DoorReset
    doorState = 0
    doorTimer = DoorTicks(DoorWaitMs)
END SUB

'DoorSet:
'  Sets the four pixels of door cell k (both walls): wall or empty
SUB DoorSet (k, wallFlag)
    r = doorRow + k
    FOR side = 1 TO 2
        IF side = 1 THEN cl = 1 ELSE cl = 80
        FOR p = r * 2 - 1 TO r * 2
            IF wallFlag THEN
                PutPixel p, cl, WallColor(p, cl)
            ELSE
                PutPixel p, cl, pal(4)
            END IF
        NEXT p
    NEXT side
END SUB

'DoorTick:
'  State machine of the side doors, called once per game step.
'  0 closed and waiting   1 blinking before opening   2 half open
'  3 open                 4 blinking before closing   5 half closed
SUB DoorTick
    SELECT CASE doorState
        CASE 0
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                IF TryChooseDoor THEN
                    doorState = 1
                    doorTimer = DoorTicks(DOORWARNMS)
                    Sfx 9
                ELSE
                    doorTimer = DoorTicks(DOORRETRYMS)
                END IF
            END IF
        CASE 1
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                DoorBlink 1, FALSE
                DoorSet 0, FALSE
                DoorSet 2, FALSE
                doorState = 2
                doorTimer = DoorTicks(DOORHALFMS)
            ELSE
                DoorBlink 1, (doorTimer \ 2) AND 1
            END IF
        CASE 2
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                DoorSet 1, FALSE
                DoorSet 3, FALSE
                doorState = 3
                doorTimer = DoorTicks(DOOROPENMS)
            END IF
        CASE 3
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                doorState = 4
                doorTimer = DoorTicks(DOORWARNMS)
                Sfx 9
            END IF
        CASE 4
            IF doorTimer > 0 THEN doorTimer = doorTimer - 1
            IF doorTimer > 0 THEN
                IF DoorFree(15) THEN
                    DoorBlink 2, (doorTimer \ 2) AND 1
                ELSE
                    DoorBlink 2, FALSE                'a snake is passing: no blinking
                END IF
            ELSEIF DoorFree(15) THEN
                DoorBlink 2, FALSE
                DoorSet 1, TRUE
                DoorSet 3, TRUE
                doorState = 5
                doorTimer = DoorTicks(DOORHALFMS)
            ELSE
                DoorBlink 2, FALSE                    'a snake is inside: wait, the door stays steady
            END IF
        CASE 5
            IF doorTimer > 0 THEN doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                IF DoorFree(5) THEN
                    DoorSet 0, TRUE
                    DoorSet 2, TRUE
                    doorState = 0
                    doorTimer = DoorTicks(DoorWaitMs)
                END IF
            END IF
    END SELECT
END SUB

'DoorTicks:
'  Converts milliseconds to game steps
FUNCTION DoorTicks (ms)
    s = stepMs
    IF s < 8 THEN s = 8
    t = ms \ s
    IF t < 2 THEN t = 2
    DoorTicks = t
END FUNCTION

'DoorWaitMs:
'  Waiting time (milliseconds) until the doors open the next time;
'  much shorter on the divided levels, where the doors are the only way over
FUNCTION DoorWaitMs
    IF splitLevel THEN
        DoorWaitMs = DOORSPLITMS + INT(RND * DOORSPLITRND)
    ELSE
        DoorWaitMs = DOORIDLEMS + INT(RND * DOORIDLERND)
    END IF
END FUNCTION

'DrawCell:
'  Draws one text character of the playfield from the two pixels in arena()
SUB DrawCell (r, c)
    t = arena(r * 2 - 1, c)
    b = arena(r * 2, c)
    IF t = b THEN
        ch = 219: attr = t + (t AND 7) * 16
    ELSEIF b < 8 THEN
        ch = 223: attr = t + b * 16
    ELSEIF t < 8 THEN
        ch = 220: attr = b + t * 16
    ELSE
        ch = 223: attr = t + b * 16
    END IF
    ofs = (r - 1) * 160 + (c - 1) * 2
    DEF SEG = vidSeg
    POKE ofs, ch
    POKE ofs + 1, attr
    DEF SEG
END SUB

'DrawHud:
'  Status line (row 1): names, lives, scores, level, eggs left, high score.
'  The line is put together in memory and written to the screen in one pass,
'  so the screen never shows an emptied line (no flicker).
SUB DrawHud
    hb = pal(12) * 16
    hudLn$ = SPACE$(80)
    hudAt$ = STRING$(80, CHR$(pal(11) + hb))
    hc = 12

    lv = sammy(1).lives
    IF lv < 0 THEN lv = 0
    IF lv > MAXLIVES THEN lv = MAXLIVES
    HudPutStr 2, nm$(1), pal(1) + hb
    HudPutStr 11, CHR$(3), hc + hb
    HudPutStr 13, LTRIM$(STR$(lv)), pal(11) + hb
    HudPutStr 16, Num7$(sammy(1).score), pal(11) + hb

    HudCenter pal(16)

    IF numPlayers = 2 THEN
        lv = sammy(2).lives
        IF lv < 0 THEN lv = 0
        IF lv > MAXLIVES THEN lv = MAXLIVES
        HudPutStr 58, Num7$(sammy(2).score), pal(11) + hb
        HudPutStr 66, CHR$(3), hc + hb
        HudPutStr 68, LTRIM$(STR$(lv)), pal(11) + hb
        HudPutStr 71, nm$(2), pal(2) + hb
    ELSE
        HudPutStr 62, "P=Pause  ESC=Quit", pal(11) + hb
    END IF
    HudShow 1, 80
END SUB

'DrawHudCenter:
'  Redraws only the middle of the status line (columns 24 to 57), in one pass
SUB DrawHudCenter (eggFg)
    hb = pal(12) * 16
    hudLn$ = SPACE$(80)
    hudAt$ = STRING$(80, CHR$(pal(11) + hb))
    HudCenter eggFg
    HudShow 24, 57
END SUB

'HudCenter:
'  Puts the middle of the status line into the buffer: level, eggs left
'  (colour eggFg), high score
SUB HudCenter (eggFg)
    hb = pal(12) * 16
    a$ = "LEVEL" + STR$(curLevel) + "   "
    b$ = CHR$(eggChr) + STR$(eggLeft)
    c$ = "   HI " + Num7$(highScore)
    sc = (80 - LEN(a$) - LEN(b$) - LEN(c$)) \ 2 + 1
    HudPutStr 24, SPACE$(34), pal(11) + hb
    HudPutStr sc, a$, pal(11) + hb
    HudPutStr sc + LEN(a$), b$, eggFg + hb
    HudPutStr sc + LEN(a$) + LEN(b$), c$, pal(11) + hb
END SUB

'HudPutStr:
'  Puts a text with one colour into the status line buffer (not on the screen)
SUB HudPutStr (col, s$, attr)
    n = LEN(s$)
    IF col + n - 1 > 80 THEN n = 80 - col + 1
    IF n < 1 THEN EXIT SUB
    MID$(hudLn$, col, n) = LEFT$(s$, n)
    MID$(hudAt$, col, n) = STRING$(n, CHR$(attr))
END SUB

'HudShow:
'  Writes the columns c1 to c2 of the status line buffer to the screen
SUB HudShow (c1, c2)
    DEF SEG = vidSeg
    ofs = (c1 - 1) * 2
    FOR c = c1 TO c2
        POKE ofs, ASC(MID$(hudLn$, c, 1))
        POKE ofs + 1, ASC(MID$(hudAt$, c, 1))
        ofs = ofs + 2
    NEXT c
    DEF SEG
END SUB

'DrawItems:
'  Draws the eggs, the bonus star, the pill, the heart and the mines
SUB DrawItems
    FOR e = 1 TO MAXEGG
        IF eggRow(e) > 0 THEN PutChar eggRow(e), eggCol(e), eggChr, pal(9) + pal(4) * 16
    NEXT e
    IF bonOn THEN PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
    IF pillOn THEN PutChar pillRow, pillCol, 5, pillClr + pal(4) * 16
    IF heartOn THEN
        hc = 12
        PutChar heartRow, heartCol, 3, hc + pal(4) * 16
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN PutChar minRow(m), minCol(m), MINECHAR, pal(15) + pal(4) * 16
    NEXT m
    FOR m = 1 TO fxCount
        IF NOT fxGone(m) THEN PutChar fxRow(m), fxCol(m), MINECHAR, pal(15) + pal(4) * 16
    NEXT m
END SUB

'EggsReachable:
'  TRUE if a snake head can reach every egg (uses the result of RunBfs)
FUNCTION EggsReachable
    EggsReachable = TRUE
    FOR e = 1 TO eggTotal
        IF eggRow(e) > 0 THEN
            IF bfsD((eggRow(e) * 2 - 2) * 80 + eggCol(e) - 1) < 0 AND bfsD((eggRow(e) * 2 - 1) * 80 + eggCol(e) - 1) < 0 THEN EggsReachable = FALSE
        END IF
    NEXT e
END FUNCTION

'EraseSnake:
'  Removes a snake from the screen
SUB EraseSnake (a)
    FOR k = 0 TO sammy(a).count - 1
        idx = (sammy(a).head - k + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
        PutPixel sammyBody(idx, a).row, sammyBody(idx, a).col, pal(4)
    NEXT k
    sammy(a).count = 0
END SUB

'FindCell:
'  Finds a free text cell (both pixels empty, no item) for an item.  found is
'  FALSE when there is none.  FINDTRIES random cells are tried first (fast);
'  if they are all taken, every cell is checked once, from a random start.
SUB FindCell (rr, cc, found)
    found = FALSE
    FOR tries = 1 TO FINDTRIES
        p = INT(RND * 46) + 4
        cc = INT(RND * 78) + 2
        IF p AND 1 THEN q = p + 1 ELSE q = p - 1
        rr = (p + 1) \ 2
        IF arena(p, cc) = pal(4) AND arena(q, cc) = pal(4) THEN
            IF NOT CellBusy(rr, cc) THEN
                found = TRUE
                EXIT SUB
            END IF
        END IF
    NEXT tries
    start = INT(RND * 3588)                     '46 pixel rows x 78 columns
    FOR i = 0 TO 3587
        n = (start + i) MOD 3588
        p = n \ 78 + 4
        cc = n MOD 78 + 2
        IF p AND 1 THEN q = p + 1 ELSE q = p - 1
        rr = (p + 1) \ 2
        IF arena(p, cc) = pal(4) AND arena(q, cc) = pal(4) THEN
            IF NOT CellBusy(rr, cc) THEN
                found = TRUE
                EXIT SUB
            END IF
        END IF
    NEXT i
END SUB

'FixEggs:
'  Divided levels: moves eggs that nobody can reach (even through the
'  doors) to a reachable spot
SUB FixEggs
    RunBfs TRUE
    FOR e = 1 TO eggTotal
        IF eggRow(e) > 0 THEN
            tries = 0
            DO WHILE bfsD((eggRow(e) * 2 - 2) * 80 + eggCol(e) - 1) < 0 AND bfsD((eggRow(e) * 2 - 1) * 80 + eggCol(e) - 1) < 0 AND tries < 200
                tries = tries + 1
                oldR = eggRow(e)
                eggRow(e) = 0
                FindCell r, c, found
                IF NOT found THEN eggRow(e) = oldR: EXIT DO
                eggRow(e) = r
                eggCol(e) = c
            LOOP
        END IF
    NEXT e
END SUB

'FontClose:
'  Back to the normal text mode memory layout
SUB FontClose
    OUT &H3C4, 2: OUT &H3C5, 3
    OUT &H3C4, 4: OUT &H3C5, 3
    OUT &H3CE, 4: OUT &H3CF, 0
    OUT &H3CE, 5: OUT &H3CF, &H10
    OUT &H3CE, 6: OUT &H3CF, &HE
END SUB

'FontOpen:
'  Makes the character generator memory (plane 2, segment A000h) readable
'  and writable
SUB FontOpen
    OUT &H3C4, 2: OUT &H3C5, 4
    OUT &H3C4, 4: OUT &H3C5, 7
    OUT &H3CE, 4: OUT &H3CF, 2
    OUT &H3CE, 5: OUT &H3CF, 0
    OUT &H3CE, 6: OUT &H3CF, 4
END SUB

'GlyphData$:
'  Shape (16 lines of 8 pixels) of special character number k:
'  1 egg (character 1), 2 heart (3), 3 star (4), 4 mine (15), 5 pill (5)
FUNCTION GlyphData$ (k)
    SELECT CASE k
        CASE 1
            g$ = CHR$(0) + CHR$(0) + CHR$(24) + CHR$(60) + CHR$(60) + CHR$(126) + CHR$(126) + CHR$(255)
            g$ = g$ + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(126) + CHR$(126) + CHR$(60) + CHR$(24) + CHR$(0)
        CASE 2
            g$ = CHR$(0) + CHR$(0) + CHR$(102) + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(126)
            g$ = g$ + CHR$(126) + CHR$(60) + CHR$(60) + CHR$(24) + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(0)
        CASE 3
            g$ = CHR$(0) + CHR$(24) + CHR$(24) + CHR$(66) + CHR$(36) + CHR$(24) + CHR$(165) + CHR$(90)
            g$ = g$ + CHR$(90) + CHR$(165) + CHR$(24) + CHR$(36) + CHR$(66) + CHR$(24) + CHR$(24) + CHR$(0)
        CASE 5
            g$ = CHR$(0) + CHR$(0) + CHR$(60) + CHR$(126) + CHR$(126) + CHR$(126) + CHR$(126) + CHR$(126)
            g$ = g$ + CHR$(0) + CHR$(126) + CHR$(126) + CHR$(126) + CHR$(126) + CHR$(126) + CHR$(60) + CHR$(0)
        CASE ELSE
            g$ = CHR$(0) + CHR$(0) + CHR$(3) + CHR$(4) + CHR$(8) + CHR$(8) + CHR$(60) + CHR$(126)
            g$ = g$ + CHR$(223) + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(126) + CHR$(60) + CHR$(0) + CHR$(0)
    END SELECT
    GlyphData$ = g$
END FUNCTION

'ItemInRect:
'  TRUE if an egg, bonus, heart, pill or mine sits inside the text cell rectangle
FUNCTION ItemInRect (r1, c1, r2, c2)
    ItemInRect = TRUE
    FOR e = 1 TO eggTotal
        IF eggRow(e) >= r1 AND eggRow(e) <= r2 AND eggCol(e) >= c1 AND eggCol(e) <= c2 THEN EXIT FUNCTION
    NEXT e
    IF bonOn THEN
        IF bonRow >= r1 AND bonRow <= r2 AND bonCol >= c1 AND bonCol <= c2 THEN EXIT FUNCTION
    END IF
    IF heartOn THEN
        IF heartRow >= r1 AND heartRow <= r2 AND heartCol >= c1 AND heartCol <= c2 THEN EXIT FUNCTION
    END IF
    IF pillOn THEN
        IF pillRow >= r1 AND pillRow <= r2 AND pillCol >= c1 AND pillCol <= c2 THEN EXIT FUNCTION
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            IF minRow(m) >= r1 AND minRow(m) <= r2 AND minCol(m) >= c1 AND minCol(m) <= c2 THEN EXIT FUNCTION
        END IF
    NEXT m
    FOR m = 1 TO fxCount
        IF fxRow(m) >= r1 AND fxRow(m) <= r2 AND fxCol(m) >= c1 AND fxCol(m) <= c2 THEN EXIT FUNCTION
    NEXT m
    ItemInRect = FALSE
END FUNCTION

'DoorsActive:
'  TRUE if side doors are used on this level: always on the divided levels,
'  otherwise when the Doors setting is ON and the level is in band DOORFIRSTBAND or later
FUNCTION DoorsActive
    DoorsActive = (splitLevel OR (doorsOn AND LevelBand >= DOORFIRSTBAND))
END FUNCTION

'LevelBand:
'  Band of the level, 0 to LVBANDS - 1: the play order cut into equal parts
FUNCTION LevelBand
    LevelBand = ((LevelNo - 1) * LVBANDS) \ numLevels
END FUNCTION

'LevelNo:
'  Number of the level in the play order, 1 to numLevels (curLevel keeps
'  counting in ENDLESS mode, this number starts again at 1)
FUNCTION LevelNo
    LevelNo = ((curLevel - 1) MOD numLevels) + 1
END FUNCTION

'LevelFileInit:
'  Checks the level file and gets the number of levels (numLevels);
'  FALSE if the file is missing or does not fit
FUNCTION LevelFileInit
    LevelFileInit = FALSE
    numLevels = 0
    fileFail = FALSE
    fileBusy = TRUE
    OPEN LEVELFILE FOR INPUT AS #1               'fails if the file is missing
    IF NOT fileFail THEN
        CLOSE #1
        OPEN LEVELFILE FOR BINARY ACCESS READ AS #1
        IF NOT fileFail THEN
            hd$ = SPACE$(16)
            GET #1, 1, hd$
            IF NOT fileFail THEN
                n = ASC(MID$(hd$, 6, 1))
                IF LEFT$(hd$, 4) = "NBLV" AND ASC(MID$(hd$, 5, 1)) = 1 AND n >= 1 THEN
                    IF LOF(1) = 16& + n * CLNG(LEVELREC) THEN
                        numLevels = n
                        LevelFileInit = TRUE
                    END IF
                END IF
            END IF
            CLOSE #1
        END IF
    END IF
    fileBusy = FALSE
END FUNCTION

'LoadLevelRec:
'  Reads the record of level k (1 to numLevels) from the level file into rec$,
'  which has to be LEVELREC characters long.  If the file cannot be read, an
'  empty arena is returned.
SUB LoadLevelRec (k, rec$)
    fileFail = FALSE
    fileBusy = TRUE
    OPEN LEVELFILE FOR BINARY ACCESS READ AS #1
    IF NOT fileFail THEN
        GET #1, 17& + CLNG(k - 1) * LEVELREC, rec$
        CLOSE #1
    END IF
    fileBusy = FALSE
    IF fileFail THEN
        rec$ = STRING$(LEVELREC, 0)
        MID$(rec$, 2, 6) = CHR$(25) + CHR$(50) + CHR$(4) + CHR$(25) + CHR$(30) + CHR$(3)
    END IF
END SUB

'LoadConfig:
'  Reads names and menu settings from NIBBLES.CFG
SUB LoadConfig
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.CFG" FOR APPEND AS #1      'creates the file if missing
    CLOSE #1
    IF NOT fileFail THEN
        OPEN "NIBBLES.CFG" FOR INPUT AS #1
        IF NOT fileFail THEN
            IF NOT EOF(1) THEN
                INPUT #1, n1$, n2$, NP, sp, su, sl, th, so, mo
                IF NOT fileFail THEN
                    nm$(1) = CleanName$(n1$, "SAMMY")
                    nm$(2) = CleanName$(n2$, "JAKE")
                    IF NP = 1 OR NP = 2 THEN numPlayers = NP
                    IF sp >= 1 AND sp <= 10 THEN speedSet = sp
                    speedUp = (su <> 0)
                    IF sl >= 1 AND sl <= numLevels THEN startLevel = sl
                    IF th >= 1 AND th <= 5 THEN theme = th
                    soundOn = (so <> 0)
                    IF mo >= 1 AND mo <= 4 THEN
                        mineMode = mo
                    ELSEIF mo <> 0 THEN
                        mineMode = 4
                    ELSE
                        mineMode = 1
                    END IF
                    IF NOT EOF(1) THEN
                        INPUT #1, dr
                        IF NOT fileFail THEN doorsOn = (dr <> 0)
                    END IF
                    IF NOT EOF(1) THEN
                        INPUT #1, ws, em
                        IF NOT fileFail THEN
                            wallStone = (ws <> 0)
                            IF em = 2 THEN endMode = 2 ELSE endMode = 1
                        END IF
                    END IF
                END IF
            END IF
            CLOSE #1
        END IF
    END IF
    fileBusy = FALSE
END SUB

'LoadGlyphs:
'  Redefines the characters of the egg, heart, star, mine and pill as filled
'  shapes (8 x 16 pixels).  Everything is read back; if the video card does
'  not accept the new shapes the old ones are put back and the normal
'  characters (hollow circle for the egg) stay in use.
SUB LoadGlyphs
    IF vidSeg <> &HB800& THEN EXIT SUB
    gCode(1) = EGGGLYPH: gCode(2) = 3: gCode(3) = 4: gCode(4) = 15: gCode(5) = 5
    FOR k = 1 TO 5
        gNew$(k) = GlyphData$(k)
    NEXT k
    ok = TRUE
    FontOpen
    DEF SEG = &HA000&
    FOR k = 1 TO 5
        ofs = gCode(k) * 32
        old$ = ""
        FOR i = 0 TO 15
            old$ = old$ + CHR$(PEEK(ofs + i))
        NEXT i
        gOld$(k) = old$
        FOR i = 0 TO 15
            POKE ofs + i, ASC(MID$(gNew$(k), i + 1, 1))
        NEXT i
        FOR i = 0 TO 15
            IF PEEK(ofs + i) <> ASC(MID$(gNew$(k), i + 1, 1)) THEN ok = FALSE
        NEXT i
    NEXT k
    IF NOT ok THEN
        FOR k = 1 TO 5
            ofs = gCode(k) * 32
            FOR i = 0 TO 15
                POKE ofs + i, ASC(MID$(gOld$(k), i + 1, 1))
            NEXT i
        NEXT k
    END IF
    DEF SEG
    FontClose
    IF ok THEN
        eggChr = EGGGLYPH
        glyphsOn = TRUE
    END IF
END SUB

'LoadHigh:
'  Reads the high score table from NIBBLES.HI (old files hold one score)
SUB LoadHigh
    hsCount = 0
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.HI" FOR APPEND AS #1       'creates the file if missing
    CLOSE #1
    IF NOT fileFail THEN
        OPEN "NIBBLES.HI" FOR INPUT AS #1
        IF NOT fileFail THEN
            IF NOT EOF(1) THEN
                INPUT #1, t$
                IF t$ = "NIB6" THEN
                    DO WHILE NOT EOF(1) AND hsCount < 10
                        INPUT #1, n$, sc&, lv
                        IF fileFail THEN EXIT DO
                        hsCount = hsCount + 1
                        hsName$(hsCount) = CleanName$(n$, "?")
                        hsScore(hsCount) = sc&
                        hsLevel(hsCount) = lv
                    LOOP
                ELSE
                    sc& = VAL(t$)
                    n$ = ""
                    IF NOT EOF(1) THEN INPUT #1, n$
                    IF sc& > 0 THEN
                        hsCount = 1
                        hsName$(1) = CleanName$(n$, "?")
                        hsScore(1) = sc&
                        hsLevel(1) = 1
                    END IF
                END IF
            END IF
            CLOSE #1
        END IF
    END IF
    fileBusy = FALSE
    IF hsCount > 0 THEN
        highScore = hsScore(1)
        hiName$ = hsName$(1)
    ELSE
        highScore = 0
        hiName$ = ""
    END IF
END SUB

'MineBoom:
'  Explosion on the text cell (rr, cc) where a snake hit a mine: a short
'  flash in the cell and 16 sparks that fly out in all directions, slow
'  down and change colour (white, yellow, red, dark red, grey).  Every
'  spark is a text character that gets smaller as it cools down: * then +
'  then a small dot.  Only the screen is changed, not arena(); the
'  playfield is redrawn at the end.  The sound is played in
'  the background, so the timing is the same with and without sound.
SUB MineBoom (rr, cc)
    CONST NP = 16
    DIM x(1 TO NP) AS SINGLE, y(1 TO NP) AS SINGLE
    DIM vx(1 TO NP) AS SINGLE, vy(1 TO NP) AS SINGLE
    DIM ox(1 TO NP), oy(1 TO NP)
    DIM ang AS SINGLE, sp AS SINGLE

    Sfx 10
    FOR m = 1 TO fxCount                        'a fixed mine that explodes is not drawn again
        IF fxRow(m) = rr AND fxCol(m) = cc THEN fxGone(m) = TRUE
    NEXT m
    FOR i = 1 TO NP
        ang = RND * 6.2832
        sp = 1.2 + RND * 2
        vx(i) = COS(ang) * sp
        vy(i) = SIN(ang) * sp
        x(i) = cc
        y(i) = rr * 2 - 1 + INT(RND * 2)
        ox(i) = 0
        oy(i) = 0
    NEXT i

    FOR f = 0 TO 10
        'erase the sparks of the last frame
        FOR i = 1 TO NP
            IF ox(i) > 0 THEN
                rw = (oy(i) + 1) \ 2
                DrawCell rw, ox(i)
                ox(i) = 0
            END IF
        NEXT i

        'flash in the cell of the mine
        SELECT CASE f
            CASE 0: PutChar rr, cc, 219, 15
            CASE 1: PutChar rr, cc, 219, 14
            CASE 2: PutChar rr, cc, 178, 12 + pal(4) * 16
            CASE 3: DrawCell rr, cc
        END SELECT

        'colour of this frame
        SELECT CASE f
            CASE 0, 1: pc = 15
            CASE 2, 3: pc = 14
            CASE 4, 5, 6: pc = 12
            CASE 7, 8: pc = 4
            CASE ELSE: pc = 8
        END SELECT

        'character of this frame: the sparks get smaller as they cool down
        SELECT CASE f
            CASE 0 TO 2: sch = 42                   '*
            CASE 3 TO 6: sch = 43                   '+
            CASE ELSE: sch = 250                    'small dot
        END SELECT

        'move and draw the sparks
        FOR i = 1 TO NP
            x(i) = x(i) + vx(i)
            y(i) = y(i) + vy(i)
            vx(i) = vx(i) * .86
            vy(i) = vy(i) * .86
            px = INT(x(i) + .5)
            py = INT(y(i) + .5)
            IF px >= 1 AND px <= 80 AND py >= 3 AND py <= 50 THEN
                rw = (py + 1) \ 2
                PutChar rw, px, sch, pc + pal(4) * 16
                ox(i) = px
                oy(i) = py
            END IF
        NEXT i
        DelayMs 75
    NEXT f
    RedrawRows 2, 25
END SUB

'MineSpotOk:
'  TRUE if a fixed mine may be placed on text cell (r, c): free, open
'  space around it, far from the snake heads, not next to another mine
FUNCTION MineSpotOk (r, c)
    MineSpotOk = FALSE
    IF r < 2 OR r > 25 OR c < 2 OR c > 79 THEN EXIT FUNCTION
    IF CellBusy(r, c) THEN EXIT FUNCTION
    FOR pr = r * 2 - 3 TO r * 2 + 2
        FOR px = c - 2 TO c + 2
            IF pr < 3 OR pr > 50 OR px < 1 OR px > 80 THEN EXIT FUNCTION
            IF arena(pr, px) <> pal(4) THEN EXIT FUNCTION
        NEXT px
    NEXT pr
    FOR a = 1 TO numPlayers
        SnakeDist r, c, a, dx, dy
        IF dx <= 10 AND dy <= 10 THEN EXIT FUNCTION
    NEXT a
    FOR k = 1 TO fxCount
        IF ABS(c - fxCol(k)) <= 3 AND ABS(r - fxRow(k)) <= 2 THEN EXIT FUNCTION
    NEXT k
    MineSpotOk = TRUE
END FUNCTION

'PlaceEggs:
'  Scatters the eggs of a level (not near the snakes, not on items)
SUB PlaceEggs
    eggTotal = EGGSTART + EGGSTEP * LevelBand
    IF eggTotal > MAXEGG THEN eggTotal = MAXEGG
    eggLeft = eggTotal
    FOR e = 1 TO MAXEGG
        eggRow(e) = 0
        eggCol(e) = 0
    NEXT e
    FOR e = 1 TO eggTotal
        IF deferDraw THEN PollWait
        FOR attempt = 1 TO 40
            FindCell r, c, found
            IF NOT found THEN EXIT FOR                'no free cell at all (cannot really happen)
            okFar = TRUE
            FOR a = 1 TO numPlayers
                SnakeDist r, c, a, dx, dy
                IF dx <= 8 AND dy <= 8 THEN okFar = FALSE
            NEXT a
            IF okFar THEN EXIT FOR
        NEXT attempt
        eggRow(e) = r
        eggCol(e) = c
    NEXT e
END SUB

'PlaceFixedMines:
'  Puts the permanent mines of a level (menu modes FIXED and BOTH).  With
'  two players they come in point symmetric pairs.  Afterwards a path
'  search checks that every egg can still be reached.
SUB PlaceFixedMines
    fxCount = 0
    IF mineMode < 3 THEN EXIT SUB
    want = LevelNo \ 2
    IF want > 6 THEN want = 6
    IF want < 1 THEN EXIT SUB
    IF numPlayers = 2 THEN want = ((want + 1) \ 2) * 2

    FOR attempt = 1 TO 3
        IF deferDraw THEN PollWait
        fxCount = 0
        bfsFresh = FALSE                          'the last path search may still count removed mines
        tries = 0
        DO WHILE fxCount < want AND tries < 200
            tries = tries + 1
            FindCell r, c, found
            IF NOT found THEN EXIT DO
            IF MineSpotOk(r, c) THEN
                fxCount = fxCount + 1
                fxRow(fxCount) = r
                fxCol(fxCount) = c
                IF numPlayers = 2 THEN
                    r2 = 27 - r
                    c2 = 81 - c
                    IF MineSpotOk(r2, c2) THEN
                        fxCount = fxCount + 1
                        fxRow(fxCount) = r2
                        fxCol(fxCount) = c2
                    ELSE
                        fxCount = fxCount - 1
                    END IF
                END IF
            END IF
        LOOP
        IF fxCount = 0 THEN EXIT SUB
        RunBfs TRUE
        IF EggsReachable THEN EXIT SUB
    NEXT attempt
    fxCount = 0
    bfsFresh = FALSE
END SUB

'PlayNibbles:
'  Plays one complete game
SUB PlayNibbles
    abortGame = FALSE
    newHigh = FALSE
    victory = FALSE
    rankOf(1) = 0
    rankOf(2) = 0
    tickCnt = 0
    godMode = FALSE
    cheated = FALSE
    FOR m = 1 TO MAXFIX
        fxGone(m) = FALSE
    NEXT m
    FOR a = 1 TO 2
        sammy(a).lives = 5
        sammy(a).score = 0
    NEXT a

    ClearScreen pal(4) * 16 + 7
    ShowWait
    Level STARTOVER
    DrawHud
    Dialog "L E V E L" + STR$(curLevel), "Collect" + STR$(eggTotal) + " eggs", "Press SPACE to start"
    IF NOT abortGame THEN Sfx 1                  'no round start sound when quitting to the menu

    gameOver = FALSE
    DO
        IF abortGame THEN EXIT DO                'ESC in a message box
        'speed of this level
        stepMs = 180 - speedSet * 16
        IF speedUp THEN stepMs = INT(stepMs * .93 ^ (curLevel - startLevel))
        IF stepMs < 8 THEN stepMs = 8
        DoorReset

        bonOn = FALSE
        pillWait = 0
        hitMine(1) = FALSE
        hitMine(2) = FALSE
        anyDead = FALSE
        levelDone = FALSE

        DO
            DelayMs stepMs
            ReadKeys
            IF abortGame THEN EXIT DO
            Tick
        LOOP UNTIL anyDead OR levelDone
        IF abortGame THEN EXIT DO

        IF anyDead THEN
            boom = FALSE
            FOR a = 1 TO numPlayers
                IF hitMine(a) THEN boom = TRUE
            NEXT a
            IF NOT boom THEN Sfx 3                    'a mine has its own sound
            FOR a = 1 TO numPlayers
                IF NOT sammy(a).alive THEN sammy(a).lives = sammy(a).lives - 1
            NEXT a
            FOR a = 1 TO numPlayers
                IF hitMine(a) THEN MineBoom mineHitRow(a), mineHitCol(a)
            NEXT a
            variant = INT(RND * 3) + 1
            FOR a = 1 TO numPlayers
                IF NOT sammy(a).alive THEN DeathAnim a, variant
            NEXT a
            FOR a = 1 TO numPlayers
                EraseSnake a
            NEXT a
            bonOn = FALSE
            pillOn = FALSE
            pillWait = 0
            heartOn = FALSE
            FOR m = 1 TO MAXMINE
                minTime(m) = 0
            NEXT m
            RedrawRows 2, 25
            DrawHud

            IF numPlayers = 2 AND NOT sammy(1).alive AND NOT sammy(2).alive THEN
                msg$ = "BOTH SNAKES CRASHED!"
            ELSE
                who = 1
                IF sammy(1).alive THEN who = 2
                IF hitMine(who) THEN
                    msg$ = nm$(who) + " HIT A MINE!"
                ELSE
                    msg$ = nm$(who) + " CRASHED!"
                END IF
            END IF

            gameOver = FALSE
            FOR a = 1 TO numPlayers
                IF sammy(a).lives <= 0 THEN gameOver = TRUE
            NEXT a

            IF gameOver THEN
                Dialog msg$, "No lives left!", "Press SPACE"
            ELSE
                prepWhat = SAMELEVEL                  'the arena is built behind the message
                Dialog msg$, "Collect" + STR$(eggTotal) + " eggs", "Press SPACE to continue"
                IF NOT abortGame THEN
                    DrawHud
                    DelayMs 300
                END IF
            END IF
        ELSE
            'level completed
            Sfx 4
            FOR a = 1 TO numPlayers
                AddScore a, 500
            NEXT a
            DrawHud
            IF endMode = 1 AND curLevel >= numLevels THEN
                'the last level is done: life bonus and the end of the game
                FOR a = 1 TO numPlayers
                    AddScore a, sammy(a).lives * 1000
                NEXT a
                DrawHud
                victory = TRUE
                gameOver = TRUE
                dlgBg = 2                             'dark green window
                Dialog "ALL" + STR$(numLevels) + " LEVELS COMPLETE!", "Life bonus: 1000 per life", "Press SPACE"
                dlgBg = 0
            ELSE
                prepWhat = NEXTLEVEL                  'the next level is built behind the message
                dlgBg = 2                             'dark green window
                Dialog "LEVEL COMPLETE!", "Bonus +500 points", "Press SPACE"
                dlgBg = 0
                IF abortGame THEN EXIT DO
                DrawHud
                Dialog "L E V E L" + STR$(curLevel), "Collect" + STR$(eggTotal) + " eggs", "Press SPACE to start"
            END IF
        END IF
    LOOP UNTIL gameOver

    'enter the scores in the high score table
    IF NOT cheated THEN
        FOR a = 1 TO numPlayers
            rankOf(a) = AddToTable(nm$(a), sammy(a).score, curLevel)
        NEXT a
    END IF
    newHigh = (rankOf(1) = 1 OR rankOf(2) = 1)
    IF rankOf(1) > 0 OR rankOf(2) > 0 THEN SaveHigh
    IF hsCount > 0 THEN
        highScore = hsScore(1)
        hiName$ = hsName$(1)
    END IF
END SUB

'PointIsThere:
'  TRUE if the pixel is not empty (wall or snake)
FUNCTION PointIsThere (row, col)
    IF row < 1 OR row > 50 OR col < 1 OR col > 80 THEN
        PointIsThere = TRUE
    ELSE
        PointIsThere = (arena(row, col) <> pal(4))
    END IF
END FUNCTION

'PrepareHeart:
'  Called when the arena is ready.  Picks, near each of the four corners (at
'  most 3 pixels away), the closest free place the snakes can reach.  The path
'  length from the start to each place comes from the path search of the arena
'  (done anyway for the eggs and mines; it is run again only if needed).
'  Nothing else is calculated, so building the arena is not slower.
SUB PrepareHeart
    hcN = 0
    IF splitLevel OR NOT bfsFresh THEN RunBfs FALSE
    bfsFresh = FALSE
    FOR k = 1 TO 4
        SELECT CASE k
            CASE 1: r0 = 3: c0 = 2: dr = 1: dc = 1
            CASE 2: r0 = 3: c0 = 79: dr = 1: dc = -1
            CASE 3: r0 = 24: c0 = 2: dr = -1: dc = 1
            CASE ELSE: r0 = 24: c0 = 79: dr = -1: dc = -1
        END SELECT
        bestS = 99
        br = 0
        bc = 0
        FOR i = 0 TO 1                        'text rows from the corner (2 pixels each)
            FOR j = 0 TO 3                    'columns from the corner
                rr = r0 + i * dr
                cc = c0 + j * dc
                s = j + i * 2
                IF s < bestS THEN
                    p = (rr * 2 - 2) * 80 + cc - 1
                    IF bfsD(p) >= 0 AND bfsD(p + 80) >= 0 THEN
                        IF NOT CellBusy(rr, cc) THEN
                            bestS = s
                            br = rr
                            bc = cc
                        END IF
                    END IF
                END IF
            NEXT j
        NEXT i
        IF br > 0 THEN
            hcN = hcN + 1
            hcRow(hcN) = br
            hcCol(hcN) = bc
            p = (br * 2 - 2) * 80 + bc - 1
            pl = bfsD(p)
            IF bfsD(p + 80) < pl THEN pl = bfsD(p + 80)
            mn = 32000
            FOR a = 1 TO numPlayers
                IF sammy(a).alive THEN
                    SnakeDist br, bc, a, dx, dy
                    IF dx + dy < mn THEN mn = dx + dy
                END IF
            NEXT a
            IF mn < 1 THEN mn = 1
            rt& = (pl * 16&) \ mn
            IF rt& < 16 THEN rt& = 16
            IF rt& > 160 THEN rt& = 160
            hcRat(hcN) = rt&
        END IF
    NEXT k
END SUB

'PrepareDoors:
'  Called when a level is built (after the eggs, the fixed mines and the heart
'  places are known).  Picks up to DOORCAND door rows that do not overlap, so
'  that the game only has to choose one of them.  The lanes of these rows stay
'  free of items and mines.  dcN = 0 when doors are not used on this level.
SUB PrepareDoors
    DIM ord(0 TO 18)
    dcN = 0
    IF NOT DoorsActive THEN EXIT SUB
    FOR i = 0 TO 18
        ord(i) = i + 3
    NEXT i
    FOR i = 18 TO 1 STEP -1                     'shuffle the rows 3 to 21
        j = INT(RND * (i + 1))
        t = ord(i): ord(i) = ord(j): ord(j) = t
    NEXT i
    FOR i = 0 TO 18
        r = ord(i)
        ok = DoorRowOk(r)
        FOR k = 1 TO dcN
            IF ABS(r - dcRow(k)) < 4 THEN ok = FALSE     'lanes must not overlap
        NEXT k
        IF ok THEN
            dcN = dcN + 1
            dcRow(dcN) = r
            IF dcN >= DOORCAND THEN EXIT FOR
        END IF
    NEXT i
END SUB

'PrepareMines:
'  Called when a level is built, after PrepareHeart (it uses the path search
'  result of that call) and PrepareDoors.  Collects up to MINECAND places for
'  the random mines: free cells with empty surroundings, away from the fixed
'  mines and the door lanes, and reachable by a snake.  SpawnMine only has to
'  choose one that is far enough from the snakes.
SUB PrepareMines
    mcN = 0
    IF mineMode <> 2 AND mineMode <> 4 THEN EXIT SUB
    tries = 0
    DO WHILE mcN < MINECAND AND tries < 300
        tries = tries + 1
        r = INT(RND * 24) + 2
        c = INT(RND * 78) + 2
        ok = TRUE
        FOR pr = r * 2 - 3 TO r * 2 + 2             'the surroundings must be empty
            IF pr < 3 OR pr > 50 THEN ok = FALSE: EXIT FOR
            FOR px = c - 2 TO c + 2
                IF px < 1 OR px > 80 THEN ok = FALSE: EXIT FOR
                IF arena(pr, px) <> pal(4) THEN ok = FALSE: EXIT FOR
            NEXT px
            IF NOT ok THEN EXIT FOR
        NEXT pr
        IF ok THEN
            IF CellBusy(r, c) THEN ok = FALSE
        END IF
        IF ok THEN
            FOR k = 1 TO fxCount                    'away from the fixed mines
                IF ABS(c - fxCol(k)) <= 5 AND ABS(r - fxRow(k)) <= 3 THEN ok = FALSE
            NEXT k
            FOR k = 1 TO dcN                        'away from the door lanes
                IF r >= dcRow(k) - 1 AND r <= dcRow(k) + 4 THEN
                    IF c <= 10 OR c >= 71 THEN ok = FALSE
                END IF
            NEXT k
        END IF
        IF ok THEN
            p = (r * 2 - 2) * 80 + c - 1
            IF bfsD(p) < 0 OR bfsD(p + 80) < 0 THEN ok = FALSE
        END IF
        IF ok THEN
            FOR k = 1 TO mcN                        'not twice the same place
                IF mcRow(k) = r AND mcCol(k) = c THEN ok = FALSE
            NEXT k
        END IF
        IF ok THEN
            mcN = mcN + 1
            mcRow(mcN) = r
            mcCol(mcN) = c
        END IF
    LOOP
END SUB

'PutHeart:
'  Shows the heart at text cell (rr, cc); d = path length to it.  The time it
'  stays is the path length plus a third plus 12 steps.
SUB PutHeart (rr, cc, d)
    heartRow = rr
    heartCol = cc
    heartMax = d + d \ 3 + 12
    heartTime = heartMax
    heartOn = TRUE
    heartDone = TRUE
    hc = 12
    PutChar heartRow, heartCol, 3, hc + pal(4) * 16
    Sfx 7
END SUB


'PollWait:
'  Called while a level is built behind a message box: looks at the keys.
'  SPACE / ENTER shows "please wait"; ESC is kept for the message box.
SUB PollWait
    DO
        k$ = INKEY$
        IF k$ = "" THEN EXIT DO
        IF k$ = " " OR k$ = CHR$(13) THEN
            IF NOT spaceHit THEN
                spaceHit = TRUE
                ShowWait
            END IF
        ELSEIF k$ = CHR$(27) THEN
            pendingEsc = TRUE
        END IF
    LOOP
END SUB

'PutPixel:
'  Sets a pixel of the 80 x 50 playfield and redraws its text character
SUB PutPixel (row, col, c)
    IF row < 3 OR row > 50 OR col < 1 OR col > 80 THEN EXIT SUB
    arena(row, col) = c
    rr = (row + 1) \ 2
    DrawCell rr, col
END SUB

'QueueTurn:
'  Stores a turn (up to 3 in advance); reversing is not allowed
SUB QueueTurn (who, d)
    IF who < 1 OR who > numPlayers THEN EXIT SUB
    IF qn(who) > 0 THEN ref = qd(who, qn(who)) ELSE ref = sammy(who).lastDir
    IF d = ref THEN EXIT SUB
    IF d = (((ref - 1) XOR 1) + 1) THEN EXIT SUB
    IF qn(who) < 3 THEN
        qn(who) = qn(who) + 1
        qd(who, qn(who)) = d
    END IF
END SUB

'ReadKeys:
'  Reads all waiting keys: steering, pause and quit
SUB ReadKeys
    DO
        k$ = INKEY$
        IF k$ = "" THEN EXIT DO
        SELECT CASE k$
            CASE CHR$(0) + "H", "8"
                QueueTurn 1, 1
            CASE CHR$(0) + "P", "2"
                QueueTurn 1, 2
            CASE CHR$(0) + "K", "4"
                QueueTurn 1, 3
            CASE CHR$(0) + "M", "6"
                QueueTurn 1, 4
            CASE "w", "W"
                QueueTurn numPlayers, 1
            CASE "s", "S"
                QueueTurn numPlayers, 2
            CASE "a", "A"
                QueueTurn numPlayers, 3
            CASE "d", "D"
                QueueTurn numPlayers, 4
            CASE "p", "P"
                Dialog "G A M E   P A U S E D", "", "Press SPACE to continue"
                IF abortGame THEN EXIT DO
            CASE CHR$(7)                             'Ctrl+G: hidden immortality switch (test only)
                godMode = NOT godMode
                IF godMode THEN cheated = TRUE
                IF soundOn THEN
                    IF godMode THEN PLAY "MBMNT255O4L64CEG" ELSE PLAY "MBMNT255O4L64GEC"
                END IF
            CASE CHR$(27)
                IF AskYesNo("Quit to the menu?") THEN
                    variant = INT(RND * 3) + 1         'the living snakes die, no life is lost
                    FOR a = 1 TO numPlayers
                        IF sammy(a).alive THEN DeathAnim a, variant
                    NEXT a
                    abortGame = TRUE
                    EXIT DO
                END IF
        END SELECT
    LOOP
END SUB

'RedrawRows:
'  Redraws text rows r1 to r2 of the playfield (and the items)
SUB RedrawRows (r1, r2)
    DEF SEG = vidSeg
    FOR r = r1 TO r2
        pt = r * 2 - 1
        pb = r * 2
        ofs = (r - 1) * 160
        FOR c = 1 TO 80
            t = arena(pt, c)
            b = arena(pb, c)
            IF t = b THEN
                ch = 219: attr = t + (t AND 7) * 16
            ELSEIF b < 8 THEN
                ch = 223: attr = t + b * 16
            ELSEIF t < 8 THEN
                ch = 220: attr = b + t * 16
            ELSE
                ch = 223: attr = t + b * 16
            END IF
            POKE ofs, ch
            POKE ofs + 1, attr
            ofs = ofs + 2
        NEXT c
    NEXT r
    DEF SEG
    DrawItems
END SUB

'RestoreGlyphs:
'  Puts the original shapes back (at the end of the program)
SUB RestoreGlyphs
    IF NOT glyphsOn THEN EXIT SUB
    FontOpen
    DEF SEG = &HA000&
    FOR k = 1 TO 5
        ofs = gCode(k) * 32
        FOR i = 0 TO 15
            POKE ofs + i, ASC(MID$(gOld$(k), i + 1, 1))
        NEXT i
    NEXT k
    DEF SEG
    FontClose
END SUB

'RunBfs:
'  Path search from the heads of the living snakes over the empty pixels.
'  bfsD(i) for pixel (row, col), i = (row - 1) * 80 + col - 1:
'  steps from the nearest head, -1 = not reachable, -2 = blocked
'  (wall, snake, mine, status line).  With useDoors (divided levels only)
'  a path may also leave through a side door and come out on the other side.
SUB RunBfs (useDoors)
    doors = (useDoors AND splitLevel)
    FOR r = 1 TO 50
        bs = (r - 1) * 80 - 1
        FOR c = 1 TO 80
            IF arena(r, c) = pal(4) THEN bfsD(bs + c) = -1 ELSE bfsD(bs + c) = -2
        NEXT c
    NEXT r
    FOR i = 0 TO 159                          'the two status line rows
        bfsD(i) = -2
    NEXT i
    IF doors THEN
        FOR r = 5 TO 48
            bfsD((r - 1) * 80) = -1
            bfsD((r - 1) * 80 + 79) = -1
        NEXT r
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            bfsD((minRow(m) * 2 - 2) * 80 + minCol(m) - 1) = -2
            bfsD((minRow(m) * 2 - 1) * 80 + minCol(m) - 1) = -2
        END IF
    NEXT m
    FOR m = 1 TO fxCount
        bfsD((fxRow(m) * 2 - 2) * 80 + fxCol(m) - 1) = -2
        bfsD((fxRow(m) * 2 - 1) * 80 + fxCol(m) - 1) = -2
    NEXT m

    qh = 0
    qt = 0
    FOR a = 1 TO numPlayers
        IF sammy(a).alive THEN
            i = (sammy(a).row - 1) * 80 + sammy(a).col - 1
            bfsD(i) = 0
            bfsQ(qt) = i
            qt = qt + 1
        END IF
    NEXT a

    DO WHILE qh < qt
        i = bfsQ(qh)
        qh = qh + 1
        d = bfsD(i) + 1
        c = i MOD 80
        rw = i \ 80                           'row - 1
        IF c < 79 THEN
            j = i + 1
            IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
        ELSEIF doors THEN
            IF rw >= 4 AND rw <= 47 THEN
                j = i - 79
                IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
            END IF
        END IF
        IF c > 0 THEN
            j = i - 1
            IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
        ELSEIF doors THEN
            IF rw >= 4 AND rw <= 47 THEN
                j = i + 79
                IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
            END IF
        END IF
        IF i < 3920 THEN
            j = i + 80
            IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
        END IF
        IF i >= 80 THEN
            j = i - 80
            IF bfsD(j) = -1 THEN bfsD(j) = d: bfsQ(qt) = j: qt = qt + 1
        END IF
    LOOP
    bfsFresh = TRUE
END SUB

'SaveConfig:
'  Writes names and menu settings to NIBBLES.CFG
SUB SaveConfig
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.CFG" FOR OUTPUT AS #1
    IF NOT fileFail THEN
        WRITE #1, nm$(1), nm$(2), numPlayers, speedSet, speedUp, startLevel, theme, soundOn, mineMode
        WRITE #1, doorsOn
        WRITE #1, wallStone, endMode
        CLOSE #1
    END IF
    fileBusy = FALSE
END SUB

'SaveHigh:
'  Writes the high score table to NIBBLES.HI
SUB SaveHigh
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.HI" FOR OUTPUT AS #1
    IF NOT fileFail THEN
        WRITE #1, "NIB6"
        FOR i = 1 TO hsCount
            WRITE #1, hsName$(i), hsScore(i), hsLevel(i)
        NEXT i
        CLOSE #1
    END IF
    fileBusy = FALSE
END SUB

'Sfx:
'  Sound effects
SUB Sfx (n)
    IF NOT soundOn THEN EXIT SUB
    SELECT CASE n
        CASE 1: PLAY "MBMNT140O3L8GL16GL8>C<L16GL4>E"        'level start (bugle call)
        CASE 2: PLAY "MBMNT240O4L64CDEFGAB>L32C"          'number eaten (quick bubble run)
        CASE 3: PLAY "MBMNT180O3>L32C<BA-GF+FEE-DC+C"        'crash (cartoon fall)
        CASE 4: PLAY "MBMNT160O2L16CEGO3CEGO4C"          'level complete
        CASE 5: PLAY "MBMNT200O3L32EGB>CL16E"            'bonus
        CASE 7: PLAY "MBMNT180O3L16EGEGL8>C"               'heart appears (sparkle)
        CASE 8: PLAY "MBMNT180O3L16CEGB>CE"               'heart caught
        CASE 9: PLAY "MBMNT160O3L8GL4E"                    'door warning (two falling notes)
        CASE 10: PLAY "MBT255MSL64O1GFEDCO0BAGFEDCP64O2GFEDCO1BAGFEDC" 'mine explosion
        CASE 11: PLAY "MBMNT250O4L32CO3BB-AA-GG-FEL16C"   'pill eaten (chromatic slide down)
        CASE 12: PLAY "MBMNT220O4L32GEGEGE"                'pill appears (short trill)
    END SELECT
END SUB

'ShrinkSnake:
'  Takes n segments off the tail of snake a (never below the start length)
SUB ShrinkSnake (a, n)
    nl = sammy(a).length - n
    IF nl < STARTLEN THEN nl = STARTLEN
    tc = sammy(a).count - n
    IF tc < STARTLEN THEN tc = STARTLEN
    sammy(a).length = nl
    DO WHILE sammy(a).count > tc
        tl = (sammy(a).head - sammy(a).count + 1 + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
        PutPixel sammyBody(tl, a).row, sammyBody(tl, a).col, pal(4)
        sammy(a).count = sammy(a).count - 1
    LOOP
END SUB

'SnakeDist:
'  Distance of text cell (r, c) from the head of snake a: dx in columns, dy in
'  pixel rows (the nearer of the two pixels of the cell)
SUB SnakeDist (r, c, a, dx, dy)
    dx = ABS(c - sammy(a).col)
    dy = ABS(r * 2 - sammy(a).row)
    dy2 = ABS(r * 2 - 1 - sammy(a).row)
    IF dy2 < dy THEN dy = dy2
END SUB

'SpawnBonus:
'  Puts a bonus star on a free spot
SUB SpawnBonus
    FindCell r, c, found
    IF NOT found THEN EXIT SUB
    bonRow = r
    bonCol = c
    bonOn = TRUE
    bonTime = BONUSMS \ (stepMs + 10)
    PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
END SUB

'HeartSpawn:
'  The heart appears at the prepared corner place that is farthest from the
'  nearest snake (path length estimated from the straight line distance and
'  the path / straight line ratio worked out when the arena was built).  If no
'  corner place can be used, HEARTTRIES random free places are tried.  Nothing here is
'  slow, the heart is there at once.
SUB HeartSpawn
    best = -1
    bk = 0
    FOR k = 1 TO hcN
        IF arena(hcRow(k) * 2 - 1, hcCol(k)) = pal(4) AND arena(hcRow(k) * 2, hcCol(k)) = pal(4) THEN
            IF NOT CellBusy(hcRow(k), hcCol(k)) THEN
                dmin = 32000
                FOR a = 1 TO numPlayers
                    IF sammy(a).alive THEN
                        SnakeDist hcRow(k), hcCol(k), a, dx, dy
                        est = ((dx + dy) * hcRat(k)) \ 16
                        IF est < dmin THEN dmin = est
                    END IF
                NEXT a
                IF dmin < 32000 AND dmin > best THEN
                    best = dmin
                    bk = k
                END IF
            END IF
        END IF
    NEXT k
    IF bk > 0 AND best >= 6 THEN
        PutHeart hcRow(bk), hcCol(bk), best
        EXIT SUB
    END IF

    'no corner place: the farthest of HEARTTRIES random free places that can be reached
    best = -1
    br = 0
    bc = 0
    FOR t = 1 TO HEARTTRIES
        rr = 3 + INT(RND * 22)
        cc = 2 + INT(RND * 78)
        p = (rr * 2 - 2) * 80 + cc - 1
        IF bfsD(p) >= 0 AND bfsD(p + 80) >= 0 THEN
            IF arena(rr * 2 - 1, cc) = pal(4) AND arena(rr * 2, cc) = pal(4) THEN
                IF NOT CellBusy(rr, cc) THEN
                    dmin = 32000
                    FOR a = 1 TO numPlayers
                        IF sammy(a).alive THEN
                            SnakeDist rr, cc, a, dx, dy
                            est = (dx + dy) + (dx + dy) \ 4
                            IF est < dmin THEN dmin = est
                        END IF
                    NEXT a
                    IF dmin < 32000 AND dmin > best THEN
                        best = dmin
                        br = rr
                        bc = cc
                    END IF
                END IF
            END IF
        END IF
    NEXT t
    IF br > 0 AND best >= 6 THEN PutHeart br, bc, best
END SUB


'SpawnMine:
'  Puts a mine on a free spot that is not close to any snake head.  The
'  required distance grows with the game speed (about 0.7 seconds of travel).
'  The places prepared when the level was built are tried first.
SUB SpawnMine
    slot = 0
    FOR m = 1 TO MAXMINE
        IF minTime(m) <= 0 AND slot = 0 THEN slot = m
    NEXT m
    IF slot = 0 THEN EXIT SUB

    minDist = MINEAWAYMS \ stepMs
    IF minDist < 6 THEN minDist = 6
    IF minDist > 30 THEN minDist = 30

    'first choice: the prepared places, starting at a random one
    IF mcN > 0 THEN
        k0 = INT(RND * mcN)
        FOR i = 0 TO mcN - 1
            k = ((k0 + i) MOD mcN) + 1
            r = mcRow(k)
            c = mcCol(k)
            okFar = (arena(r * 2 - 1, c) = pal(4)) AND (arena(r * 2, c) = pal(4))
            IF okFar THEN okFar = NOT CellBusy(r, c)
            FOR a = 1 TO numPlayers
                SnakeDist r, c, a, dx, dy
                IF dx <= minDist AND dy <= minDist THEN okFar = FALSE
            NEXT a
            IF okFar THEN
                minRow(slot) = r
                minCol(slot) = c
                minTime(slot) = MINELIFEMS \ (stepMs + 10)
                PutChar r, c, MINECHAR, pal(15) + pal(4) * 16
                EXIT SUB
            END IF
        NEXT i
    END IF

    'back-up (tight levels, no prepared place far enough): search at random
    FOR attempt = 1 TO 60
        FindCell r, c, found
        IF NOT found THEN EXIT SUB
        okFar = (arena(r * 2 - 1, c) = pal(4)) AND (arena(r * 2, c) = pal(4))
        FOR a = 1 TO numPlayers
            SnakeDist r, c, a, dx, dy
            IF dx <= minDist AND dy <= minDist THEN okFar = FALSE
        NEXT a
        IF okFar THEN
            minRow(slot) = r
            minCol(slot) = c
            minTime(slot) = MINELIFEMS \ (stepMs + 10)
            PutChar r, c, MINECHAR, pal(15) + pal(4) * 16
            EXIT SUB
        END IF
    NEXT attempt
END SUB

'SpawnPill:
'  Puts a pill on a free spot (one pill for every PILLEGGS eggs of a level, none in the early levels)
SUB SpawnPill
    FindCell r, c, found
    IF NOT found THEN EXIT SUB
    pillRow = r
    pillCol = c
    pillClr = 11
    IF pal(4) = 3 THEN pillClr = 13           'light cyan would vanish on cyan
    pillOn = TRUE
    pillCnt = pillCnt + 1
    pillTime = PILLMS \ (stepMs + 10)
    PutChar pillRow, pillCol, 5, pillClr + pal(4) * 16
    Sfx 12
END SUB

'Tick:
'  One step of the game: timers, move all snakes, collisions, eating
SUB Tick
    tickCnt = (tickCnt + 1) AND 255
    IF (tickCnt AND 3) = 0 THEN BlinkHud
    IF DoorsActive THEN DoorTick

    'the bonus star flashes and disappears after a while
    IF bonOn THEN
        bonTime = bonTime - 1
        IF bonTime <= 0 THEN
            bonOn = FALSE
            DrawCell bonRow, bonCol
        ELSEIF (bonTime AND 3) = 0 THEN
            IF (bonTime AND 4) = 0 THEN fc = pal(10) ELSE fc = pal(9)
            PutChar bonRow, bonCol, 4, fc + pal(4) * 16
        END IF
    END IF

    'the pill: wait for its random moment, then it flashes like the star
    IF pillWait > 0 THEN
        pillWait = pillWait - 1
        IF pillWait = 0 THEN SpawnPill
    END IF
    IF pillOn THEN
        pillTime = pillTime - 1
        IF pillTime <= 0 THEN
            pillOn = FALSE
            DrawCell pillRow, pillCol
        ELSEIF (pillTime AND 3) = 0 THEN
            IF (pillTime AND 4) = 0 THEN fc = pillClr ELSE fc = 15
            PutChar pillRow, pillCol, 5, fc + pal(4) * 16
        END IF
    END IF

    'mines stay steady and disappear after a while
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            minTime(m) = minTime(m) - 1
            IF minTime(m) = 0 THEN DrawCell minRow(m), minCol(m)
        END IF
    NEXT m

    'the heart flashes faster and faster, then it is gone
    IF heartOn THEN
        heartTime = heartTime - 1
        IF heartTime <= 0 THEN
            heartOn = FALSE
            DrawCell heartRow, heartCol
        ELSE
            IF heartTime * 4 < heartMax THEN
                hs = 1
            ELSEIF heartTime * 2 < heartMax THEN
                hs = 2
            ELSE
                hs = 4
            END IF
            hc = 12
            fc = pal(9)
            IF (heartTime \ hs) AND 1 THEN fc = hc
            PutChar heartRow, heartCol, 3, fc + pal(4) * 16
        END IF
    END IF

    'phase 1: every snake takes its next buffered turn and moves its head
    FOR a = 1 TO numPlayers
        IF qn(a) > 0 THEN
            sammy(a).direction = qd(a, 1)
            qd(a, 1) = qd(a, 2)
            qd(a, 2) = qd(a, 3)
            qn(a) = qn(a) - 1
        END IF
        sammy(a).lastDir = sammy(a).direction
        SELECT CASE sammy(a).direction
            CASE 1: sammy(a).row = sammy(a).row - 1
            CASE 2: sammy(a).row = sammy(a).row + 1
            CASE 3: sammy(a).col = sammy(a).col - 1
            CASE ELSE: sammy(a).col = sammy(a).col + 1
        END SELECT
        'through an open side door to the other side of the arena
        IF sammy(a).col < 1 THEN
            IF DoorPass(sammy(a).row) THEN sammy(a).col = 80
        ELSEIF sammy(a).col > 80 THEN
            IF DoorPass(sammy(a).row) THEN sammy(a).col = 1
        END IF
    NEXT a

    'phase 2: collisions, drawing, eating
    FOR a = 1 TO numPlayers
        r = sammy(a).row
        c = sammy(a).col
        dead = PointIsThere(r, c)
        IF numPlayers = 2 THEN
            IF sammy(1).row = sammy(2).row AND sammy(1).col = sammy(2).col THEN dead = TRUE
        END IF
        rr = (r + 1) \ 2
        FOR m = 1 TO MAXMINE
            IF minTime(m) > 0 THEN
                IF minRow(m) = rr AND minCol(m) = c AND NOT godMode THEN
                    dead = TRUE
                    hitMine(a) = TRUE
                    mineHitRow(a) = rr
                    mineHitCol(a) = c
                    minTime(m) = 0
                    DrawCell minRow(m), minCol(m)
                END IF
            END IF
        NEXT m
        FOR m = 1 TO fxCount
            IF fxRow(m) = rr AND fxCol(m) = c AND NOT godMode THEN
                dead = TRUE
                hitMine(a) = TRUE
                mineHitRow(a) = rr
                mineHitCol(a) = c
            END IF
        NEXT m

        IF dead THEN
            IF godMode THEN
                'immortal: the snake stays on its cell until the player turns
                hd = sammy(a).head
                sammy(a).row = sammyBody(hd, a).row
                sammy(a).col = sammyBody(hd, a).col
            ELSE
                sammy(a).alive = FALSE
                anyDead = TRUE
            END IF
        ELSE
            'old head becomes body: the parts right behind the head are dark and plain
            hd = sammy(a).head
            PutPixel sammyBody(hd, a).row, sammyBody(hd, a).col, pal(12 + a)
            IF sammy(a).count > NECKLEN THEN
                nk = (hd - NECKLEN + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
                PutPixel sammyBody(nk, a).row, sammyBody(nk, a).col, BodyColor(a, nk)
            END IF
            'new head
            hd = (hd + 1) MOD MAXSNAKELENGTH
            sammy(a).head = hd
            sammyBody(hd, a).row = r
            sammyBody(hd, a).col = c
            sammy(a).count = sammy(a).count + 1
            PutPixel r, c, pal(6 + a)
            'erase the tail when the snake is long enough
            IF sammy(a).count > sammy(a).length THEN
                tl = (hd - sammy(a).count + 1 + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
                PutPixel sammyBody(tl, a).row, sammyBody(tl, a).col, pal(4)
                sammy(a).count = sammy(a).count - 1
            END IF

            'did the head reach an egg, the bonus or the heart?
            FOR e = 1 TO eggTotal
                IF eggRow(e) = rr AND eggCol(e) = c THEN
                    eggRow(e) = 0
                    Sfx 2
                    IF sammy(a).length < MAXSNAKELENGTH - 60 THEN
                        sammy(a).length = sammy(a).length + 3
                    END IF
                    AddScore a, 100
                    eggLeft = eggLeft - 1
                    IF eggLeft <= 0 THEN
                        levelDone = TRUE
                    ELSE
                        IF NOT bonOn THEN
                            IF INT(RND * 3) = 0 THEN SpawnBonus
                        END IF
                        'the 1st pill comes 2 to 12 seconds after the 3rd egg; a level has one
                        'pill for every PILLEGGS eggs, the others come when 1/2, 2/3 ... of the
                        'eggs are eaten, once the pill before is gone; no pills in the early bands
                        pillMax = (eggTotal + PILLEGGS - 1) \ PILLEGGS
                        IF LevelBand < PILLFIRSTBAND THEN pillMax = 0
                        IF pillCnt < pillMax AND pillWait = 0 AND NOT pillOn THEN
                            IF pillCnt = 0 THEN need = 3 ELSE need = pillCnt * eggTotal \ pillMax
                            IF eggTotal - eggLeft >= need THEN
                                pillWait = PILLDELAYMS \ (stepMs + 10) + INT(RND * (PILLDELAYRND \ (stepMs + 10))) + 1
                            END IF
                        END IF
                        IF mineMode = 2 OR mineMode = 4 THEN
                            IF INT(RND * 3) = 0 THEN SpawnMine
                        END IF
                        IF eggLeft = 1 AND NOT heartDone THEN HeartSpawn
                    END IF
                    DrawHud
                    EXIT FOR
                END IF
            NEXT e
            IF bonOn THEN
                IF bonRow = rr AND bonCol = c THEN
                    bonOn = FALSE
                    Sfx 5
                    AddScore a, 500
                    DrawHud
                END IF
            END IF
            IF heartOn THEN
                IF heartRow = rr AND heartCol = c THEN
                    heartOn = FALSE
                    IF sammy(a).lives < MAXLIVES THEN sammy(a).lives = sammy(a).lives + 1
                    Sfx 8
                    DrawHud
                END IF
            END IF
            IF pillOn THEN
                IF pillRow = rr AND pillCol = c THEN
                    pillOn = FALSE
                    ShrinkSnake a, PILLCUT
                    AddScore a, PILLPTS
                    Sfx 11
                    DrawHud
                END IF
            END IF
        END IF
    NEXT a
END SUB

'TryChooseDoor:
'  Picks a row for the next door pair: one of the rows prepared when the level
'  was built (PrepareDoors).  The lanes in front of both doors must still be
'  empty (no wall, snake, item or mine).  On a divided level without a
'  prepared row any row is tried.  FALSE if none was found.
FUNCTION TryChooseDoor
    TryChooseDoor = FALSE
    IF dcN > 0 THEN
        k0 = INT(RND * dcN)                     'one of the prepared rows, in random order
        FOR i = 0 TO dcN - 1
            r = dcRow(((k0 + i) MOD dcN) + 1)
            IF DoorRowOk(r) THEN
                doorRow = r
                TryChooseDoor = TRUE
                EXIT FUNCTION
            END IF
        NEXT i
    ELSEIF splitLevel THEN                      'divided level without a prepared row: the doors are the only way over
        FOR attempt = 1 TO 30
            r = INT(RND * 19) + 3
            IF DoorRowOk(r) THEN
                doorRow = r
                TryChooseDoor = TRUE
                EXIT FUNCTION
            END IF
        NEXT attempt
    END IF
END FUNCTION


'ApplyTheme:
'  Fills the colour table.  Entries:
'   1 snake 1 body   2 snake 2 body   3 plain walls   4 background
'   5 dialog text    6 dialog back    7 snake 1 head  8 snake 2 head
'   9 egg colour    10 bonus colour  11 status text  12 status back
'  13 snake 1 stripe 14 snake 2 stripe 15 mine colour 16 egg count (status)
'  17/18 stone walls (two greys, set below for every theme)
SUB ApplyTheme
    SELECT CASE theme
        CASE 1                                  'Classic (blue)
            pal(1) = 14: pal(2) = 13: pal(3) = 12: pal(4) = 1
            pal(5) = 15: pal(6) = 4: pal(7) = 15: pal(8) = 15
            pal(9) = 15: pal(10) = 10: pal(11) = 15: pal(12) = 0
            pal(13) = 6: pal(14) = 5: pal(15) = 12: pal(16) = 14
        CASE 2                                  'Night (black)
            pal(1) = 10: pal(2) = 11: pal(3) = 9: pal(4) = 0
            pal(5) = 15: pal(6) = 1: pal(7) = 15: pal(8) = 15
            pal(9) = 14: pal(10) = 13: pal(11) = 15: pal(12) = 1
            pal(13) = 2: pal(14) = 3: pal(15) = 12: pal(16) = 14
        CASE 3                                  'Forest (green)
            pal(1) = 14: pal(2) = 11: pal(3) = 6: pal(4) = 2
            pal(5) = 15: pal(6) = 1: pal(7) = 15: pal(8) = 15
            pal(9) = 15: pal(10) = 13: pal(11) = 15: pal(12) = 0
            pal(13) = 6: pal(14) = 3: pal(15) = 12: pal(16) = 14
        CASE 4                                  'Ocean (cyan)
            pal(1) = 14: pal(2) = 13: pal(3) = 1: pal(4) = 3
            pal(5) = 15: pal(6) = 1: pal(7) = 15: pal(8) = 15
            pal(9) = 15: pal(10) = 10: pal(11) = 15: pal(12) = 1
            pal(13) = 6: pal(14) = 5: pal(15) = 12: pal(16) = 14
        CASE ELSE                               'Desert (brown)
            pal(1) = 10: pal(2) = 11: pal(3) = 14: pal(4) = 6
            pal(5) = 15: pal(6) = 1: pal(7) = 15: pal(8) = 15
            pal(9) = 15: pal(10) = 13: pal(11) = 15: pal(12) = 0
            pal(13) = 2: pal(14) = 3: pal(15) = 12: pal(16) = 14
    END SELECT
    pal(17) = 7: pal(18) = 8
END SUB

'AskYesNo:
'  Small Yes / No menu: arrow keys + ENTER, or Y / N.  ESC = No.
'  Returns TRUE for Yes.
FUNCTION AskYesNo (msg$)
    w = LEN(msg$) + 8
    IF w < 30 THEN w = 30
    c1 = (80 - w) \ 2 + 1
    c2 = c1 + w - 1
    attr = pal(5) + pal(6) * 16
    hl = 7 * 16                               'highlighted option
    DrawBox 8, c1, 12, c2, attr
    Center 9, msg$, attr
    cy = (80 - 17) \ 2 + 1
    sel = 2                                   '1 = Yes, 2 = No (safe default)
    DO WHILE INKEY$ <> "": LOOP
    DO
        IF sel = 1 THEN ay = hl ELSE ay = attr
        IF sel = 2 THEN an = hl ELSE an = attr
        PutStr 11, cy, "  Yes  ", ay
        PutStr 11, cy + 11, "  No  ", an
        DO
            k$ = INKEY$
        LOOP WHILE k$ = ""
        SELECT CASE k$
            CASE CHR$(0) + "K", CHR$(0) + "M", CHR$(0) + "H", CHR$(0) + "P", CHR$(9)
                sel = 3 - sel
            CASE "y", "Y"
                sel = 1
                EXIT DO
            CASE "n", "N", CHR$(27)
                sel = 2
                EXIT DO
            CASE CHR$(13)
                EXIT DO
        END SELECT
    LOOP
    AskYesNo = (sel = 1)
    RedrawRows 7, 13
END FUNCTION

'BannerRow$:
'  One line of the big NIBBLES logo ("#" = solid block)
FUNCTION BannerRow$ (i)
    SELECT CASE i
        CASE 1: BannerRow$ = "#   #  #####  ####   ####   #      #####   ####"
        CASE 2: BannerRow$ = "##  #    #    #   #  #   #  #      #      #    "
        CASE 3: BannerRow$ = "# # #    #    ####   ####   #      ####    ### "
        CASE 4: BannerRow$ = "#  ##    #    #   #  #   #  #      #          #"
        CASE ELSE: BannerRow$ = "#   #  #####  ####   ####   #####  #####  #### "
    END SELECT
END FUNCTION

'BorderPos:
'  Text cell (r, c) of border position u (0 to 251).  The positions run
'  clockwise around the screen edge, starting at the top left corner.  A
'  text cell is about twice as high as it is wide, so a step along the left
'  and right edges is worth 2 units and a step along the top and bottom
'  edges 1 unit: equal distances in units look equal on the screen.
SUB BorderPos (u, r, c)
    IF u < 80 THEN
        r = 1: c = u + 1                       'top edge
    ELSEIF u < 126 THEN
        r = 2 + (u - 80) \ 2: c = 80           'right edge
    ELSEIF u < 206 THEN
        r = 25: c = 80 - (u - 126)             'bottom edge
    ELSE
        r = 24 - (u - 206) \ 2: c = 1          'left edge
    END IF
END SUB

'Center:
'  Prints text centred on the given row
SUB Center (row, text$, attr)
    PutStr row, (80 - LEN(text$)) \ 2 + 1, text$, attr
END SUB

'ChangeSetting:
'  Changes one menu setting (d = -1 or +1)
SUB ChangeSetting (sel, d)
    SELECT CASE sel
        CASE 1
            IF numPlayers = 1 THEN numPlayers = 2 ELSE numPlayers = 1
        CASE 2
            speedSet = speedSet + d
            IF speedSet < 1 THEN speedSet = 1
            IF speedSet > 10 THEN speedSet = 10
        CASE 3
            speedUp = NOT speedUp
        CASE 4
            startLevel = startLevel + d
            IF startLevel < 1 THEN startLevel = 1
            IF startLevel > numLevels THEN startLevel = numLevels
        CASE 5
            theme = theme + d
            IF theme > 5 THEN theme = 1
            IF theme < 1 THEN theme = 5
        CASE 6
            soundOn = NOT soundOn
        CASE 7
            mineMode = mineMode + d
            IF mineMode > 4 THEN mineMode = 1
            IF mineMode < 1 THEN mineMode = 4
        CASE 8
            doorsOn = NOT doorsOn
        CASE 9
            wallStone = NOT wallStone
        CASE 10
            IF endMode = 1 THEN endMode = 2 ELSE endMode = 1
    END SELECT
END SUB

'CleanName$:
'  Makes a valid player name: upper case, 1 to 8 printable characters
FUNCTION CleanName$ (n$, dflt$)
    res$ = ""
    FOR i = 1 TO LEN(n$)
        ch = ASC(MID$(n$, i, 1))
        IF ch >= 32 AND ch <= 126 AND ch <> 34 AND ch <> 44 THEN res$ = res$ + MID$(n$, i, 1)
    NEXT i
    res$ = LTRIM$(RTRIM$(UCASE$(res$)))
    IF LEN(res$) > 8 THEN res$ = LEFT$(res$, 8)
    IF LEN(res$) = 0 THEN res$ = dflt$
    CleanName$ = res$
END FUNCTION

'ClearScreen:
'  Clears the whole screen with the given attribute
SUB ClearScreen (attr)
    FillRect 1, 1, 25, 80, 32, attr
END SUB

'Dialog:
'  Message box in the upper part of the screen, waits for SPACE or ENTER.
'  ESC asks "Quit to the menu?" (Yes sets abortGame, No shows the box again).
'  If prepWhat is set, that level (SAMELEVEL / NEXTLEVEL) is built while the
'  box is on the screen; the arena is drawn when the box is closed.  If SPACE
'  is pressed before the level is ready, "please wait" is shown.
SUB Dialog (t1$, t2$, hint$)
    w = LEN(t1$)
    IF LEN(t2$) > w THEN w = LEN(t2$)
    IF LEN(hint$) > w THEN w = LEN(hint$)
    w = w + 8
    IF w < 34 THEN w = 34
    c1 = (80 - w) \ 2 + 1
    c2 = c1 + w - 1
    attr = pal(5) + pal(6) * 16
    IF dlgBg > 0 THEN attr = 15 + dlgBg * 16     'own colour (level complete)
    DO WHILE INKEY$ <> "": LOOP
    prep = prepWhat
    prepWhat = 0
    prepDone = FALSE
    spaceHit = FALSE
    pendingEsc = FALSE
    done = FALSE
    DO
        DrawBox 8, c1, 12, c2, attr
        Center 9, t1$, attr
        Center 10, t2$, attr
        Center 11, hint$, attr
        IF prep > 0 THEN
            deferDraw = TRUE
            Level prep
            deferDraw = FALSE
            prepDone = TRUE
            prep = 0
        END IF
        IF pendingEsc THEN
            k$ = CHR$(27)
            pendingEsc = FALSE
        ELSEIF spaceHit THEN
            k$ = " "
            spaceHit = FALSE
        ELSE
            DO
                k$ = INKEY$
            LOOP UNTIL k$ = " " OR k$ = CHR$(13) OR k$ = CHR$(27)
        END IF
        IF k$ = CHR$(27) THEN
            IF AskYesNo("Quit to the menu?") THEN
                abortGame = TRUE
                done = TRUE
            END IF
        ELSE
            done = TRUE
        END IF
    LOOP UNTIL done
    IF prepDone THEN
        FOR m = 1 TO MAXFIX                     'the new arena shows all mines again
            fxGone(m) = FALSE
        NEXT m
        RedrawRows 2, 25
    ELSE
        RedrawRows 7, 13
    END IF
END SUB

'DrawBanner:
'  Draws the big NIBBLES logo.  phase shifts the colours (animation)
SUB DrawBanner (row, phase, withShadow)
    c0 = 17
    FOR i = 1 TO 5
        s$ = BannerRow$(i)
        SELECT CASE (i + phase) MOD 5
            CASE 0: fc = 12
            CASE 1: fc = 14
            CASE 2: fc = 10
            CASE 3: fc = 11
            CASE ELSE: fc = 13
        END SELECT
        FOR j = 1 TO LEN(s$)
            IF MID$(s$, j, 1) = "#" THEN
                IF withShadow THEN PutChar row + i, c0 + j, 177, 8
                PutChar row + i - 1, c0 + j - 1, 219, fc
            END IF
        NEXT j
    NEXT i
END SUB

'DrawBox:
'  Double line box, the inside is cleared
SUB DrawBox (r1, c1, r2, c2, attr)
    FillRect r1, c1, r2, c2, 32, attr
    PutStr r1, c1, CHR$(201) + STRING$(c2 - c1 - 1, 205) + CHR$(187), attr
    PutStr r2, c1, CHR$(200) + STRING$(c2 - c1 - 1, 205) + CHR$(188), attr
    FOR r = r1 + 1 TO r2 - 1
        PutChar r, c1, 186, attr
        PutChar r, c2, 186, attr
    NEXT r
END SUB

'DrawMenu:
'  Draws the whole settings menu (the frame is drawn by DrawMenuFrame)
SUB DrawMenu (sel)
    FOR i = 1 TO 15
        DrawMenuRow i, sel
    NEXT i
END SUB

'DrawMenuFrame:
'  Background of the menu screen: logo, box, high score, help line
SUB DrawMenuFrame
    ClearScreen 7
    DrawBanner 2, 0, TRUE
    DrawBox 8, 18, 24, 63, 11
    Center 8, " S E T T I N G S ", 14
    Center 24, " HIGH SCORE:" + STR$(highScore) + "  " + hiName$ + " ", 14
    DrawMenuHint
END SUB

'DrawMenuHint:
'  Help line of the menu
SUB DrawMenuHint
    FillRect 25, 1, 25, 80, 32, 7
    Center 25, "UP/DOWN select    LEFT/RIGHT change    ENTER start    ESC quit", 7
END SUB

'DrawMenuRow:
'  Draws one line of the settings menu.  Every part of the line is written
'  with a single PutStr, so nothing flickers.  sel = highlighted line.
SUB DrawMenuRow (i, sel)
    r = 8 + i
    SELECT CASE i
        CASE 1: lab$ = "Players"
        CASE 2: lab$ = "Speed"
        CASE 3: lab$ = "Faster each level"
        CASE 4: lab$ = "Start level"
        CASE 5: lab$ = "Colors"
        CASE 6: lab$ = "Sound"
        CASE 7: lab$ = "Mines"
        CASE 8: lab$ = "Doors"
        CASE 9: lab$ = "Walls"
        CASE 10: lab$ = "After last level"
        CASE 11: lab$ = "Player 1 name"
        CASE 12: lab$ = "Player 2 name"
        CASE 13: lab$ = "High scores"
        CASE ELSE: lab$ = ""
    END SELECT
    SELECT CASE i
        CASE 1
            IF numPlayers = 1 THEN v$ = "1 PLAYER" ELSE v$ = "2 PLAYERS"
        CASE 2
            v$ = STRING$(speedSet, 219) + STRING$(10 - speedSet, 176) + STR$(speedSet)
        CASE 3
            IF speedUp THEN v$ = "ON" ELSE v$ = "OFF"
        CASE 4
            v$ = LTRIM$(STR$(startLevel))
        CASE 5
            SELECT CASE theme
                CASE 1: v$ = "CLASSIC"
                CASE 2: v$ = "NIGHT"
                CASE 3: v$ = "FOREST"
                CASE 4: v$ = "OCEAN"
                CASE ELSE: v$ = "DESERT"
            END SELECT
        CASE 6
            IF soundOn THEN v$ = "ON" ELSE v$ = "OFF"
        CASE 7
            SELECT CASE mineMode
                CASE 1: v$ = "OFF"
                CASE 2: v$ = "RANDOM"
                CASE 3: v$ = "FIXED"
                CASE ELSE: v$ = "BOTH"
            END SELECT
        CASE 8
            IF doorsOn THEN v$ = "ON" ELSE v$ = "OFF"
        CASE 9
            IF wallStone THEN v$ = "STONE" ELSE v$ = "PLAIN"
        CASE 10
            IF endMode = 1 THEN v$ = "ENDING" ELSE v$ = "ENDLESS"
        CASE 11
            v$ = nm$(1)
        CASE 12
            v$ = nm$(2)
        CASE ELSE
            v$ = ""
    END SELECT

    IF i <= 13 THEN
        IF i = sel THEN
            IF i >= 11 THEN
                v$ = v$ + "  [ENTER]"
            ELSE
                v$ = CHR$(17) + " " + v$ + " " + CHR$(16)
            END IF
            ln$ = SPACE$(44)
            MID$(ln$, 4) = lab$
            MID$(ln$, 24) = v$
            PutStr r, 19, ln$, 112
        ELSE
            ln$ = SPACE$(25)
            MID$(ln$, 4) = lab$
            PutStr r, 19, ln$, 7
            PutStr r, 44, LEFT$(v$ + SPACE$(19), 19), 15
        END IF
    ELSE
        IF i = 14 THEN txt$ = "S T A R T   G A M E" ELSE txt$ = "Q U I T"
        ln$ = SPACE$(44)
        MID$(ln$, (44 - LEN(txt$)) \ 2 + 1) = txt$
        IF i = 14 THEN
            IF i = sel THEN ta = 15 + 2 * 16 ELSE ta = 10      'green START GAME
        ELSE
            IF i = sel THEN ta = 15 + 4 * 16 ELSE ta = 12      'red QUIT
        END IF
        PutStr r, 19, ln$, ta
    END IF
END SUB

'DrawTable:
'  Draws the high score table (header on row r0, entries below it).
'  Entries hl1 and hl2 are drawn with hlAttr.
SUB DrawTable (r0, hl1, hl2, baseAttr, hlAttr)
    Center r0, "H I G H   S C O R E S", hlAttr
    FOR i = 1 TO 10
        IF i <= hsCount THEN
            nn$ = hsName$(i)
            sc$ = Num7$(hsScore(i))
            lv$ = RIGHT$("0" + LTRIM$(STR$(hsLevel(i))), 2)
        ELSE
            nn$ = "--------"
            sc$ = Num7$(0&)
            lv$ = "--"
        END IF
        ln$ = RIGHT$(" " + LTRIM$(STR$(i)), 2) + ". " + nn$ + SPACE$(8 - LEN(nn$)) + " " + sc$ + "   L" + lv$
        IF i = hl1 OR i = hl2 THEN ta = hlAttr ELSE ta = baseAttr
        Center r0 + i, ln$, ta
    NEXT i
END SUB

'EditName:
'  Lets the user type a new name for player who (1 or 2)
SUB EditName (who)
    IF who = 1 THEN
        r = 19
        dflt$ = "SAMMY"
    ELSE
        r = 20
        dflt$ = "JAKE"
    END IF
    FillRect 25, 1, 25, 80, 32, 7
    Center 25, "Type a name (max 8 characters)    ENTER = ok    ESC = cancel", 14
    n$ = ""
    cancelled = FALSE
    DO
        PutStr r, 42, LEFT$(n$ + "_" + SPACE$(14), 14), 112
        DO
            k$ = INKEY$
        LOOP WHILE k$ = ""
        IF k$ = CHR$(13) THEN
            EXIT DO
        ELSEIF k$ = CHR$(27) THEN
            cancelled = TRUE
            EXIT DO
        ELSEIF k$ = CHR$(8) THEN
            IF LEN(n$) > 0 THEN n$ = LEFT$(n$, LEN(n$) - 1)
        ELSEIF LEN(k$) = 1 THEN
            ch = ASC(k$)
            IF ch >= 32 AND ch <= 126 AND ch <> 34 AND ch <> 44 AND LEN(n$) < 8 THEN n$ = n$ + UCASE$(k$)
        END IF
    LOOP
    IF NOT cancelled THEN nm$(who) = CleanName$(n$, dflt$)
END SUB

'FillRect:
'  Fills a rectangle of the text screen with a character and attribute
SUB FillRect (r1, c1, r2, c2, ch, attr)
    DEF SEG = vidSeg
    FOR r = r1 TO r2
        ofs = (r - 1) * 160 + (c1 - 1) * 2
        FOR c = c1 TO c2
            POKE ofs, ch
            POKE ofs + 1, attr
            ofs = ofs + 2
        NEXT c
    NEXT r
    DEF SEG
END SUB

'GameOverScreen:
'  Shows the results and the high score table.  The box is only as high as
'  its content.  Returns 1 = play again, 2 = menu, 3 = quit
FUNCTION GameOverScreen
    attr = pal(5) + pal(6) * 16
    hl = 7 * 16
    hasRes = (numPlayers = 2)
    IF rankOf(1) = 1 THEN hasRes = TRUE
    'title, blank, players, blank, table (header + 10), blank, buttons, hint
    rows = 1 + 1 + numPlayers + 1 + 11 + 1 + 1 + 1
    IF victory THEN rows = rows + 1
    IF hasRes THEN rows = rows + 1
    top = (25 - (rows + 2)) \ 2 + 1
    DrawBox top, 20, top + rows + 1, 61, attr
    r = top + 1
    IF victory THEN
        Center r, "C O N G R A T U L A T I O N S !", attr
        r = r + 1
        Center r, "You completed all" + STR$(numLevels) + " levels!", attr
    ELSE
        Center r, "G A M E   O V E R", attr
    END IF
    r = r + 2

    FOR a = 1 TO numPlayers
        l$ = nm$(a) + SPACE$(8 - LEN(nm$(a))) + Num7$(sammy(a).score)
        IF rankOf(a) > 0 THEN l$ = l$ + "   RANK" + STR$(rankOf(a))
        Center r, l$, attr
        r = r + 1
    NEXT a
    IF numPlayers = 2 THEN
        IF sammy(1).score > sammy(2).score THEN
            res$ = nm$(1) + " WINS!"
        ELSEIF sammy(2).score > sammy(1).score THEN
            res$ = nm$(2) + " WINS!"
        ELSE
            res$ = "IT IS A DRAW!"
        END IF
        Center r, res$, attr
        r = r + 1
    ELSEIF rankOf(1) = 1 THEN
        Center r, "*  NEW HIGH SCORE!  *", attr
        r = r + 1
    END IF
    r = r + 1

    DrawTable r, rankOf(1), rankOf(2), attr, 14 + pal(6) * 16
    r = r + 12                                'buttons row (hint row below it)

    sel = 1                                   '1 play again, 2 menu, 3 quit
    DO WHILE INKEY$ <> "": LOOP
    DO
        IF sel = 1 THEN a1 = hl ELSE a1 = attr
        IF sel = 2 THEN a2 = hl ELSE a2 = attr
        IF sel = 3 THEN a3 = hl ELSE a3 = attr
        PutStr r, 23, "  PLAY AGAIN  ", a1
        PutStr r, 40, "  MENU  ", a2
        PutStr r, 51, "  QUIT  ", a3
        Center r + 1, "arrow keys + ENTER      or P  M  Q", attr
        DO
            k$ = INKEY$
        LOOP WHILE k$ = ""
        SELECT CASE k$
            CASE CHR$(0) + "K", CHR$(0) + "H"
                sel = sel - 1
                IF sel < 1 THEN sel = 3
            CASE CHR$(0) + "M", CHR$(0) + "P", CHR$(9)
                sel = sel + 1
                IF sel > 3 THEN sel = 1
            CASE CHR$(13)
                EXIT DO
            CASE "p", "P", "y", "Y"
                sel = 1
                EXIT DO
            CASE "m", "M"
                sel = 2
                EXIT DO
            CASE CHR$(27), "q", "Q", "n", "N"
                sel = 3
                EXIT DO
        END SELECT
    LOOP
    GameOverScreen = sel
END FUNCTION

'Intro:
'  Animated title screen
SUB Intro
    ClearScreen 7
    DrawBanner 3, 0, TRUE
    Center 10, "D E L U X E   E D I T I O N   -   " + VERSIONTXT, 14
    Center 11, "based on Microsoft QBasic Nibbles (C) 1990", 8

    Center 12, "Steer your snake around the arena and collect all the eggs to", 7
    Center 13, "finish a level.  Every egg makes you longer and scores 100 points.", 7
    Center 14, "Catch the flashing star for a bonus and the heart for an extra life!", 7
    Center 15, "From level 6 on, a flashing pill scores 250 points and shortens you.", 7
    Center 16, "Avoid walls, the other snake, your own tail and the red mines.", 7
    Center 17, "From level 6 on, side doors open now and then - go through them!", 7

    Center 18, "PLAYER 1  -  arrow keys  (or keypad 8 2 4 6)", 11
    Center 19, "PLAYER 2  -  W A S D     (W A S D also work in 1 player mode)", 13
    Center 20, "P = pause           ESC = quit to menu", 7

    SparklePause
END SUB

'IsWallColor:
'  TRUE if colour c is a wall colour (plain or stone)
FUNCTION IsWallColor (c)
    IsWallColor = (c = pal(3) OR c = pal(17) OR c = pal(18))
END FUNCTION

'Level:
'  Builds a level: walls, start positions and snakes
SUB Level (what)
    SELECT CASE what
        CASE STARTOVER
            curLevel = startLevel
        CASE NEXTLEVEL
            curLevel = curLevel + 1
    END SELECT

    FOR r = 1 TO 50
        FOR c = 1 TO 80
            arena(r, c) = pal(4)
        NEXT c
    NEXT r
    IF deferDraw THEN PollWait

    'outer wall
    FOR c = 1 TO 80
        Wall 3, c
        Wall 50, c
    NEXT c
    FOR r = 4 TO 49
        Wall r, 1
        Wall r, 80
    NEXT r

    'the level is read from the level file: divided flag, start positions, walls
    lvRec$ = SPACE$(LEVELREC)
    k = ((curLevel - 1) MOD numLevels) + 1
    LoadLevelRec k, lvRec$
    splitLevel = (ASC(MID$(lvRec$, 1, 1)) <> 0)
    FOR a = 1 TO 2
        sammy(a).row = ASC(MID$(lvRec$, 2 + (a - 1) * 3, 1))
        sammy(a).col = ASC(MID$(lvRec$, 3 + (a - 1) * 3, 1))
        sammy(a).direction = ASC(MID$(lvRec$, 4 + (a - 1) * 3, 1))
    NEXT a
    p = 17                                          'the 46 x 78 interior, row by row
    FOR r = 4 TO 49
        FOR c = 2 TO 79
            IF ASC(MID$(lvRec$, p, 1)) <> 0 THEN Wall r, c
            p = p + 1
        NEXT c
    NEXT r
    IF deferDraw THEN PollWait

    'set up the snakes: body behind the head, head drawn in head colour
    FOR a = 1 TO 2
        sammy(a).alive = TRUE
        sammy(a).lastDir = sammy(a).direction
        qn(a) = 0
    NEXT a
    FOR a = 1 TO numPlayers
        dr = 0: dc = 0
        SELECT CASE sammy(a).direction
            CASE 1: dr = -1
            CASE 2: dr = 1
            CASE 3: dc = -1
            CASE ELSE: dc = 1
        END SELECT
        nseg = 0
        FOR back = 0 TO STARTLEN - 1                'head first, then the body behind it
            sr = sammy(a).row - back * dr
            sc = sammy(a).col - back * dc
            IF sr < 4 OR sr > 49 OR sc < 2 OR sc > 79 THEN EXIT FOR
            IF arena(sr, sc) <> pal(4) THEN EXIT FOR      'never start inside a wall
            j = STARTLEN - 1 - back
            sammyBody(j, a).row = sr
            sammyBody(j, a).col = sc
            IF back = 0 THEN
                arena(sr, sc) = pal(6 + a)
            ELSEIF back <= NECKLEN THEN
                arena(sr, sc) = pal(12 + a)           'the neck: dark, no stripes
            ELSE
                arena(sr, sc) = BodyColor(a, j)
            END IF
            nseg = nseg + 1
        NEXT back
        sammy(a).head = STARTLEN - 1
        sammy(a).count = nseg
        sammy(a).length = STARTLEN
    NEXT a

    IF deferDraw THEN PollWait
    bonOn = FALSE: heartOn = FALSE: heartDone = FALSE
    pillOn = FALSE: pillCnt = 0
    FOR m = 1 TO MAXMINE
        minTime(m) = 0
    NEXT m
    doorState = 0
    dcN = 0                                     'no door lanes reserved while the level is built
    IF what <> SAMELEVEL THEN fxCount = 0       'same level again: same fixed mines
    PlaceEggs
    IF deferDraw THEN PollWait
    IF splitLevel THEN FixEggs
    IF deferDraw THEN PollWait
    IF fxCount = 0 THEN
        PlaceFixedMines
    ELSE
        RunBfs TRUE
        IF NOT EggsReachable THEN PlaceFixedMines
    END IF
    PrepareHeart                                 'places of the heart, near the corners
    PrepareDoors                                 'door rows (one of them is used in the game)
    PrepareMines                                 'places for the random mines
    IF NOT deferDraw THEN RedrawRows 2, 25
END SUB

'MainMenu:
'  Settings menu.  Returns TRUE to start a game, FALSE to quit.
'  Only the lines that change are redrawn.
FUNCTION MainMenu
    DrawMenuFrame
    sel = 14
    DrawMenu sel
    DO
        DO
            k$ = INKEY$
        LOOP WHILE k$ = ""
        old = sel
        full = FALSE
        SELECT CASE k$
            CASE CHR$(0) + "H"
                sel = sel - 1
                IF sel < 1 THEN sel = 15
            CASE CHR$(0) + "P"
                sel = sel + 1
                IF sel > 15 THEN sel = 1
            CASE CHR$(0) + "K"
                ChangeSetting sel, -1
            CASE CHR$(0) + "M"
                ChangeSetting sel, 1
            CASE " "
                IF sel <= 10 THEN
                    ChangeSetting sel, 1
                ELSEIF sel = 11 OR sel = 12 THEN
                    EditName sel - 10
                    DrawMenuHint
                ELSEIF sel = 13 THEN
                    ShowScores
                    DrawMenuFrame
                    full = TRUE
                END IF
            CASE CHR$(13)
                IF sel = 11 OR sel = 12 THEN
                    EditName sel - 10
                    DrawMenuHint
                ELSEIF sel = 13 THEN
                    ShowScores
                    DrawMenuFrame
                    full = TRUE
                ELSE
                    IF sel = 15 THEN MainMenu = FALSE ELSE MainMenu = TRUE
                    EXIT DO
                END IF
            CASE CHR$(27)
                MainMenu = FALSE
                EXIT DO
        END SELECT
        IF full THEN
            DrawMenu sel
        ELSE
            IF old <> sel THEN DrawMenuRow old, sel
            DrawMenuRow sel, sel
        END IF
    LOOP
END FUNCTION

'Num7$:
'  Number as a right aligned string of 7 characters
FUNCTION Num7$ (v&)
    Num7$ = RIGHT$(SPACE$(7) + LTRIM$(STR$(v&)), 7)
END FUNCTION

'PutChar:
'  Writes one character with an attribute directly into video memory
SUB PutChar (row, col, ch, attr)
    ofs = (row - 1) * 160 + (col - 1) * 2
    DEF SEG = vidSeg
    POKE ofs, ch
    POKE ofs + 1, attr
    DEF SEG
END SUB

'PutStr:
'  Writes a string with an attribute directly into video memory
SUB PutStr (row, col, s$, attr)
    ofs = (row - 1) * 160 + (col - 1) * 2
    DEF SEG = vidSeg
    FOR i = 1 TO LEN(s$)
        IF col + i - 1 > 80 THEN EXIT FOR
        POKE ofs, ASC(MID$(s$, i, 1))
        POKE ofs + 1, attr
        ofs = ofs + 2
    NEXT i
    DEF SEG
END SUB

'SetBlink:
'  TRUE = normal blinking text, FALSE = 16 background colours (VGA)
SUB SetBlink (flag)
    IF vidSeg <> &HB800& THEN EXIT SUB
    dummy = INP(&H3DA)        'reset the attribute controller flip-flop
    OUT &H3C0, &H30           'select the mode control register
    v = INP(&H3C1)
    IF flag THEN v = v OR 8 ELSE v = v AND 247
    OUT &H3C0, v
END SUB

'ShowScores:
'  Full screen high score table (from the menu)
SUB ShowScores
    ClearScreen 7
    DrawBox 3, 24, 17, 57, 11
    DrawTable 4, 0, 0, 7, 14
    Center 16, "Press any key", 8
    DO WHILE INKEY$ <> "": LOOP
    DO
    LOOP WHILE INKEY$ = ""
END SUB

'ShowWait:
'  Message while a level is built (it takes a moment)
SUB ShowWait
    attr = pal(5) + pal(6) * 16
    DrawBox 10, 22, 14, 59, attr
    Center 11, "PLEASE WAIT", attr
    Center 12, "preparing the arena...", attr
END SUB

'SparklePause:
'  Title screen animation until a key is pressed: the game pieces (egg,
'  star, mine, heart, pill) travel clockwise around the screen edge, every
'  second piece is dark and they take turns blinking.  The logo cycles its
'  colours.
SUB SparklePause
    CONST NB = 28                              'number of pieces (an even divisor of 252)
    DIM oldP(1 TO NB)
    DIM tune$(1 TO 20)
    'the opening music (cheerful march, C major, 4 bars), played once, one note
    'at a time so that it stops almost at once when a key is pressed
    tune$(1) = "MBMNT160O3L8C"
    tune$(2) = "MBMNT160O3L8D"
    tune$(3) = "MBMNT160O3L8E"
    tune$(4) = "MBMNT160O3L8G"
    tune$(5) = "MBMNT160O4L4C"
    tune$(6) = "MBMNT160O3L4G"
    tune$(7) = "MBMNT160O3L8A"
    tune$(8) = "MBMNT160O3L8G"
    tune$(9) = "MBMNT160O3L8E"
    tune$(10) = "MBMNT160O3L8D"
    tune$(11) = "MBMNT160O3L4E"
    tune$(12) = "MBMNT160O3L4C"
    tune$(13) = "MBMNT160O3L4G"
    tune$(14) = "MBMNT160O3L4F"
    tune$(15) = "MBMNT160O3L4E"
    tune$(16) = "MBMNT160O3L4D"
    tune$(17) = "MBMNT160O3L4C"
    tune$(18) = "MBMNT160O3L4E"
    tune$(19) = "MBMNT160O3L4G"
    tune$(20) = "MBMNT160O4L2C"
    tp = 1
    ph = 0
    FOR i = 1 TO NB
        oldP(i) = -1
    NEXT i
    DO WHILE INKEY$ <> "": LOOP
    DO
        'erase the pieces of the last frame
        FOR i = 1 TO NB
            IF oldP(i) >= 0 THEN
                BorderPos oldP(i), r, c
                PutChar r, c, 32, 7
            END IF
        NEXT i
        'draw them at their new places
        FOR i = 1 TO NB
            p = ((i - 1) * (252 \ NB) + ph) MOD 252
            SELECT CASE (i - 1) MOD 5
                CASE 0: ch = eggChr: fc = 15
                CASE 1: ch = 4: fc = 10
                CASE 2: ch = MINECHAR: fc = 12
                CASE 3: ch = 3: fc = 12
                CASE ELSE: ch = 5: fc = 11
            END SELECT
            IF ((i + ph \ 2) AND 1) = 0 THEN fc = 8
            BorderPos p, r, c
            PutChar r, c, ch, fc
            oldP(i) = p
        NEXT i
        DrawBanner 3, ph, FALSE
        IF ph AND 1 THEN
            Center 22, "Press any key to continue", 15
        ELSE
            Center 22, "Press any key to continue", 8
        END IF
        ph = ph + 1
        IF ph >= 1260 THEN ph = 0               'all cycles (5, 4, 252) fit into 1260
        FOR sl = 1 TO 4                           'the music is checked every 20 ms
            IF soundOn AND tp <= 20 THEN
                IF PLAY(0) = 0 THEN
                    PLAY tune$(tp)
                    tp = tp + 1
                END IF
            END IF
            DelayMs 20
        NEXT sl
    LOOP WHILE INKEY$ = ""
END SUB

'Wall:
'  Marks a pixel as wall (the screen is drawn later by RedrawRows)
SUB Wall (row, col)
    IF row >= 1 AND row <= 50 AND col >= 1 AND col <= 80 THEN arena(row, col) = WallColor(row, col)
END SUB

'WallColor:
'  Colour of the wall pixel (row, col): a two grey check pattern for stone
'  walls (one pattern square per text cell), or the plain wall colour
FUNCTION WallColor (row, col)
    IF wallStone THEN
        IF (((row + 1) \ 2) + col) AND 1 THEN
            WallColor = pal(17)
        ELSE
            WallColor = pal(18)
        END IF
    ELSE
        WallColor = pal(3)
    END IF
END FUNCTION
