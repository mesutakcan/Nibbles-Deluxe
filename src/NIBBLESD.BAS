'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  An improved version of the classic Microsoft QBasic Nibbles (1990).
'
'  https://github.com/mesutakcan/Nibbles-Deluxe
'  Version 13
'  2026-10-19
'
'  Written for QuickBASIC 4.5 (QB45), in two modules (NIBBLESD.BAS + NIBBLEUI.BAS).
'  QB64-PE builds NIBBLESD_ALL.BAS, the same code merged into one file.
'  For detailed information, please refer to the README.md file.
'===========================================================================

'$DYNAMIC
DEFINT A-Z


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

'---- Sub declarations --------------------------------------------------------
DECLARE FUNCTION AddToTable (n$, sc&, lv)
DECLARE FUNCTION AskYesNo (msg$)
DECLARE FUNCTION BodyColor (a, idx)
DECLARE FUNCTION CellBusy (rr, cc)
DECLARE FUNCTION CleanName$ (n$, dflt$)
DECLARE FUNCTION DoorFree (mask)
DECLARE FUNCTION DoorPass (row)
DECLARE FUNCTION DoorTicks (ms)
DECLARE FUNCTION EggsReachable ()
DECLARE FUNCTION MineSpotOk (r, c)
DECLARE FUNCTION TryChooseDoor ()
DECLARE FUNCTION WallColor (row, col)
DECLARE FUNCTION GameOverScreen ()
DECLARE FUNCTION GlyphData$ (k)
DECLARE FUNCTION IsWallColor (c)
DECLARE FUNCTION ItemInRect (r1, c1, r2, c2)
DECLARE FUNCTION MainMenu ()
DECLARE FUNCTION Num7$ (v&)
DECLARE FUNCTION PointIsThere (row, col)
DECLARE SUB AddScore (a, pts)
DECLARE SUB ApplyTheme ()
DECLARE SUB BlinkHud ()
DECLARE SUB Calibrate ()
DECLARE SUB Center (row, text$, attr)
DECLARE SUB ClearScreen (attr)
DECLARE SUB DeathAnim (a, variant)
DECLARE SUB DelayMs (ms)
DECLARE SUB DoorBlink (kind, flag)
DECLARE SUB DoorReset ()
DECLARE SUB DoorSet (k, wallFlag)
DECLARE SUB DoorTick ()
DECLARE SUB Dialog (t1$, t2$, hint$)
DECLARE SUB DrawCell (r, c)
DECLARE SUB DrawHud ()
DECLARE SUB DrawHudCenter (eggFg)
DECLARE SUB DrawItems ()
DECLARE SUB EraseSnake (a)
DECLARE SUB FillRect (r1, c1, r2, c2, ch, attr)
DECLARE SUB FindCell (rr, cc)
DECLARE SUB FontClose ()
DECLARE SUB FontOpen ()
DECLARE SUB Intro ()
DECLARE SUB Level (what)
DECLARE SUB LoadConfig ()
DECLARE SUB LoadGlyphs ()
DECLARE SUB LoadHigh ()
DECLARE SUB PlaceEggs ()
DECLARE SUB PlaceFixedMines ()
DECLARE SUB PlayNibbles ()
DECLARE SUB PutChar (row, col, ch, attr)
DECLARE SUB PutPixel (row, col, c)
DECLARE SUB PutStr (row, col, s$, attr)
DECLARE SUB QueueTurn (who, d)
DECLARE SUB ReadKeys ()
DECLARE SUB RedrawRows (r1, r2)
DECLARE SUB RunBfs (useDoors)
DECLARE SUB FixEggs ()
DECLARE FUNCTION DoorWaitMs ()
DECLARE SUB PollWait ()
DECLARE SUB RestoreGlyphs ()
DECLARE SUB SaveConfig ()
DECLARE SUB SaveHigh ()
DECLARE SUB SetBlink (flag)
DECLARE SUB ShowWait ()
DECLARE SUB Sfx (n)
DECLARE SUB SpawnBonus ()
DECLARE SUB SpawnHeart ()
DECLARE SUB SpawnMine ()
DECLARE SUB Tick ()

