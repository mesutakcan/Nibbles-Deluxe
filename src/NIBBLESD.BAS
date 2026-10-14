'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  An improved version of the classic Microsoft QBasic Nibbles (1990).

'  https://github.com/mesutakcan/Nibbles-Deluxe
'  Version 3
'  2026-10-09
'===========================================================================

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
DECLARE FUNCTION AskYesNo (msg$)
DECLARE FUNCTION BannerRow$ (i)
DECLARE FUNCTION BodyColor (a, idx)
DECLARE FUNCTION GameOverScreen ()
DECLARE FUNCTION MainMenu ()
DECLARE FUNCTION Num7$ (v&)
DECLARE FUNCTION PointIsThere (row, col)
DECLARE SUB AddScore (a, pts)
DECLARE SUB ApplyTheme ()
DECLARE SUB Calibrate ()
DECLARE SUB Center (row, text$, attr)
DECLARE SUB ChangeSetting (sel, d)
DECLARE SUB ClearScreen (attr)
DECLARE SUB DelayMs (ms)
DECLARE SUB Dialog (t1$, t2$, hint$)
DECLARE SUB DrawBanner (row, phase, withShadow)
DECLARE SUB DrawBox (r1, c1, r2, c2, attr)
DECLARE SUB DrawCell (r, c)
DECLARE SUB DrawHud ()
DECLARE SUB DrawItems ()
DECLARE SUB DrawMenu (sel)
DECLARE SUB EraseSnake (a)
DECLARE SUB FillRect (r1, c1, r2, c2, ch, attr)
DECLARE SUB FindCell (rr, cc)
DECLARE SUB FlashSnake (a)
DECLARE SUB Intro ()
DECLARE SUB Level (what)
DECLARE SUB LoadHigh ()
DECLARE SUB PlaceNumber ()
DECLARE SUB PlayNibbles ()
DECLARE SUB PutChar (row, col, ch, attr)
DECLARE SUB PutPixel (row, col, c)
DECLARE SUB PutStr (row, col, s$, attr)
DECLARE SUB QueueTurn (who, d)
DECLARE SUB ReadKeys ()
DECLARE SUB RedrawRows (r1, r2)
DECLARE SUB SaveHigh ()
DECLARE SUB SetBlink (flag)
DECLARE SUB Sfx (n)
DECLARE SUB SparklePause ()
DECLARE SUB SpawnBonus ()
DECLARE SUB SpawnMine ()
DECLARE SUB Tick ()
DECLARE SUB Wall (row, col)

'---- Constants ---------------------------------------------------------------
CONST TRUE = -1
CONST FALSE = 0
CONST MAXSNAKELENGTH = 1000
CONST STARTLEN = 5
CONST NUMLEVELS = 12
CONST MAXMINE = 3         'mines on the screen at the same time
CONST MINECHAR = 15       'character used for a mine
CONST STARTOVER = 1       'parameters of the Level SUB
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

'---- Global variables --------------------------------------------------------
'The playfield is 80 x 50 "pixels": every text character holds two pixels
'(upper and lower half block).  arena() stores the colour of each pixel.
DIM SHARED arena(1 TO 50, 1 TO 80)
DIM SHARED sammy(1 TO 2) AS snakeType
DIM SHARED sammyBody(0 TO MAXSNAKELENGTH - 1, 1 TO 2) AS snakeBody
DIM SHARED qd(1 TO 2, 1 TO 3), qn(1 TO 2)       'buffered turns per snake
DIM SHARED pal(1 TO 15)                           'colour table, see ApplyTheme
DIM SHARED minRow(1 TO MAXMINE), minCol(1 TO MAXMINE), minTime(1 TO MAXMINE)
DIM SHARED hitMine(1 TO 2)
DIM SHARED nm$(1 TO 2)
DIM SHARED vidSeg AS LONG
DIM SHARED highScore AS LONG
DIM SHARED loopsPerMs AS SINGLE
DIM SHARED curLevel, numPlayers, speedSet, speedUp, startLevel, theme, soundOn, minesOn
DIM SHARED numRow, numCol, numVal, bonRow, bonCol, bonOn, bonTime
DIM SHARED newHigh, abortGame, anyDead, levelDone, stepMs
DIM SHARED fileFail, fileBusy

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
startLevel = 1: theme = 1: soundOn = TRUE: minesOn = TRUE
ApplyTheme
LoadHigh
SetBlink FALSE                'allows 16 background colours
LOCATE , , 0                  'hide the cursor

