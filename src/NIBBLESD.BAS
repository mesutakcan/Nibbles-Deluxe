'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  An improved version of the classic Microsoft QBasic Nibbles (1990).
'
'  https://github.com/mesutakcan/Nibbles-Deluxe
'  Version 18
'  2026-10-28
'
'  Written for QuickBASIC 4.5 (QB45), in two modules (NIBBLESD.BAS + NIBBLEUI.BAS).
'  QB64-PE builds NIBBLESD_ALL.BAS, the same code merged into one file.
'  For detailed information, please refer to the README.md file.
'===========================================================================

'$DYNAMIC
DEFINT A-Z


'---- Declarations shared by both modules (types, constants, COMMON SHARED) ----
'$INCLUDE: 'NIBBLES.BI'

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
DECLARE SUB MineBoom (rr, cc)
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
DECLARE SUB ShrinkSnake (a, n)
DECLARE SUB Sfx (n)
DECLARE SUB SpawnBonus ()
DECLARE SUB HeartSpawn ()
DECLARE SUB PrepareHeart ()
DECLARE SUB PutHeart (rr, cc, d)
DECLARE SUB SpawnMine ()
DECLARE SUB SpawnPill ()
DECLARE SUB Tick ()

'---- Constants used in this module only --------------------------------------
CONST MAXSNAKELENGTH = 1000
CONST MAXEGG = 30         'eggs per level (at most)
CONST EGGGLYPH = 1        'character code redefined as a filled egg
CONST MAXLIVES = 9
CONST PILLCUT = 3         'segments a pill takes off the snake (one egg gives 3)
CONST PILLPTS = 250       'points for a pill

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
DIM fxGone(1 TO MAXFIX)                           'exploded fixed mines (not drawn)

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

'Level order from easy to hard (tightness, length of the routes and how
'many places can only be reached through a narrow gap were measured).  The
'numbers are the level definitions in the Level SUB:  1 empty arena,
'2 centre bar, 3 two columns, 7 fence, 13 bunkers, 11 box with gates,
'14 pinwheel, 15 diamond, 18 crossed diagonals, 4 offset bars, 12 plus sign,
'19 fortress, 6 corridors, 9 diagonals, 16 pillars, 8 comb, 5 inner box,
'17 serpentine, 20 nested boxes, 10 dotted columns, 21 to 25 divided arenas
'(the doors are the only way over).
lvOrder(1) = 1: lvOrder(2) = 2: lvOrder(3) = 3: lvOrder(4) = 7
lvOrder(5) = 13: lvOrder(6) = 11: lvOrder(7) = 14: lvOrder(8) = 15
lvOrder(9) = 18: lvOrder(10) = 4: lvOrder(11) = 12: lvOrder(12) = 19
lvOrder(13) = 6: lvOrder(14) = 9: lvOrder(15) = 16: lvOrder(16) = 8
lvOrder(17) = 5: lvOrder(18) = 17: lvOrder(19) = 20: lvOrder(20) = 10
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
    bfsFresh = TRUE
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
    IF doorState > 0 THEN                       'keep the door lanes free
        IF rr >= doorRow AND rr <= doorRow + 3 THEN
            IF cc <= 7 OR cc >= 74 THEN EXIT FUNCTION
        END IF
    END IF
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
        bfsFresh = FALSE                          'the last path search may still count removed mines
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
            IF endMode = 1 AND curLevel >= NUMLEVELS THEN
                'the last level is done: life bonus and the end of the game
                FOR a = 1 TO numPlayers
                    AddScore a, sammy(a).lives * 1000
                NEXT a
                DrawHud
                victory = TRUE
                gameOver = TRUE
                dlgBg = 2                             'dark green window
                Dialog "ALL" + STR$(NUMLEVELS) + " LEVELS COMPLETE!", "Life bonus: 1000 per life", "Press SPACE"
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
                    dx = ABS(bc - sammy(a).col)
                    dy = ABS(br * 2 - 1 - sammy(a).row)
                    dy2 = ABS(br * 2 - sammy(a).row)
                    IF dy2 < dy THEN dy = dy2
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
        CASE 7: PLAY "MBMNT220O2L32GBGB"                  'heart appears
        CASE 8: PLAY "MBMNT180O3L16CEGB>CE"               'heart caught
        CASE 9: PLAY "MBMNT200O2L32CEC"                   'door warning
        CASE 10: PLAY "T255MSL64O1GFEDCO0BAGFEDCP64O2GFEDCO1BAGFEDC"   'mine explosion
        CASE 11: PLAY "MBMNT190O3L32CDEFGAB>CL16EGL8>C"   'pill eaten (rising run, then a bright chord)
        CASE 12: PLAY "MBMNT220O4L32EP32EP32>C"           'pill appears (short alert)
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