'---- Constants ---------------------------------------------------------------
CONST TRUE = -1
CONST FALSE = 0
CONST MAXSNAKELENGTH = 1000
CONST STARTLEN = 5
CONST NUMLEVELS = 25
CONST MAXMINE = 3         'mines on the screen at the same time
CONST MINECHAR = 15       'character used for a mine
CONST MAXEGG = 30         'eggs per level (at most)
CONST EGGGLYPH = 1        'character code redefined as a filled egg
CONST VERSIONTXT = "VERSION 13"   'shown on the title screen
CONST MAXLIVES = 9
CONST MAXFIX = 8          'fixed mines per level (at most)
CONST STARTOVER = 1       'parameters of the Level SUB
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

'---- Variables shared by both modules (COMMON SHARED; keep identical in both) ----
COMMON SHARED arena(), sammy() AS snakeType, sammyBody() AS snakeBody
COMMON SHARED qn(), pal(), minTime(), hiName$, lvOrder(), hsName$()
COMMON SHARED hsLevel(), hsCount, rankOf(), hsScore() AS LONG, nm$()
COMMON SHARED vidSeg AS LONG, highScore AS LONG, curLevel, numPlayers
COMMON SHARED speedSet, speedUp, startLevel, theme, soundOn, mineMode
COMMON SHARED doorsOn, wallStone, endMode, bonOn, fxCount, heartOn
COMMON SHARED heartDone, doorState, abortGame, victory, splitLevel
COMMON SHARED prepWhat, spaceHit, pendingEsc, deferDraw

'---- Global variables of this module only ------------------------------------
'The playfield is 80 x 50 "pixels": every text character holds two pixels
'(upper and lower half block).  arena() stores the colour of each pixel.
DIM SHARED qd(1 TO 2, 1 TO 3)                      'buffered turns per snake
DIM SHARED minRow(1 TO MAXMINE), minCol(1 TO MAXMINE)
DIM SHARED hitMine(1 TO 2)
DIM SHARED eggRow(1 TO MAXEGG), eggCol(1 TO MAXEGG)
DIM SHARED fxRow(1 TO MAXFIX), fxCol(1 TO MAXFIX)     'fixed mines
DIM SHARED bfsD(0 TO 3999), bfsQ(0 TO 3999)        'path search (one entry per pixel)
DIM SHARED eggChr, glyphsOn
DIM SHARED gCode(1 TO 4), gNew$(1 TO 4), gOld$(1 TO 4)
DIM SHARED loopsPerMs AS SINGLE
DIM SHARED bonRow, bonCol, bonTime, eggLeft, eggTotal
DIM SHARED heartRow, heartCol, heartTime, heartMax, tickCnt
DIM SHARED doorTimer, doorRow                      'side doors
DIM SHARED newHigh, anyDead, levelDone, stepMs
DIM SHARED fileFail, fileBusy