ClearScreen 7
Center 12, "Please wait...", 7
Calibrate

Intro
quitAll = FALSE
DO
    IF NOT MainMenu THEN EXIT DO
    ApplyTheme
    DO
        PlayNibbles
        IF abortGame THEN EXIT DO
        choice = GameOverScreen
        IF choice = 3 THEN quitAll = TRUE
    LOOP WHILE choice = 1
LOOP UNTIL quitAll

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
'  Adds points to a player and keeps the high score up to date
SUB AddScore (a, pts)
    sammy(a).score = sammy(a).score + pts
    IF sammy(a).score > highScore THEN
        highScore = sammy(a).score
        newHigh = TRUE
    END IF
END SUB

'AskYesNo:
'  Small yes/no box, returns TRUE for Y
FUNCTION AskYesNo (msg$)
    w = LEN(msg$) + 8
    IF w < 30 THEN w = 30
    c1 = (80 - w) \ 2 + 1
    c2 = c1 + w - 1
    attr = pal(5) + pal(6) * 16
    DrawBox 8, c1, 12, c2, attr
    Center 9, msg$, attr
    Center 11, "[Y] Yes        [N] No", attr
    DO WHILE INKEY$ <> "": LOOP
    DO
        k$ = UCASE$(INKEY$)
    LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
    AskYesNo = (k$ = "Y")
    RedrawRows 7, 13
END FUNCTION

'ApplyTheme:
'  Fills the colour table.  Entries:
'   1 snake 1 body   2 snake 2 body   3 walls        4 background
'   5 dialog text    6 dialog back    7 snake 1 head  8 snake 2 head
'   9 number colour 10 bonus colour  11 status text  12 status back
'  13 snake 1 stripe 14 snake 2 stripe 15 mine colour
SUB ApplyTheme
    SELECT CASE theme
        CASE 1                                  'Classic (blue)
            pal(1) = 14: pal(2) = 13: pal(3) = 12: pal(4) = 1
            pal(5) = 15: pal(6) = 4: pal(7) = 15: pal(8) = 15
            pal(9) = 15: pal(10) = 10: pal(11) = 15: pal(12) = 0
            pal(13) = 6: pal(14) = 5: pal(15) = 12
        CASE 2                                  'Night (black)
            pal(1) = 10: pal(2) = 11: pal(3) = 9: pal(4) = 0
            pal(5) = 15: pal(6) = 1: pal(7) = 15: pal(8) = 15
            pal(9) = 14: pal(10) = 13: pal(11) = 15: pal(12) = 1
            pal(13) = 2: pal(14) = 3: pal(15) = 12
        CASE ELSE                               'Mono
            pal(1) = 15: pal(2) = 7: pal(3) = 8: pal(4) = 0
            pal(5) = 0: pal(6) = 7: pal(7) = 7: pal(8) = 15
            pal(9) = 15: pal(10) = 15: pal(11) = 7: pal(12) = 0
            pal(13) = 7: pal(14) = 7: pal(15) = 15
    END SELECT
END SUB

'BodyColor:
'  Body colour of a snake segment: two shades alternate along the body
FUNCTION BodyColor (a, idx)
    IF idx AND 1 THEN BodyColor = pal(a) ELSE BodyColor = pal(12 + a)
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
            IF startLevel > NUMLEVELS THEN startLevel = NUMLEVELS
        CASE 5
            theme = theme + d
            IF theme > 3 THEN theme = 1
            IF theme < 1 THEN theme = 3
        CASE 6
            soundOn = NOT soundOn
        CASE 7
            minesOn = NOT minesOn
    END SELECT
END SUB

'ClearScreen:
'  Clears the whole screen with the given attribute
SUB ClearScreen (attr)
    FillRect 1, 1, 25, 80, 32, attr
END SUB

