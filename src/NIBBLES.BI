'===========================================================================
'                     N I B B L E S   D E L U X E
'
'  NIBBLES.BI - declarations shared by the two modules NIBBLESD.BAS and
'  NIBBLEUI.BAS.  Both modules include it at the top (INCLUDE metacommand),
'  so the user defined types, the constants used by both modules and the
'  COMMON SHARED variable list are written only once.
'  Declarations only: no executable statements, no SUB or FUNCTION.
'  A constant that only one module uses is defined in that module.
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

'---- Constants used by both modules ------------------------------------------
CONST TRUE = -1
CONST FALSE = 0
CONST STARTLEN = 5
CONST NECKLEN = 2          'plain (unstriped) body parts right behind the head
CONST NUMLEVELS = 25
CONST MAXMINE = 3         'mines on the screen at the same time
CONST MINECHAR = 15       'character used for a mine
CONST MAXFIX = 8          'fixed mines per level (at most)
CONST STARTOVER = 1       'parameters of the Level SUB
CONST SAMELEVEL = 2
CONST NEXTLEVEL = 3

'---- Variables shared by both modules (COMMON SHARED) -------------------------
COMMON SHARED arena(), sammy() AS snakeType, sammyBody() AS snakeBody
COMMON SHARED qn(), pal(), minTime(), hiName$, lvOrder(), hsName$()
COMMON SHARED hsLevel(), hsCount, rankOf(), hsScore() AS LONG, nm$()
COMMON SHARED vidSeg AS LONG, highScore AS LONG, curLevel, numPlayers
COMMON SHARED speedSet, speedUp, startLevel, theme, soundOn, mineMode
COMMON SHARED doorsOn, wallStone, endMode, bonOn, fxCount, heartOn
COMMON SHARED heartDone, doorState, abortGame, victory, splitLevel
COMMON SHARED prepWhat, spaceHit, pendingEsc, deferDraw
COMMON SHARED eggChr, fxGone()
COMMON SHARED pillOn, pillCnt
COMMON SHARED dlgBg
