Lexibomb
========

A tile-based word game similar to Scrabble, but the letter and word multipliers
for each game are based on the proximity to randomly placed bombs. As the
neighboring bomb counts get higher (think Minesweeper), the larger the
multiplier grows for your letter/word...although if you hit a bomb, your word
earns no points.

- The initial board gives no clue as of to where the bombs are located.
- Play tiles anywhere and it will open up the board information like clicks in
  Minesweeper.

<iframe src="https://player.vimeo.com/video/126956439" width="600" height="376" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> <p><a href="https://vimeo.com/126956439">Lexibomb Game Demo</a> from <a href="https://vimeo.com/elasticdog">Aaron Bull Schaefer</a> on <a href="https://vimeo.com">Vimeo</a>.</p>

### Gameplay Notes

- The play button only becomes enabled when a valid play is on the board
  (meaning proper placement of tiles and creating words that exist in the
  dictionary).
- You do not have to specify a letter for blank tiles, all possible words are
  tested. This also means that the blank tiles may represent different letters
  for words in the differing orientations (vertical / horizontal).

![Example Ending Board](images/end-game.png)

Scoring
-------

| Tile | Multiplier | Neighboring Bombs | Notes |
|:----:|:----------:|:-----------------:|:-----:|
| ![White Blank Tile](images/blank-tile.png) | 1 x L | 0 | Letters played on these tiles are worth thier face value |
| ![Double Letter Tile](images/two-dots-tile.png) | 2 x L | 1 | Double letter tile |
| ![Triple Letter Tile](images/three-dots-tile.png) | 3 x L | 2 | Triple letter tile |
| ![Double Word Tile](images/two-lines-tile.png) | 2 x W | 3 | Double word tile |
| ![Triple Word Tile](images/three-lines-tile.png) | 3 x W | 4+ | Triple word tile |
| ![Red Bomb Tile](images/bomb-tile.png) | 0 x W<sup>*</sup> | N/A | Bomb tile; no points awarded for this word |

\* _Note: The 0 x W multiplier for bomb tiles only happens when the tile is first revealed...subsequent turns treat the spot as a 1 x L._

| Tile | Notes |
|:----:|:-----:|
| ![Gray Current Play Tile](images/current-turn-tile.png) | Gray tiles are shown for the current player's turn, before final submission |
| ![Blue Previously Play Tile](images/played-tile.png) | Blue tiles are shown for all previously played tiles |

### Letter Points

| A - M ||||||||||||||
|:------------------------------------------------------------:|
| _Letter_ | A | B | C | D | E | F | G | H | I | J | K | L | M |
| _Points_ | 1 | 3 | 3 | 2 | 1 | 4 | 2 | 4 | 1 | 8 | 5 | 1 | 3 |

| N - Z ||||||||||||||
|:--------------------------------------------------------------:|
| _Letter_ | N | O | P | Q  | R | S | T | U | V | W | X | Y | Z  |
| _Points_ | 1 | 1 | 3 | 10 | 1 | 1 | 1 | 1 | 4 | 4 | 8 | 4 | 10 |

**Blanks [ _ ]** = 0 Points

### Tileset

| A - M ||||||||||||||
|:------------------------------------------------------------:|
| _Tile_  | A | B | C | D | E  | F | G | H | I | J | K | L | M |
| _Count_ | 9 | 2 | 2 | 4 | 12 | 2 | 3 | 2 | 9 | 1 | 1 | 4 | 2 |

| N - Z ||||||||||||||
|:-----------------------------------------------------------:|
| _Tile_  | N | O | P | Q | R | S | T | U | V | W | X | Y | Z |
| _Count_ | 6 | 8 | 2 | 1 | 6 | 4 | 6 | 4 | 2 | 2 | 1 | 2 | 1 |

**Blanks [ _ ]** = 2 Tiles

Word List
---------

The list of words that Lexibomb uses to validate plays comes from Release
5 of Alan Beale's [12dicts project][]; more specifically, Lexibomb checks
validity against the [2of12inf][] word list with all of the plural
"uncountables" included.

[12dicts project]: http://wordlist.aspell.net/12dicts/
[2of12inf]: http://wordlist.aspell.net/12dicts-readme/#2of12inf

### Two-Letter Words

```
ad   ah   am   an   as   at   aw   ax   ay
be   bi   by
do
ed   eh   em   en   ex
fa
go
ha   he   hi   ho
id   if   in   is   it
la   lo
ma   me   mi   mu   my
no   nu
of   oh   om   on   op   or   ow   ox
pa   pi
re
sh   so
ti   to
uh   um   up   us
we
xi
ya   ye   yo
```

What's Missing
--------------

These are the game mechanics that currently have not been implemented:

- A mechanism to exchange tiles.
- Enforcment of passing/exchange rules...if a player scores zero points for
  three consecutive turns, the game should end.
- Bonus points for using all seven tiles in a single play (A.K.A. a bingo).
- End of game scoring...when a player runs out of tiles, the remaining tile
  values for the other player should be subtracted from their score.

Legal
-----

Scrabble is a registered trademark of Hasbro Inc./Milton Bradley, and Mattel/JW Spear & Sons plc.

Minesweeper is a registered trademark of Microsoft.