'DelayMs:
'  Waits roughly the given number of milliseconds
SUB DelayMs (ms)
    DIM i AS LONG, n AS LONG
    n = ms * loopsPerMs
    IF n < 1 THEN n = 1
    FOR i = 1 TO n: NEXT i
END SUB

'Dialog:
'  Message box in the upper part of the screen, waits for SPACE or ENTER
SUB Dialog (t1$, t2$, hint$)
    w = LEN(t1$)
    IF LEN(t2$) > w THEN w = LEN(t2$)
    IF LEN(hint$) > w THEN w = LEN(hint$)
    w = w + 8
    IF w < 34 THEN w = 34
    c1 = (80 - w) \ 2 + 1
    c2 = c1 + w - 1
    attr = pal(5) + pal(6) * 16
    DrawBox 8, c1, 12, c2, attr
    Center 9, t1$, attr
    Center 10, t2$, attr
    Center 11, hint$, attr
    DO WHILE INKEY$ <> "": LOOP
    DO
        k$ = INKEY$
    LOOP UNTIL k$ = " " OR k$ = CHR$(13)
    RedrawRows 7, 13
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
'  Status line (row 1): names, lives, scores, level and high score
SUB DrawHud
    hb = pal(12) * 16
    FillRect 1, 1, 1, 80, 32, pal(11) + hb
    IF theme = 3 THEN hc = pal(11) ELSE hc = 12

    lv = sammy(1).lives
    IF lv < 0 THEN lv = 0
    IF lv > 5 THEN lv = 5
    PutStr 1, 2, nm$(1), pal(1) + hb
    PutStr 1, 9, STRING$(lv, 3) + SPACE$(5 - lv), hc + hb
    PutStr 1, 15, Num7$(sammy(1).score), pal(11) + hb

    Center 1, "LEVEL" + STR$(curLevel) + "    HI " + Num7$(highScore), pal(11) + hb

    IF numPlayers = 2 THEN
        lv = sammy(2).lives
        IF lv < 0 THEN lv = 0
        IF lv > 5 THEN lv = 5
        PutStr 1, 60, Num7$(sammy(2).score), pal(11) + hb
        PutStr 1, 68, STRING$(lv, 3) + SPACE$(5 - lv), hc + hb
        PutStr 1, 74, nm$(2), pal(2) + hb
    ELSE
        PutStr 1, 62, "P=Pause  ESC=Quit", pal(11) + hb
    END IF
END SUB

'DrawItems:
'  Draws the current number and the bonus diamond (if any)
SUB DrawItems
    IF numRow > 0 THEN PutChar numRow, numCol, 48 + numVal, pal(9) + pal(4) * 16
    IF bonOn THEN PutChar bonRow, bonCol, 4, pal(10) + pal(4) * 16
    FOR m = 1 TO MAXMINE
        IF minTime(m) > 0 THEN PutChar minRow(m), minCol(m), MINECHAR, pal(15) + pal(4) * 16
    NEXT m
END SUB

'DrawMenu:
'  Draws the settings menu, sel is the highlighted line
SUB DrawMenu (sel)
    FOR i = 1 TO 9
        r = 10 + i
        IF i >= 8 THEN r = r + 1
        IF i = sel THEN attr = 0 + 7 * 16 ELSE attr = 7
        FillRect r, 19, r, 62, 32, attr
        SELECT CASE i
            CASE 1: lab$ = "Players"
            CASE 2: lab$ = "Speed"
            CASE 3: lab$ = "Faster each level"
            CASE 4: lab$ = "Start level"
            CASE 5: lab$ = "Colors"
            CASE 6: lab$ = "Sound"
            CASE 7: lab$ = "Mines"
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
                    CASE ELSE: v$ = "MONO"
                END SELECT
            CASE 6
                IF soundOn THEN v$ = "ON" ELSE v$ = "OFF"
            CASE 7
                IF minesOn THEN v$ = "ON" ELSE v$ = "OFF"
            CASE ELSE
                v$ = ""
        END SELECT
        IF i <= 7 THEN
            PutStr r, 22, lab$, attr
            IF i = sel THEN
                v$ = CHR$(17) + " " + v$ + " " + CHR$(16)
                PutStr r, 42, v$, attr
            ELSE
                PutStr r, 44, v$, 15
            END IF
        ELSEIF i = 8 THEN
            Center r, "S T A R T   G A M E", attr
        ELSE
            Center r, "Q U I T", attr
        END IF
    NEXT i