'---- Arrays shared with NIBBLEUI.BAS (dimensioned here, at program start) -----
DIM arena(1 TO 50, 1 TO 80)                       'colour of each pixel
DIM sammy(1 TO 2) AS snakeType
DIM sammyBody(0 TO MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
DIM qn(1 TO 2)
DIM pal(1 TO 18)                                   'colour table, see ApplyTheme
DIM minTime(1 TO MAXMINE)
DIM lvOrder(1 TO NUMLEVELS)                        'level order, easy to hard
DIM hsName$(1 TO 10)
DIM hsLevel(1 TO 10)
DIM rankOf(1 TO 2)
DIM hsScore(1 TO 10) AS LONG                       'high score table
DIM nm$(1 TO 2)

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

'Level order from easy to hard.  The numbers are the level definitions in
'the Level SUB:  1 empty arena, 2 centre bar, 3 two columns, 7 fence,
'13 bunkers, 11 box with gates, 14 pinwheel, 12 plus sign, 5 inner box,
'15 diamond, 18 crossed diagonals, 4 offset bars, 9 diagonals, 19 fortress,
'6 corridors, 10 dotted columns, 16 pillars, 8 comb, 17 serpentine,
'20 nested boxes, 21 to 25 divided arenas (the doors are the only way over).
lvOrder(1) = 1: lvOrder(2) = 2: lvOrder(3) = 3: lvOrder(4) = 7
lvOrder(5) = 13: lvOrder(6) = 11: lvOrder(7) = 14: lvOrder(8) = 12
lvOrder(9) = 5: lvOrder(10) = 15: lvOrder(11) = 18: lvOrder(12) = 4
lvOrder(13) = 9: lvOrder(14) = 19: lvOrder(15) = 6: lvOrder(16) = 10
lvOrder(17) = 16: lvOrder(18) = 8: lvOrder(19) = 17: lvOrder(20) = 20
lvOrder(21) = 21: lvOrder(22) = 22: lvOrder(23) = 23: lvOrder(24) = 24
lvOrder(25) = 25
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
'  TRUE if an item (egg, bonus, heart, mine) already sits on the text cell
FUNCTION CellBusy (rr, cc)
    CellBusy = FALSE
    FOR e = 1 TO MAXEGG
        IF eggRow(e) = rr AND eggCol(e) = cc THEN CellBusy = TRUE
    NEXT e
    IF bonOn THEN
        IF bonRow = rr AND bonCol = cc THEN CellBusy = TRUE
    END IF
    IF heartOn THEN
        IF heartRow = rr AND heartCol = cc THEN CellBusy = TRUE
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            IF minRow(m) = rr AND minCol(m) = cc THEN CellBusy = TRUE
        END IF
    NEXT m
    FOR m = 1 TO fxCount
        IF fxRow(m) = rr AND fxCol(m) = cc THEN CellBusy = TRUE
    NEXT m
    IF doorState > 0 THEN                       'keep the door lanes free
        IF rr >= doorRow AND rr <= doorRow + 3 THEN
            IF cc <= 7 OR cc >= 74 THEN CellBusy = TRUE
        END IF
    END IF
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
    DoorFree = TRUE
    FOR k = 0 TO 3
        bit = 2 ^ k
        IF mask AND bit THEN
            r = doorRow + k
            IF arena(r * 2 - 1, 1) <> pal(4) OR arena(r * 2, 1) <> pal(4) THEN DoorFree = FALSE
            IF arena(r * 2 - 1, 80) <> pal(4) OR arena(r * 2, 80) <> pal(4) THEN DoorFree = FALSE
        END IF
    NEXT k
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
                    doorTimer = DoorTicks(1500)
                    Sfx 9
                ELSE
                    doorTimer = DoorTicks(3000)
                END IF
            END IF
        CASE 1
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                DoorBlink 1, FALSE
                DoorSet 0, FALSE
                DoorSet 2, FALSE
                doorState = 2
                doorTimer = DoorTicks(250)
            ELSE
                DoorBlink 1, (doorTimer \ 2) AND 1
            END IF
        CASE 2
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                DoorSet 1, FALSE
                DoorSet 3, FALSE
                doorState = 3
                doorTimer = DoorTicks(20000)
            END IF
        CASE 3
            doorTimer = doorTimer - 1
            IF doorTimer <= 0 THEN
                doorState = 4
                doorTimer = DoorTicks(1500)
                Sfx 9
            END IF
        CASE 4
            IF doorTimer > 0 THEN doorTimer = doorTimer - 1
            IF doorTimer > 0 THEN
                DoorBlink 2, (doorTimer \ 2) AND 1
            ELSEIF DoorFree(15) THEN
                DoorBlink 2, FALSE
                DoorSet 1, TRUE
                DoorSet 3, TRUE
                doorState = 5
                doorTimer = DoorTicks(250)
            ELSE
                DoorBlink 2, (tickCnt \ 2) AND 1      'a snake is inside: wait
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
        DoorWaitMs = 5000 + INT(RND * 6000)
    ELSE
        DoorWaitMs = 10000 + INT(RND * 15000)
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
'  Status line (row 1): names, lives, scores, level, eggs left, high score
SUB DrawHud
    hb = pal(12) * 16
    FillRect 1, 1, 1, 80, 32, pal(11) + hb
    hc = 12

    lv = sammy(1).lives
    IF lv < 0 THEN lv = 0
    IF lv > MAXLIVES THEN lv = MAXLIVES
    PutStr 1, 2, nm$(1), pal(1) + hb
    PutStr 1, 11, CHR$(3), hc + hb
    PutStr 1, 13, LTRIM$(STR$(lv)), pal(11) + hb
    PutStr 1, 16, Num7$(sammy(1).score), pal(11) + hb

    DrawHudCenter pal(16)

    IF numPlayers = 2 THEN
        lv = sammy(2).lives
        IF lv < 0 THEN lv = 0
        IF lv > MAXLIVES THEN lv = MAXLIVES
        PutStr 1, 58, Num7$(sammy(2).score), pal(11) + hb
        PutStr 1, 66, CHR$(3), hc + hb
        PutStr 1, 68, LTRIM$(STR$(lv)), pal(11) + hb
        PutStr 1, 71, nm$(2), pal(2) + hb
    ELSE
        PutStr 1, 62, "P=Pause  ESC=Quit", pal(11) + hb
    END IF
END SUB

'DrawHudCenter:
'  Middle of the status line: level, eggs left (colour eggFg), high score
SUB DrawHudCenter (eggFg)
    hb = pal(12) * 16
    a$ = "LEVEL" + STR$(curLevel) + "   "
    b$ = CHR$(eggChr) + STR$(eggLeft)
    c$ = "   HI " + Num7$(highScore)
    sc = (80 - LEN(a$) - LEN(b$) - LEN(c$)) \ 2 + 1
    FillRect 1, 24, 1, 57, 32, pal(11) + hb
    PutStr 1, sc, a$, pal(11) + hb
    PutStr 1, sc + LEN(a$), b$, eggFg + hb
    PutStr 1, sc + LEN(a$) + LEN(b$), c$, pal(11) + hb
END SUB

'DrawItems:
'  Draws the eggs, the bonus diamond, the heart and the mines
SUB DrawItems
    FOR e = 1 TO MAXEGG
        IF eggRow(e) > 0 THEN PutChar eggRow(e), eggCol(e), eggChr, pal(9) + pal(4) * 16
    NEXT e
    IF bonOn THEN PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
    IF heartOn THEN
        hc = 12
        PutChar heartRow, heartCol, 3, hc + pal(4) * 16
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN PutChar minRow(m), minCol(m), MINECHAR, pal(15) + pal(4) * 16
    NEXT m
    FOR m = 1 TO fxCount
        PutChar fxRow(m), fxCol(m), MINECHAR, pal(15) + pal(4) * 16
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
'  Finds a free text cell (both pixels empty, no item) for an item
SUB FindCell (rr, cc)
    tries = 0
    DO
        tries = tries + 1
        p = INT(RND * 46) + 4
        cc = INT(RND * 78) + 2
        IF p AND 1 THEN q = p + 1 ELSE q = p - 1
        rr = (p + 1) \ 2
        ok = (arena(p, cc) = pal(4)) AND (arena(q, cc) = pal(4))
        IF ok THEN
            IF CellBusy(rr, cc) THEN ok = FALSE
        END IF
    LOOP UNTIL ok OR tries > 2000
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
                eggRow(e) = 0
                FindCell r, c
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
'  1 egg (character 1), 2 heart (3), 3 diamond (4), 4 mine (15)
FUNCTION GlyphData$ (k)
    SELECT CASE k
        CASE 1
            g$ = CHR$(0) + CHR$(0) + CHR$(24) + CHR$(60) + CHR$(60) + CHR$(126) + CHR$(126) + CHR$(255)
            g$ = g$ + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(126) + CHR$(126) + CHR$(60) + CHR$(24) + CHR$(0)
        CASE 2
            g$ = CHR$(0) + CHR$(0) + CHR$(102) + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(255) + CHR$(126)
            g$ = g$ + CHR$(126) + CHR$(60) + CHR$(60) + CHR$(24) + CHR$(0) + CHR$(0) + CHR$(0) + CHR$(0)
        CASE 3
            g$ = CHR$(0) + CHR$(24) + CHR$(24) + CHR$(60) + CHR$(60) + CHR$(126) + CHR$(126) + CHR$(255)
            g$ = g$ + CHR$(255) + CHR$(126) + CHR$(126) + CHR$(60) + CHR$(60) + CHR$(24) + CHR$(24) + CHR$(0)
        CASE ELSE
            g$ = CHR$(0) + CHR$(24) + CHR$(24) + CHR$(153) + CHR$(126) + CHR$(126) + CHR$(255) + CHR$(255)
            g$ = g$ + CHR$(255) + CHR$(255) + CHR$(126) + CHR$(126) + CHR$(153) + CHR$(24) + CHR$(24) + CHR$(0)
    END SELECT
    GlyphData$ = g$
END FUNCTION

'ItemInRect:
'  TRUE if an egg, bonus, heart or mine sits inside the text cell rectangle
FUNCTION ItemInRect (r1, c1, r2, c2)
    ItemInRect = FALSE
    FOR e = 1 TO eggTotal
        IF eggRow(e) >= r1 AND eggRow(e) <= r2 AND eggCol(e) >= c1 AND eggCol(e) <= c2 THEN ItemInRect = TRUE
    NEXT e
    IF bonOn THEN
        IF bonRow >= r1 AND bonRow <= r2 AND bonCol >= c1 AND bonCol <= c2 THEN ItemInRect = TRUE
    END IF
    IF heartOn THEN
        IF heartRow >= r1 AND heartRow <= r2 AND heartCol >= c1 AND heartCol <= c2 THEN ItemInRect = TRUE
    END IF
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            IF minRow(m) >= r1 AND minRow(m) <= r2 AND minCol(m) >= c1 AND minCol(m) <= c2 THEN ItemInRect = TRUE
        END IF
    NEXT m
    FOR m = 1 TO fxCount
        IF fxRow(m) >= r1 AND fxRow(m) <= r2 AND fxCol(m) >= c1 AND fxCol(m) <= c2 THEN ItemInRect = TRUE
    NEXT m
END FUNCTION

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
                INPUT #1, n1$, n2$, np, sp, su, sl, th, so, mo
                IF NOT fileFail THEN
                    nm$(1) = CleanName$(n1$, "SAMMY")
                    nm$(2) = CleanName$(n2$, "JAKE")
                    IF np = 1 OR np = 2 THEN numPlayers = np
                    IF sp >= 1 AND sp <= 10 THEN speedSet = sp
                    speedUp = (su <> 0)
                    IF sl >= 1 AND sl <= NUMLEVELS THEN startLevel = sl
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
'  Redefines the characters of the egg, heart, diamond and mine as filled
'  shapes (8 x 16 pixels).  Everything is read back; if the video card does
'  not accept the new shapes the old ones are put back and the normal
'  characters (hollow circle for the egg) stay in use.
SUB LoadGlyphs
    IF vidSeg <> &HB800& THEN EXIT SUB
    gCode(1) = EGGGLYPH: gCode(2) = 3: gCode(3) = 4: gCode(4) = 15
    FOR k = 1 TO 4
        gNew$(k) = GlyphData$(k)
    NEXT k
    ok = TRUE
    FontOpen
    DEF SEG = &HA000&
    FOR k = 1 TO 4
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
        FOR k = 1 TO 4
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
        dx = ABS(c - sammy(a).col)
        dy = ABS(r * 2 - sammy(a).row)
        dy2 = ABS(r * 2 - 1 - sammy(a).row)
        IF dy2 < dy THEN dy = dy2
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
    eggTotal = 8 + curLevel
    IF eggTotal > 25 THEN eggTotal = 25
    eggLeft = eggTotal
    FOR e = 1 TO MAXEGG
        eggRow(e) = 0
        eggCol(e) = 0
    NEXT e
    FOR e = 1 TO eggTotal
        IF deferDraw THEN PollWait
        FOR attempt = 1 TO 40
            FindCell r, c
            okFar = TRUE
            FOR a = 1 TO numPlayers
                dx = ABS(c - sammy(a).col)
                dy = ABS(r * 2 - sammy(a).row)
                dy2 = ABS(r * 2 - 1 - sammy(a).row)
                IF dy2 < dy THEN dy = dy2
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
    want = curLevel \ 2
    IF want > 6 THEN want = 6
    IF want < 1 THEN EXIT SUB
    IF numPlayers = 2 THEN want = ((want + 1) \ 2) * 2

    FOR attempt = 1 TO 3
        IF deferDraw THEN PollWait
        fxCount = 0
        tries = 0
        DO WHILE fxCount < want AND tries < 200
            tries = tries + 1
            FindCell r, c
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
    FOR a = 1 TO 2
        sammy(a).lives = 5
        sammy(a).score = 0
    NEXT a

    ClearScreen pal(4) * 16 + 7
    ShowWait
    Level STARTOVER
    DrawHud
    Dialog "L E V E L" + STR$(curLevel), "Collect" + STR$(eggTotal) + " eggs", "Press SPACE to start"
    Sfx 1

    gameOver = FALSE
    DO
        IF abortGame THEN EXIT DO                'ESC in a message box
        'speed of this level
        stepMs = 180 - speedSet * 16
        IF speedUp THEN stepMs = INT(stepMs * .93 ^ (curLevel - startLevel))
        IF stepMs < 8 THEN stepMs = 8
        DoorReset

        bonOn = FALSE
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
            Sfx 3
            FOR a = 1 TO numPlayers
                IF NOT sammy(a).alive THEN sammy(a).lives = sammy(a).lives - 1
            NEXT a
            variant = INT(RND * 3) + 1
            FOR a = 1 TO numPlayers
                IF NOT sammy(a).alive THEN DeathAnim a, variant
            NEXT a
            FOR a = 1 TO numPlayers
                EraseSnake a
            NEXT a
            bonOn = FALSE
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
            IF endMode = 1 AND curLevel >= NUMLEVELS THEN
                'the last level is done: life bonus and the end of the game
                FOR a = 1 TO numPlayers
                    AddScore a, sammy(a).lives * 1000
                NEXT a
                DrawHud
                victory = TRUE
                gameOver = TRUE
                Dialog "ALL" + STR$(NUMLEVELS) + " LEVELS COMPLETE!", "Life bonus: 1000 per life", "Press SPACE"
            ELSE
                prepWhat = NEXTLEVEL                  'the next level is built behind the message
                Dialog "LEVEL COMPLETE!", "Bonus +500 points", "Press SPACE"
                IF abortGame THEN EXIT DO
                DrawHud
                Dialog "L E V E L" + STR$(curLevel), "Collect" + STR$(eggTotal) + " eggs", "Press SPACE to start"
            END IF
        END IF
    LOOP UNTIL gameOver

    'enter the scores in the high score table
    FOR a = 1 TO numPlayers
        rankOf(a) = AddToTable(nm$(a), sammy(a).score, curLevel)
    NEXT a
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
            CASE CHR$(27)
                IF AskYesNo("Quit to the menu?") THEN
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
    FOR k = 1 TO 4
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
        CASE 1: PLAY "MBT160O1>L20CDEDCDL10ECC"        'level start
        CASE 2: PLAY "MBO0L16>CCCE"                    'number eaten
        CASE 3: PLAY "MBO0L32EFGEFDC"                  'crash
        CASE 4: PLAY "MBT160O2L16CEGO3CEGO4C"          'level complete
        CASE 5: PLAY "MBT200O3L32EGB>CL16E"            'bonus
        CASE 6: PLAY "MBT200O1L32DC"                    'mine appears
        CASE 7: PLAY "MBT220O2L32GBGB"                  'heart appears
        CASE 8: PLAY "MBT180O3L16CEGB>CE"               'heart caught
        CASE 9: PLAY "MBT200O2L32CEC"                   'door warning
    END SELECT
END SUB

'SpawnBonus:
'  Puts a bonus diamond on a free spot
SUB SpawnBonus
    FindCell r, c
    bonRow = r
    bonCol = c
    bonOn = TRUE
    bonTime = 10000 \ (stepMs + 10)
    PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
END SUB

'SpawnHeart:
'  Puts the heart on the reachable cell that is farthest (by real path
'  length) from the snakes.  The time limit follows from that distance.
SUB SpawnHeart
    RunBfs FALSE

    best = -1
    bestR = 0
    bestC = 0
    FOR rr = 2 TO 25
        FOR cc = 2 TO 79
            d1 = bfsD((rr * 2 - 2) * 80 + cc - 1)
            d2 = bfsD((rr * 2 - 1) * 80 + cc - 1)
            IF d1 >= 0 AND d2 >= 0 THEN
                dd = d1
                IF d2 < dd THEN dd = d2
                IF dd > best THEN
                    IF NOT CellBusy(rr, cc) THEN
                        best = dd
                        bestR = rr
                        bestC = cc
                    END IF
                END IF
            END IF
        NEXT cc
    NEXT rr

    IF best >= 6 THEN
        heartRow = bestR
        heartCol = bestC
        heartMax = best + best \ 3 + 12
        heartTime = heartMax
        heartOn = TRUE
        heartDone = TRUE
        hc = 12
        PutChar heartRow, heartCol, 3, hc + pal(4) * 16
        Sfx 7
    END IF
END SUB

'SpawnMine:
'  Puts a mine on a free spot that is not close to any snake head.  The
'  required distance grows with the game speed (about 0.7 seconds of travel).
SUB SpawnMine
    slot = 0
    FOR m = 1 TO MAXMINE
        IF minTime(m) <= 0 AND slot = 0 THEN slot = m
    NEXT m
    IF slot = 0 THEN EXIT SUB

    minDist = 700 \ stepMs
    IF minDist < 6 THEN minDist = 6
    IF minDist > 30 THEN minDist = 30

    FOR attempt = 1 TO 60
        FindCell r, c
        okFar = (arena(r * 2 - 1, c) = pal(4)) AND (arena(r * 2, c) = pal(4))
        FOR a = 1 TO numPlayers
            dx = ABS(c - sammy(a).col)
            dy = ABS(r * 2 - sammy(a).row)
            dy2 = ABS(r * 2 - 1 - sammy(a).row)
            IF dy2 < dy THEN dy = dy2
            IF dx <= minDist AND dy <= minDist THEN okFar = FALSE
        NEXT a
        IF okFar THEN
            minRow(slot) = r
            minCol(slot) = c
            minTime(slot) = 12000 \ (stepMs + 10)
            PutChar r, c, MINECHAR, pal(15) + pal(4) * 16
            Sfx 6
            EXIT SUB
        END IF
    NEXT attempt
END SUB

'Tick:
'  One step of the game: timers, move all snakes, collisions, eating
SUB Tick
    tickCnt = (tickCnt + 1) AND 255
    IF (tickCnt AND 3) = 0 THEN BlinkHud
    IF doorsOn OR splitLevel THEN DoorTick

    'the bonus diamond flashes and disappears after a while
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

    'mines flash and disappear after a while
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN
            minTime(m) = minTime(m) - 1
            IF minTime(m) = 0 THEN
                DrawCell minRow(m), minCol(m)
            ELSEIF (minTime(m) AND 3) = 0 THEN
                IF (minTime(m) AND 4) = 0 THEN fc = pal(15) ELSE fc = pal(9)
                PutChar minRow(m), minCol(m), MINECHAR, fc + pal(4) * 16
            END IF
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
                IF minRow(m) = rr AND minCol(m) = c THEN
                    dead = TRUE
                    hitMine(a) = TRUE
                    minTime(m) = 0
                    DrawCell minRow(m), minCol(m)
                END IF
            END IF
        NEXT m
        FOR m = 1 TO fxCount
            IF fxRow(m) = rr AND fxCol(m) = c THEN
                dead = TRUE
                hitMine(a) = TRUE
            END IF
        NEXT m

        IF dead THEN
            sammy(a).alive = FALSE
            anyDead = TRUE
        ELSE
            'old head becomes body
            hd = sammy(a).head
            PutPixel sammyBody(hd, a).row, sammyBody(hd, a).col, BodyColor(a, hd)
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
                        IF mineMode = 2 OR mineMode = 4 THEN
                            IF INT(RND * 3) = 0 THEN SpawnMine
                        END IF
                        IF eggLeft = 1 AND NOT heartDone THEN SpawnHeart
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
        END IF
    NEXT a
END SUB

'TryChooseDoor:
'  Picks a row for the next door pair.  The lanes in front of both doors
'  must be empty (no wall, snake, item or mine).  FALSE if none was found.
FUNCTION TryChooseDoor
    TryChooseDoor = FALSE
    FOR attempt = 1 TO 30
        r = INT(RND * 19) + 3
        ok = TRUE
        FOR pr = r * 2 - 1 TO (r + 3) * 2
            IF arena(pr, 2) <> pal(4) OR arena(pr, 3) <> pal(4) OR arena(pr, 4) <> pal(4) THEN ok = FALSE: EXIT FOR
            IF arena(pr, 77) <> pal(4) OR arena(pr, 78) <> pal(4) OR arena(pr, 79) <> pal(4) THEN ok = FALSE: EXIT FOR
        NEXT pr
        IF ok THEN
            IF ItemInRect(r, 2, r + 3, 7) THEN ok = FALSE
        END IF
        IF ok THEN
            IF ItemInRect(r, 74, r + 3, 79) THEN ok = FALSE
        END IF
        IF ok THEN
            doorRow = r
            TryChooseDoor = TRUE
            EXIT FUNCTION
        END IF
    NEXT attempt
END FUNCTION
