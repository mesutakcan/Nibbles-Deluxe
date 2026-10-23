'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  Module 2 of 2 (NIBBLEUI.BAS): screens, menus, drawing helpers and the
'  level layouts.  The main module is NIBBLESD.BAS.
'
'  https://github.com/mesutakcan/Nibbles-Deluxe
'  Version 14
'  2026-10-20
'
'  Build: both modules are compiled with BC and linked together.
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
DECLARE FUNCTION AskYesNo (msg$)
DECLARE FUNCTION BannerRow$ (i)
DECLARE FUNCTION BodyColor (a, idx)
DECLARE FUNCTION CleanName$ (n$, dflt$)
DECLARE FUNCTION EggsReachable ()
DECLARE FUNCTION WallColor (row, col)
DECLARE FUNCTION GameOverScreen ()
DECLARE FUNCTION IsWallColor (c)
DECLARE FUNCTION MainMenu ()
DECLARE FUNCTION Num7$ (v&)
DECLARE SUB ApplyTheme ()
DECLARE SUB Center (row, text$, attr)
DECLARE SUB ChangeSetting (sel, d)
DECLARE SUB ClearScreen (attr)
DECLARE SUB DelayMs (ms)
DECLARE SUB Dialog (t1$, t2$, hint$)
DECLARE SUB DrawBanner (row, phase, withShadow)
DECLARE SUB DrawBox (r1, c1, r2, c2, attr)
DECLARE SUB DrawTable (r0, hl1, hl2, baseAttr, hlAttr)
DECLARE SUB DrawMenu (sel)
DECLARE SUB DrawMenuFrame ()
DECLARE SUB DrawMenuRow (i, sel)
DECLARE SUB DrawMenuHint ()
DECLARE SUB EditName (who)
DECLARE SUB FillRect (r1, c1, r2, c2, ch, attr)
DECLARE SUB Intro ()
DECLARE SUB Level (what)
DECLARE SUB PlaceEggs ()
DECLARE SUB PlaceFixedMines ()
DECLARE SUB PutChar (row, col, ch, attr)
DECLARE SUB PutStr (row, col, s$, attr)
DECLARE SUB RedrawRows (r1, r2)
DECLARE SUB RunBfs (useDoors)
DECLARE SUB FixEggs ()
DECLARE SUB PollWait ()
DECLARE SUB SetBlink (flag)
DECLARE SUB ShowScores ()
DECLARE SUB ShowWait ()
DECLARE SUB SparklePause ()
DECLARE SUB Wall (row, col)

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
CONST VERSIONTXT = "VERSION 14"   'shown on the title screen
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
        Center r, "You completed all" + STR$(NUMLEVELS) + " levels!", attr
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

    Center 13, "Steer your snake around the arena and collect all the eggs to", 7
    Center 14, "finish a level.  Every egg makes you longer and scores 100 points.", 7
    Center 15, "Catch the flashing star for a bonus and the heart for an extra life!", 7
    Center 16, "Avoid walls, the other snake, your own tail and the red mines.", 7
    Center 17, "Side doors open now and then - go through and exit on the other side!", 7

    Center 18, "PLAYER 1  -  arrow keys  (or keypad 8 2 4 6)", 11
    Center 19, "PLAYER 2  -  W A S D     (W A S D also work in 1 player mode)", 13
    Center 20, "P = pause           ESC = quit to menu", 7

    IF soundOn THEN PLAY "MBT160O1L8CDEDCDL4ECC"
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

    lv = lvOrder(((curLevel - 1) MOD NUMLEVELS) + 1)
    splitLevel = (lv >= 21)
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
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 2: sammy(2).direction = 1

        CASE 7
            FOR i = 4 TO 49 STEP 2
                Wall i, 40
            NEXT i
            sammy(1).row = 10: sammy(2).row = 43
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
            sammy(1).row = 10: sammy(2).row = 43
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
            sammy(1).row = 10: sammy(2).row = 43
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

        CASE 12                          'level 12: a big plus sign
            FOR i = 2 TO 79
                IF i < 36 OR i > 44 THEN Wall 26, i
            NEXT i
            FOR i = 4 TO 49
                IF i < 22 OR i > 30 THEN Wall i, 40
            NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 13                          'bunkers: four corner pockets
            FOR i = 2 TO 22: Wall 14, i: Wall 39, i: NEXT i
            FOR i = 59 TO 79: Wall 14, i: Wall 39, i: NEXT i
            FOR i = 4 TO 7: Wall i, 22: Wall i, 59: NEXT i
            FOR i = 46 TO 49: Wall i, 22: Wall i, 59: NEXT i
            sammy(1).row = 25: sammy(2).row = 25
            sammy(1).col = 50: sammy(2).col = 30
            sammy(1).direction = 1: sammy(2).direction = 2

        CASE 14                          'pinwheel
            FOR i = 0 TO 13: Wall 8 + i, 10 + i: Wall 8 + i, 11 + i: NEXT i
            FOR i = 0 TO 13: Wall 8 + i, 70 - i: Wall 8 + i, 71 - i: NEXT i
            FOR i = 0 TO 13: Wall 45 + i, 23 - i: Wall 45 + i, 24 - i: NEXT i
            FOR i = 0 TO 13: Wall 32 + i, 57 + i: Wall 32 + i, 58 + i: NEXT i
            FOR i = 14 TO 22: Wall i, 40: NEXT i
            FOR i = 31 TO 39: Wall i, 40: NEXT i
            sammy(1).row = 25: sammy(2).row = 25
            sammy(1).col = 50: sammy(2).col = 30
            sammy(1).direction = 4: sammy(2).direction = 3

        CASE 15                          'diamond
            FOR i = 0 TO 11: Wall 12 + i, 36 - i: Wall 12 + i, 37 - i: NEXT i
            FOR i = 0 TO 11: Wall 12 + i, 44 + i: Wall 12 + i, 45 + i: NEXT i
            FOR i = 0 TO 9: Wall 30 + i, 27 + i: Wall 30 + i, 28 + i: NEXT i
            FOR i = 0 TO 9: Wall 30 + i, 52 - i: Wall 30 + i, 53 - i: NEXT i
            FOR i = 25 TO 27: FOR j = 38 TO 41: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 7: sammy(2).row = 46
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 16                          'pillars
            FOR i = 9 TO 12: FOR j = 10 TO 13: Wall i, j: NEXT j: NEXT i
            FOR i = 9 TO 12: FOR j = 24 TO 27: Wall i, j: NEXT j: NEXT i
            FOR i = 9 TO 12: FOR j = 38 TO 41: Wall i, j: NEXT j: NEXT i
            FOR i = 9 TO 12: FOR j = 52 TO 55: Wall i, j: NEXT j: NEXT i
            FOR i = 9 TO 12: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 19 TO 22: FOR j = 17 TO 20: Wall i, j: NEXT j: NEXT i
            FOR i = 19 TO 22: FOR j = 31 TO 34: Wall i, j: NEXT j: NEXT i
            FOR i = 19 TO 22: FOR j = 45 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 19 TO 22: FOR j = 59 TO 62: Wall i, j: NEXT j: NEXT i
            FOR i = 19 TO 22: FOR j = 73 TO 76: Wall i, j: NEXT j: NEXT i
            FOR i = 29 TO 32: FOR j = 10 TO 13: Wall i, j: NEXT j: NEXT i
            FOR i = 29 TO 32: FOR j = 24 TO 27: Wall i, j: NEXT j: NEXT i
            FOR i = 29 TO 32: FOR j = 38 TO 41: Wall i, j: NEXT j: NEXT i
            FOR i = 29 TO 32: FOR j = 52 TO 55: Wall i, j: NEXT j: NEXT i
            FOR i = 29 TO 32: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 39 TO 42: FOR j = 17 TO 20: Wall i, j: NEXT j: NEXT i
            FOR i = 39 TO 42: FOR j = 31 TO 34: Wall i, j: NEXT j: NEXT i
            FOR i = 39 TO 42: FOR j = 45 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 39 TO 42: FOR j = 59 TO 62: Wall i, j: NEXT j: NEXT i
            FOR i = 39 TO 42: FOR j = 73 TO 76: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 7: sammy(2).row = 46
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 17                          'serpentine
            FOR i = 2 TO 70: Wall 13, i: Wall 33, i: NEXT i
            FOR i = 10 TO 79: Wall 23, i: Wall 43, i: NEXT i
            sammy(1).row = 7: sammy(2).row = 46
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 18                          'crossed diagonals
            FOR i = 0 TO 33: Wall 5 + i, 10 + i: Wall 5 + i, 11 + i: NEXT i
            FOR i = 0 TO 31: Wall 14 + i, 68 - i: Wall 14 + i, 69 - i: NEXT i
            sammy(1).row = 7: sammy(2).row = 46
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 19                          'fortress
            FOR i = 18 TO 62
                IF i < 36 OR i > 44 THEN
                    Wall 12, i
                    Wall 40, i
                END IF
            NEXT i
            FOR i = 12 TO 40
                IF i < 22 OR i > 30 THEN
                    Wall i, 18
                    Wall i, 62
                END IF
            NEXT i
            FOR i = 24 TO 28: FOR j = 37 TO 42: Wall i, j: NEXT j: NEXT i
            FOR i = 17 TO 19: FOR j = 26 TO 28: Wall i, j: Wall i, j + 26: Wall i + 17, j: Wall i + 17, j + 26: NEXT j: NEXT i
            FOR i = 0 TO 9: Wall 5 + i, 5 + i: Wall 5 + i, 6 + i: NEXT i
            FOR i = 0 TO 9: Wall 5 + i, 76 - i: Wall 5 + i, 77 - i: NEXT i
            FOR i = 0 TO 9: Wall 36 + i, 14 - i: Wall 36 + i, 15 - i: NEXT i
            FOR i = 0 TO 9: Wall 36 + i, 66 + i: Wall 36 + i, 67 + i: NEXT i
            sammy(1).row = 7: sammy(2).row = 43
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 20                          'level 20: nested boxes
            FOR i = 8 TO 73: Wall 10, i: Wall 43, i: NEXT i
            FOR i = 10 TO 43: Wall i, 73: NEXT i
            FOR i = 10 TO 23: Wall i, 8: NEXT i
            FOR i = 30 TO 43: Wall i, 8: NEXT i
            FOR i = 16 TO 65: Wall 16, i: Wall 37, i: NEXT i
            FOR i = 16 TO 37: Wall i, 16: NEXT i
            FOR i = 16 TO 23: Wall i, 65: NEXT i
            FOR i = 30 TO 37: Wall i, 65: NEXT i
            FOR i = 26 TO 55: Wall 31, i: NEXT i
            FOR i = 26 TO 37: Wall 22, i: NEXT i
            FOR i = 44 TO 55: Wall 22, i: NEXT i
            FOR i = 22 TO 31: Wall i, 26: Wall i, 55: NEXT i
            sammy(1).row = 7: sammy(2).row = 46
            sammy(1).col = 65: sammy(2).col = 15
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 21                          'divided arena: divide
            FOR i = 4 TO 49: Wall i, 39: NEXT i
            FOR i = 4 TO 49: Wall i, 40: NEXT i
            FOR i = 22 TO 38: Wall 16, i: NEXT i
            FOR i = 22 TO 38: Wall 34, i: NEXT i
            FOR i = 41 TO 57: Wall 16, i: NEXT i
            FOR i = 41 TO 57: Wall 34, i: NEXT i
            FOR i = 16 TO 19: FOR j = 9 TO 12: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 29: FOR j = 51 TO 54: Wall i, j: NEXT j: NEXT i
            FOR i = 41 TO 44: FOR j = 56 TO 59: Wall i, j: NEXT j: NEXT i
            FOR i = 16 TO 19: FOR j = 71 TO 74: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 29: FOR j = 29 TO 32: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 29: FOR j = 19 TO 22: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 62: sammy(2).col = 18
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 22                          'divided arena: zigzag
            FOR i = 0 TO 11: Wall 4 + i, 46 - i: Wall 4 + i, 47 - i: NEXT i
            FOR i = 0 TO 11: Wall 15 + i, 35 + i: Wall 15 + i, 36 + i: NEXT i
            FOR i = 0 TO 11: Wall 26 + i, 46 - i: Wall 26 + i, 47 - i: NEXT i
            FOR i = 0 TO 12: Wall 37 + i, 35 + i: Wall 37 + i, 36 + i: NEXT i
            FOR i = 20 TO 23: FOR j = 12 TO 15: Wall i, j: NEXT j: NEXT i
            FOR i = 30 TO 33: FOR j = 22 TO 25: Wall i, j: NEXT j: NEXT i
            FOR i = 20 TO 23: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 30 TO 33: FOR j = 56 TO 59: Wall i, j: NEXT j: NEXT i
            FOR i = 41 TO 44: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 16 TO 19: FOR j = 51 TO 54: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 29: FOR j = 29 TO 32: Wall i, j: NEXT j: NEXT i
            FOR i = 36 TO 39: FOR j = 46 TO 49: Wall i, j: NEXT j: NEXT i
            FOR i = 31 TO 34: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 21 TO 24: FOR j = 19 TO 22: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 62: sammy(2).col = 18
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 23                          'divided arena: bulge
            FOR i = 4 TO 49: Wall i, 39: NEXT i
            FOR i = 4 TO 49: Wall i, 40: NEXT i
            FOR i = -8 TO 8: FOR j = 40 - (8 - ABS(i)) TO 41 + (8 - ABS(i)): Wall 25 + i, j: NEXT j: NEXT i
            FOR i = 12 TO 15: FOR j = 14 TO 17: Wall i, j: NEXT j: NEXT i
            FOR i = 36 TO 39: FOR j = 28 TO 31: Wall i, j: NEXT j: NEXT i
            FOR i = 12 TO 15: FOR j = 60 TO 63: Wall i, j: NEXT j: NEXT i
            FOR i = 36 TO 39: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 10 TO 24: Wall 20, i: NEXT i
            FOR i = 56 TO 70: Wall 30, i: NEXT i
            FOR i = 21 TO 24: FOR j = 61 TO 64: Wall i, j: NEXT j: NEXT i
            FOR i = 11 TO 14: FOR j = 29 TO 32: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 29: FOR j = 9 TO 12: Wall i, j: NEXT j: NEXT i
            FOR i = 16 TO 19: FOR j = 71 TO 74: Wall i, j: NEXT j: NEXT i
            FOR i = 36 TO 39: FOR j = 51 TO 54: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 62: sammy(2).col = 18
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE 24                          'divided arena: crossbars
            FOR i = 4 TO 49: Wall i, 38: NEXT i
            FOR i = 4 TO 49: Wall i, 39: NEXT i
            FOR i = 4 TO 49: Wall i, 40: NEXT i
            FOR i = 4 TO 49: Wall i, 41: NEXT i
            FOR i = 24 TO 37: Wall 14, i: NEXT i
            FOR i = 24 TO 37: Wall 36, i: NEXT i
            FOR i = 42 TO 55: Wall 14, i: NEXT i
            FOR i = 42 TO 55: Wall 36, i: NEXT i
            FOR i = 0 TO 9: Wall 18 + i, 8 + i: Wall 18 + i, 9 + i: NEXT i
            FOR i = 0 TO 9: Wall 18 + i, 72 - i: Wall 18 + i, 73 - i: NEXT i
            FOR i = 24 TO 27: FOR j = 14 TO 17: Wall i, j: NEXT j: NEXT i
            FOR i = 24 TO 27: FOR j = 64 TO 67: Wall i, j: NEXT j: NEXT i
            FOR i = 21 TO 24: FOR j = 29 TO 32: Wall i, j: NEXT j: NEXT i
            FOR i = 31 TO 34: FOR j = 71 TO 74: Wall i, j: NEXT j: NEXT i
            FOR i = 21 TO 24: FOR j = 56 TO 59: Wall i, j: NEXT j: NEXT i
            FOR i = 41 TO 44: FOR j = 66 TO 69: Wall i, j: NEXT j: NEXT i
            FOR i = 41 TO 44: FOR j = 56 TO 59: Wall i, j: NEXT j: NEXT i
            FOR i = 31 TO 34: FOR j = 9 TO 12: Wall i, j: NEXT j: NEXT i
            FOR i = 41 TO 44: FOR j = 46 TO 49: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 62: sammy(2).col = 18
            sammy(1).direction = 3: sammy(2).direction = 4

        CASE ELSE                        'level 25: divided arena: citadel
            FOR i = 4 TO 49: Wall i, 36: NEXT i
            FOR i = 4 TO 49: Wall i, 37: NEXT i
            FOR i = 4 TO 49: Wall i, 38: NEXT i
            FOR i = 4 TO 49: Wall i, 39: NEXT i
            FOR i = 4 TO 49: Wall i, 40: NEXT i
            FOR i = 4 TO 49: Wall i, 41: NEXT i
            FOR i = 4 TO 49: Wall i, 42: NEXT i
            FOR i = 4 TO 49: Wall i, 43: NEXT i
            FOR i = 10 TO 15: Wall 12, i: NEXT i
            FOR i = 23 TO 28: Wall 12, i: NEXT i
            FOR i = 10 TO 15: Wall 38, i: NEXT i
            FOR i = 23 TO 28: Wall 38, i: NEXT i
            FOR i = 12 TO 21: Wall i, 10: NEXT i
            FOR i = 29 TO 38: Wall i, 10: NEXT i
            FOR i = 12 TO 21: Wall i, 28: NEXT i
            FOR i = 29 TO 38: Wall i, 28: NEXT i
            FOR i = 52 TO 57: Wall 12, i: NEXT i
            FOR i = 65 TO 70: Wall 12, i: NEXT i
            FOR i = 52 TO 57: Wall 38, i: NEXT i
            FOR i = 65 TO 70: Wall 38, i: NEXT i
            FOR i = 12 TO 21: Wall i, 52: NEXT i
            FOR i = 29 TO 38: Wall i, 52: NEXT i
            FOR i = 12 TO 21: Wall i, 70: NEXT i
            FOR i = 29 TO 38: Wall i, 70: NEXT i
            FOR i = 22 TO 26: FOR j = 17 TO 21: Wall i, j: NEXT j: NEXT i
            FOR i = 22 TO 26: FOR j = 58 TO 62: Wall i, j: NEXT j: NEXT i
            FOR i = 31 TO 34: FOR j = 14 TO 17: Wall i, j: NEXT j: NEXT i
            FOR i = 31 TO 34: FOR j = 61 TO 64: Wall i, j: NEXT j: NEXT i
            FOR i = 6 TO 8: FOR j = 12 TO 14: Wall i, j: NEXT j: NEXT i
            FOR i = 42 TO 44: FOR j = 54 TO 56: Wall i, j: NEXT j: NEXT i
            FOR i = 14 TO 16: FOR j = 46 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 42 TO 44: FOR j = 70 TO 72: Wall i, j: NEXT j: NEXT i
            FOR i = 6 TO 8: FOR j = 46 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 6 TO 8: FOR j = 70 TO 72: Wall i, j: NEXT j: NEXT i
            FOR i = 6 TO 8: FOR j = 20 TO 22: Wall i, j: NEXT j: NEXT i
            FOR i = 38 TO 40: FOR j = 46 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 26 TO 28: FOR j = 46 TO 48: Wall i, j: NEXT j: NEXT i
            FOR i = 6 TO 8: FOR j = 28 TO 30: Wall i, j: NEXT j: NEXT i
            sammy(1).row = 10: sammy(2).row = 43
            sammy(1).col = 62: sammy(2).col = 18
            sammy(1).direction = 3: sammy(2).direction = 4
    END SELECT
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
            IF back = 0 THEN arena(sr, sc) = pal(6 + a) ELSE arena(sr, sc) = BodyColor(a, j)
            nseg = nseg + 1
        NEXT back
        sammy(a).head = STARTLEN - 1
        sammy(a).count = nseg
        sammy(a).length = STARTLEN
    NEXT a

    IF deferDraw THEN PollWait
    bonOn = FALSE: heartOn = FALSE: heartDone = FALSE
    FOR m = 1 TO MAXMINE
        minTime(m) = 0
    NEXT m
    doorState = 0
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