'SpawnBonus:
'  Puts a bonus star on a free spot
SUB SpawnBonus
    FindCell r, c
    bonRow = r
    bonCol = c
    bonOn = TRUE
    bonTime = 10000 \ (stepMs + 10)
    PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
END SUB

'HeartSpawn:
'  The heart appears at the prepared corner place that is farthest from the
'  nearest snake (path length estimated from the straight line distance and
'  the path / straight line ratio worked out when the arena was built).  If no
'  corner place can be used, 40 random free places are tried.  Nothing here is
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
                        dx = ABS(hcCol(k) - sammy(a).col)
                        dy = ABS(hcRow(k) * 2 - 1 - sammy(a).row)
                        dy2 = ABS(hcRow(k) * 2 - sammy(a).row)
                        IF dy2 < dy THEN dy = dy2
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

    'no corner place: the farthest of 40 random free places that can be reached
    best = -1
    br = 0
    bc = 0
    FOR t = 1 TO 40
        rr = 3 + INT(RND * 22)
        cc = 2 + INT(RND * 78)
        p = (rr * 2 - 2) * 80 + cc - 1
        IF bfsD(p) >= 0 AND bfsD(p + 80) >= 0 THEN
            IF arena(rr * 2 - 1, cc) = pal(4) AND arena(rr * 2, cc) = pal(4) THEN
                IF NOT CellBusy(rr, cc) THEN
                    dmin = 32000
                    FOR a = 1 TO numPlayers
                        IF sammy(a).alive THEN
                            dx = ABS(cc - sammy(a).col)
                            dy = ABS(rr * 2 - 1 - sammy(a).row)
                            dy2 = ABS(rr * 2 - sammy(a).row)
                            IF dy2 < dy THEN dy = dy2
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
            EXIT SUB
        END IF
    NEXT attempt
END SUB

'SpawnPill:
'  Puts a pill on a free spot (once per level, twice on levels with more than 20 eggs)
SUB SpawnPill
    FindCell r, c
    pillRow = r
    pillCol = c
    pillClr = 11
    IF pal(4) = 3 THEN pillClr = 13           'light cyan would vanish on cyan
    pillOn = TRUE
    pillCnt = pillCnt + 1
    pillTime = 10000 \ (stepMs + 10)
    PutChar pillRow, pillCol, 5, pillClr + pal(4) * 16
    Sfx 12
END SUB

'Tick:
'  One step of the game: timers, move all snakes, collisions, eating
SUB Tick
    tickCnt = (tickCnt + 1) AND 255
    IF (tickCnt AND 3) = 0 THEN BlinkHud
    IF doorsOn OR splitLevel THEN DoorTick

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
                        'the 1st pill comes 2 to 12 seconds after the 3rd egg; levels with more
                        'than 20 eggs get a 2nd one after half of the eggs, once the 1st is gone
                        pillMax = 1
                        IF eggTotal > 20 THEN pillMax = 2
                        IF pillCnt < pillMax AND pillWait = 0 AND NOT pillOn THEN
                            IF pillCnt = 0 THEN need = 3 ELSE need = eggTotal \ 2
                            IF eggTotal - eggLeft >= need THEN
                                pillWait = 2000 \ (stepMs + 10) + INT(RND * (10000 \ (stepMs + 10))) + 1
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