END SUB

'EraseSnake:
'  Removes a snake from the screen
SUB EraseSnake (a)
    FOR k = 0 TO sammy(a).count - 1
        idx = (sammy(a).head - k + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
        PutPixel sammyBody(idx, a).row, sammyBody(idx, a).col, pal(4)
    NEXT k
    sammy(a).count = 0
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

'FindCell:
'  Finds a free text cell (both pixels empty) for a number or bonus
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
            IF numRow = rr AND numCol = cc THEN ok = FALSE
            IF bonOn THEN
                IF bonRow = rr AND bonCol = cc THEN ok = FALSE
            END IF
            FOR m = 1 TO MAXMINE
                IF minTime(m) > 0 THEN
                    IF minRow(m) = rr AND minCol(m) = cc THEN ok = FALSE
                END IF
            NEXT m
        END IF
    LOOP UNTIL ok OR tries > 2000
END SUB

'FlashSnake:
'  Death animation: the snake flashes white
SUB FlashSnake (a)
    FOR f = 1 TO 6
        IF f AND 1 THEN fc = 15 ELSE fc = pal(a)
        FOR k = 0 TO sammy(a).count - 1
            idx = (sammy(a).head - k + MAXSNAKELENGTH) MOD MAXSNAKELENGTH
            PutPixel sammyBody(idx, a).row, sammyBody(idx, a).col, fc
        NEXT k
        DelayMs 70
    NEXT f
END SUB

'GameOverScreen:
'  Shows the results, returns 1 = play again, 2 = menu, 3 = quit
FUNCTION GameOverScreen
    attr = pal(5) + pal(6) * 16
    DrawBox 6, 22, 18, 59, attr
    Center 8, "G A M E   O V E R", attr

    l1$ = nm$(1) + SPACE$(8 - LEN(nm$(1))) + Num7$(sammy(1).score)
    IF numPlayers = 2 THEN
        l2$ = nm$(2) + SPACE$(8 - LEN(nm$(2))) + Num7$(sammy(2).score)
        Center 10, l1$, attr
        Center 11, l2$, attr
        IF sammy(1).score > sammy(2).score THEN
            res$ = nm$(1) + " WINS!"
        ELSEIF sammy(2).score > sammy(1).score THEN
            res$ = nm$(2) + " WINS!"
        ELSE
            res$ = "IT IS A DRAW!"
        END IF
        Center 13, res$, attr
    ELSE
        Center 11, l1$, attr
    END IF
    IF newHigh THEN
        Center 14, "*  NEW HIGH SCORE!  *", attr
    ELSE
        Center 14, "High score" + STR$(highScore), attr
    END IF
    Center 16, "ENTER = play again", attr
    Center 17, "M = menu      ESC = quit", attr

    DO WHILE INKEY$ <> "": LOOP
    DO
        k$ = INKEY$
        SELECT CASE k$
            CASE CHR$(13), "y", "Y"
                GameOverScreen = 1
                EXIT DO
            CASE "m", "M"
                GameOverScreen = 2
                EXIT DO
            CASE CHR$(27), "n", "N"
                GameOverScreen = 3
                EXIT DO
        END SELECT
    LOOP
END FUNCTION

'Intro:
'  Animated title screen
SUB Intro
    ClearScreen 7
    DrawBanner 3, 0, TRUE
    Center 10, "D E L U X E   E D I T I O N", 14
    Center 11, "based on Microsoft QBasic Nibbles (C) 1990", 8

    Center 13, "Steer your snake around the arena and eat the numbers in order,", 7
    Center 14, "from 1 to 9.  Every number makes you longer and gives more points.", 7
    Center 15, "Grab the flashing diamond for a bonus.  Never hit a wall, the other", 7
    Center 16, "snake, your own tail or a red mine (mines pop up from time to time)!", 7

    Center 18, "PLAYER 1  -  arrow keys  (or keypad 8 2 4 6)", 11
    Center 19, "PLAYER 2  -  W A S D     (W A S D also work in 1 player mode)", 13
    Center 20, "P = pause           ESC = quit to menu", 7

    IF soundOn THEN PLAY "MBT160O1L8CDEDCDL4ECC"
    SparklePause
END SUB

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

    'outer wall
    FOR c = 1 TO 80
        Wall 3, c
        Wall 50, c
    NEXT c
    FOR r = 4 TO 49
        Wall r, 1
        Wall r, 80
    NEXT r

    lv = ((curLevel - 1) MOD NUMLEVELS) + 1
    SELECT CASE lv
        CASE 1
            sammy(1).row = 25: sammy(2).row = 25
            sammy(1).col = 50: sammy(2).col = 30
            sammy(1).direction = 4: sammy(2).direction = 3

        CASE 2
            FOR i = 20 TO 60
                Wall 25, i
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 60: sammy(2).col = 20
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 3
            FOR i = 10 TO 40
                Wall i, 20
                Wall i, 60
            NEXT i
            sammy(1).row = 25: sammy(2).row = 25
            sammy(1).col = 50: sammy(2).col = 30
            sammy(1).direction = 1: sammy(2).direction = 2

        CASE 4
            FOR i = 4 TO 30
                Wall i, 20
                Wall 53 - i, 60
            NEXT i
            FOR i = 2 TO 40
                Wall 38, i
                Wall 15, 81 - i
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 60: sammy(2).col = 20
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 5
            FOR i = 13 TO 39
                Wall i, 21
                Wall i, 59
            NEXT i
            FOR i = 23 TO 57
                Wall 11, i
                Wall 41, i
            NEXT i
            sammy(1).row = 25: sammy(2).row = 25
            sammy(1).col = 50: sammy(2).col = 30
            sammy(1).direction = 1: sammy(2).direction = 2

        CASE 6
            FOR i = 4 TO 49
                IF i > 30 OR i < 23 THEN
                    Wall i, 10
                    Wall i, 20
                    Wall i, 30
                    Wall i, 40
                    Wall i, 50
                    Wall i, 60
                    Wall i, 70
                END IF
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 2: sammy(2).direction = 1

        CASE 7
            FOR i = 4 TO 49 STEP 2
                Wall i, 40
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 2: sammy(2).direction = 1

        CASE 8
            FOR i = 4 TO 40
                Wall i, 10
                Wall 53 - i, 20
                Wall i, 30
                Wall 53 - i, 40
                Wall i, 50
                Wall 53 - i, 60
                Wall i, 70
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 2: sammy(2).direction = 1

        CASE 9
            FOR i = 6 TO 47
                Wall i, i
                Wall i, i + 28
            NEXT i
            sammy(1).row = 40: sammy(2).row = 15
            sammy(1).col = 75: sammy(2).col = 5
            sammy(1).direction = 1: sammy(2).direction = 2

        CASE 10
            FOR i = 4 TO 49 STEP 2
                Wall i, 10
                Wall i + 1, 20
                Wall i, 30
                Wall i + 1, 40
                Wall i, 50
                Wall i + 1, 60
                Wall i, 70
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 2: sammy(2).direction = 1

        CASE 11                          'a box with four gates
            FOR i = 25 TO 55
                IF i < 37 OR i > 43 THEN
                    Wall 15, i
                    Wall 35, i
                END IF
            NEXT i
            FOR i = 15 TO 35
                IF i < 23 OR i > 27 THEN
                    Wall i, 25
                    Wall i, 55
                END IF
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE ELSE                        'level 12: a big plus sign
            FOR i = 2 TO 79
                IF i < 36 OR i > 44 THEN Wall 26, i
            NEXT i
            FOR i = 4 TO 49
                IF i < 22 OR i > 30 THEN Wall i, 40
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4
    END SELECT

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
        FOR j = 0 TO STARTLEN - 1
            back = STARTLEN - 1 - j
            sr = sammy(a).row - back * dr
            sc = sammy(a).col - back * dc
            sammyBody(j, a).row = sr
            sammyBody(j, a).col = sc
            IF j = STARTLEN - 1 THEN arena(sr, sc) = pal(6 + a) ELSE arena(sr, sc) = BodyColor(a, j)
        NEXT j
        sammy(a).head = STARTLEN - 1
        sammy(a).count = STARTLEN
        sammy(a).length = STARTLEN
    NEXT a

    numVal = 0: numRow = 0: bonOn = FALSE
    FOR m = 1 TO MAXMINE
        minTime(m) = 0
    NEXT m
    RedrawRows 2, 25
END SUB

'LoadHigh:
'  Reads the high score from NIBBLES.HI
SUB LoadHigh
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.HI" FOR APPEND AS #1       'creates the file if missing
    CLOSE #1
    IF NOT fileFail THEN
        OPEN "NIBBLES.HI" FOR INPUT AS #1
        IF NOT fileFail THEN
            IF NOT EOF(1) THEN INPUT #1, highScore
            CLOSE #1
        END IF
    END IF
    fileBusy = FALSE
    IF highScore < 0 THEN highScore = 0
END SUB

'MainMenu:
'  Settings menu.  Returns TRUE to start a game, FALSE to quit
FUNCTION MainMenu
    ClearScreen 7
    DrawBanner 2, 0, TRUE
    DrawBox 9, 18, 22, 63, 11
    Center 9, " S E T T I N G S ", 14
    Center 23, "UP/DOWN select    LEFT/RIGHT change    ENTER start    ESC quit", 7
    Center 24, "High score:" + STR$(highScore), 14

    sel = 8
    DO
        DrawMenu sel
        DO
            k$ = INKEY$
        LOOP WHILE k$ = ""
        SELECT CASE k$
            CASE CHR$(0) + "H"
                sel = sel - 1
                IF sel < 1 THEN sel = 9
            CASE CHR$(0) + "P"
                sel = sel + 1
                IF sel > 9 THEN sel = 1
            CASE CHR$(0) + "K"
                ChangeSetting sel, -1
            CASE CHR$(0) + "M"
                ChangeSetting sel, 1
            CASE " "
                IF sel <= 7 THEN ChangeSetting sel, 1
            CASE CHR$(13)
                IF sel = 9 THEN MainMenu = FALSE ELSE MainMenu = TRUE
                EXIT DO
            CASE CHR$(27)
                MainMenu = FALSE
                EXIT DO
        END SELECT
    LOOP
END FUNCTION

'Num7$:
'  Number as a right aligned string of 7 characters
FUNCTION Num7$ (v&)
    Num7$ = RIGHT$(SPACE$(7) + LTRIM$(STR$(v&)), 7)
END FUNCTION

'PlaceNumber:
'  Puts the next number on a free spot
SUB PlaceNumber
    numRow = 0
    FindCell r, c
    numRow = r
    numCol = c
    PutChar numRow, numCol, 48 + numVal, pal(9) + pal(4) * 16
END SUB

'PlayNibbles:
'  Plays one complete game
SUB PlayNibbles
    abortGame = FALSE
    newHigh = FALSE
    FOR a = 1 TO 2
        sammy(a).lives = 5
        sammy(a).score = 0
    NEXT a

    ClearScreen pal(4) * 16 + 7
    Level STARTOVER
    DrawHud
    Dialog "L E V E L" + STR$(curLevel), "Get ready!", "Press SPACE to start"
    Sfx 1

    gameOver = FALSE
    DO
        'speed of this level
        stepMs = 180 - speedSet * 16
        IF speedUp THEN stepMs = INT(stepMs * .93 ^ (curLevel - startLevel))
        IF stepMs < 8 THEN stepMs = 8

        numVal = 1
        bonOn = FALSE
        hitMine(1) = FALSE
        hitMine(2) = FALSE
        PlaceNumber
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
            FOR a = 1 TO numPlayers
                IF NOT sammy(a).alive THEN FlashSnake a
            NEXT a
            FOR a = 1 TO numPlayers
                EraseSnake a
            NEXT a
            numRow = 0
            bonOn = FALSE
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
                Level SAMELEVEL
                DrawHud
                Dialog msg$, "Try again!", "Press SPACE to continue"
            END IF
        ELSE
            'level completed
            Sfx 4
            FOR a = 1 TO numPlayers
                AddScore a, 500
            NEXT a
            DrawHud
            Dialog "LEVEL COMPLETE!", "Bonus +500 points", "Press SPACE"
            Level NEXTLEVEL
            DrawHud
            Dialog "L E V E L" + STR$(curLevel), "Get ready!", "Press SPACE to start"
        END IF
    LOOP UNTIL gameOver

    IF newHigh THEN SaveHigh
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

'PutChar:
'  Writes one character with an attribute directly into video memory
SUB PutChar (row, col, ch, attr)
    ofs = (row - 1) * 160 + (col - 1) * 2
    DEF SEG = vidSeg
    POKE ofs, ch
    POKE ofs + 1, attr
    DEF SEG
END SUB

'PutPixel:
'  Sets a pixel of the 80 x 50 playfield and redraws its text character
SUB PutPixel (row, col, c)
    IF row < 3 OR row > 50 OR col < 1 OR col > 80 THEN EXIT SUB
    arena(row, col) = c
    rr = (row + 1) \ 2
    DrawCell rr, col
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
    FOR r = r1 TO r2
        FOR c = 1 TO 80
            DrawCell r, c
        NEXT c
    NEXT r
    DrawItems
END SUB

'SaveHigh:
'  Writes the high score to NIBBLES.HI
SUB SaveHigh
    fileFail = FALSE
    fileBusy = TRUE
    OPEN "NIBBLES.HI" FOR OUTPUT AS #1
    IF NOT fileFail THEN
        PRINT #1, highScore
        CLOSE #1
    END IF
    fileBusy = FALSE
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
    END SELECT
END SUB

'SparklePause:
'  Flashing border and colour cycling logo until a key is pressed
SUB SparklePause
    ph = 0
    DO WHILE INKEY$ <> "": LOOP
    DO
        FOR p = 0 TO 205
            IF p < 80 THEN
                r = 1: c = p + 1
            ELSEIF p < 104 THEN
                r = p - 80 + 2: c = 80
            ELSEIF p < 183 THEN
                r = 25: c = 79 - (p - 104)
            ELSE
                r = 24 - (p - 183): c = 1
            END IF
            IF ((p + ph) MOD 5) = 0 THEN
                IF p AND 1 THEN fc = 12 ELSE fc = 14
                PutChar r, c, 15, fc
            ELSE
                PutChar r, c, 32, 7
            END IF
        NEXT p
        DrawBanner 3, ph, FALSE
        IF ph AND 1 THEN
            Center 22, "Press any key to continue", 15
        ELSE
            Center 22, "Press any key to continue", 8
        END IF
        ph = ph + 1
        DelayMs 80
    LOOP WHILE INKEY$ = ""
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
'  One step of the game: lifetime of the bonus, move all snakes, collisions
SUB Tick
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

            'did the head reach the number or the bonus?
            rr = (r + 1) \ 2
            IF numRow = rr AND numCol = c THEN
                Sfx 2
                IF sammy(a).length < MAXSNAKELENGTH - 60 THEN
                    sammy(a).length = sammy(a).length + numVal * 4
                END IF
                AddScore a, numVal * 100
                numVal = numVal + 1
                numRow = 0
                IF numVal = 10 THEN
                    levelDone = TRUE
                ELSE
                    PlaceNumber
                    IF NOT bonOn THEN
                        IF INT(RND * 3) = 0 THEN SpawnBonus
                    END IF
                    IF minesOn THEN
                        IF INT(RND * 3) = 0 THEN SpawnMine
                    END IF
                END IF
                DrawHud
            END IF
            IF bonOn THEN
                IF bonRow = rr AND bonCol = c THEN
                    bonOn = FALSE
                    Sfx 5
                    AddScore a, 500
                    DrawHud
                END IF
            END IF
        END IF
    NEXT a
END SUB

'Wall:
'  Marks a pixel as wall (the screen is drawn later by RedrawRows)
SUB Wall (row, col)
    IF row >= 1 AND row <= 50 AND col >= 1 AND col <= 80 THEN arena(row, col) = pal(3)
END SUB
