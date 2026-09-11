# Motor Psycho -- discovery summary

## The cartridge

| | |
|---|---|
| ROM | `Motor Psycho (NTSC) (Atari) (1990) (1E219482).a78` |
| Size | 131,200 bytes (128-byte header + 128 KB ROM) |
| Mapper | SuperGame 64K (cart type 0x0112) |
| Vectors | NMI `$C0C2`, RESET `$C000`, IRQ `$C000` |

The SuperGame mapper has three address ranges:

- `$4000-$7FFF` fixed at bank 6 (file offset `$18000-$1BFFF`)
- `$8000-$BFFF` banked across banks 0-7 (file offset `$0000-$17FFF`)
- `$C000-$FFFF` fixed at bank 7 (file offset `$1C000-$1FFFF`)

The vectors are read from bank 7 at `$C000-$CFFF`, but the actual ROM content
spans all eight banks.

## Day one coverage

Tracing from the three hardware vectors reaches **23.7%** of the ROM
(15,470 of 65,536 bytes), leaving 50,066 bytes in 20 gaps across 8 banks.

| bank | size | bytes | instructions |
|---|---|---|---|
| f7 (bank 7) | 16 KB | 9,535 | 4,360 |
| b5 (bank 5) | 16 KB | 1,544 | 718 |
| b2 (bank 2) | 16 KB | 1,325 | 644 |
| b0 (bank 0) | 16 KB | 697 | 337 |
| b1 (bank 1) | 16 KB | 304 | 143 |

Total traced: 13,405 bytes / 6,202 instructions

## Bank-switch analysis

The code uses bank switching to access additional ROM banks. The following
sites write to `$8000` to change the bank at `$8000-$BFFF`:

| address | bank | note |
|---|---|---|
| f7:D5D4 | 2 | resolved |
| f7:D62E | 5 | resolved |
| f7:D847 | 2 | resolved |
| f7:D865 | 5 | resolved |
| f7:DA4D | 0 | resolved |
| f7:DA57 | UNRESOLVED | |
| f7:DB71 | UNRESOLVED | |
| f7:DBBD | 5 | resolved |
| f7:DBC7 | UNRESOLVED | |
| f7:DC6B | 5 | resolved |
| f7:DCBD | UNRESOLVED | |
| f7:DE4E | 3 | resolved |
| f7:DE5F | UNRESOLVED | |
| f7:DF2E | 5 | resolved |
| f7:DF91 | 3 | resolved |
| f7:DFF5 | UNRESOLVED | |
| f7:E03F | UNRESOLVED | |
| f7:E14E | 5 | resolved |
| f7:E222 | 3 | resolved |
| f7:E233 | UNRESOLVED | |
| f7:E8DF | UNRESOLVED | |
| f7:E8EA | 5 | resolved |
| f7:E91F | UNRESOLVED | |
| f7:E958 | 5 | resolved |
| f7:EDBC | 0 | resolved |
| f7:EDC7 | 5 | resolved |
| f7:F15F | 2 | resolved |
| f7:F16A | 5 | resolved |
| f7:F452 | 5 | resolved |
| f7:F5A9 | 2 | resolved |
| f7:F5B4 | 5 | resolved |
| f7:FEB9 | 1 | resolved |
| f7:FECB | 0 | resolved |
| f7:FED7 | 5 | resolved |
| f7:FEE2 | 2 | resolved |

## RAM usage

The most frequently referenced RAM addresses:

| address | refs | likely purpose |
|---|---|---|
| $005C | 89 | |
| $0067 | 70 | |
| $0050 | 64 | |
| $004A | 62 | DLI vector low |
| $0066 | 59 | |
| $005D | 43 | |
| $242E | 42 | |
| $0046 | 39 | |
| $0051 | 38 | |
| $0144 | 36 | |

## Unresolved items

The following bank-switch sites cannot be resolved statically (they use RAM
pointers or indirect jumps):

- f7:DA57, f7:DB71, f7:DBC7, f7:DCBD, f7:DE5F, f7:DFF5, f7:E03F, f7:E233,
  f7:E8DF, f7:E91F

## What's next

1. Add the unresolved bank-switch targets to `entries`
2. Trace the DLI chain via `JMP ($004A)` / `JMP ($004C)` / `JMP ($006C)`
3. Analyze the most-referenced RAM addresses to identify game state
4. Search for graphics and sound data

## Free space / Slack analysis

The ROM contains **40,445 bytes** (30.8%) of zero-padding in 938 regions of
16+ bytes. This is typical of 7800 ROM formatting.

### Slack by bank:

| bank | slack | notes |
|---|---|---|
| b0 | 1,706 bytes | Trailing zero-padding at end of bank |
| b1 | 794 bytes | Scattered padding |
| b2 | 8,502 bytes | Most slack - likely unused graphics |
| b3 | 8,359 bytes | Most slack - likely unused graphics |
| b4 | 8,358 bytes | Most slack - likely unused graphics |
| b5 | 8,536 bytes | Most slack - likely unused graphics |
| b6 | 2,930 bytes | Trailing zero-padding |
| b7 | 1,260 bytes | Trailing zero-padding |

### Total:
- **40,445 bytes** (30.8%) of zero-padding
- **86,585 bytes** of actual ROM data

### Slack patterns:
- Large trailing zeros at bank boundaries (banks 2-5)
- 128-byte padding at $04000 (end of bank 1)
- 44-byte padding at 4KB boundaries ($0A000, $0E000, $12000, $16000, $1D000)

## What's next

1. Add the unresolved bank-switch targets to `entries`
2. Trace the DLI chain via `JMP ($004A)` / `JMP ($004C)` / `JMP ($006C)`
3. Analyze the most-referenced RAM addresses to identify game state
4. Search for graphics and sound data
5. Record gameplay to identify untraced routines

## The recordings

None yet. The ROM is set up for analysis but no capture files have been
generated.

## Following the code: where a static trace gets, and why it stops

A 128K SuperGame cartridge: eight 16K banks, `$C000`-`$FFFF` fixed as bank
7 and `$8000`-`$BFFF` switched. No two banks are duplicates. Banks 0, 1 and
7 are dense code; banks 2-6 run about 40% single-value fill, which is what
graphics data looks like.

From the reset vector alone the tracer reaches:

```
b0  697/16384   4.3%      b2  1325/16384   8.1%
b1  304/16384   1.9%      b5  1544/16384   9.4%
f7 9535/16384  58.2%      b3, b4, b6, b7 -- nothing at all
```

Bank 7 is well covered because that is where reset lands and control flow
stays. Everything else is barely touched, and `--check-gaps` says why: no
real call site enters any gap -- every apparent branch into unexplored
territory is a byte coincidence. The code is not being missed for want of
following a branch. It is entered by means a static reader cannot follow.

Two such means, and they are different problems.

### 1. Each switched bank opens with a jump table

`b0:$8000` is nine consecutive `JMP`s:

```
$AE4B  $BCF7  $BD66  $BCD9  $BCB2  $BCC7  $BCD0  $8478  $84C8
```

That is the bank's public interface -- the fixed bank switches the bank in
and calls a slot. A tracer following the first `JMP` cannot fall through to
the second, which is exactly what `--check-gaps` reports: `b0:8003-800B`
skipped by `b0:8000`, `b0:800F-8017` skipped by `b0:800C`. Declaring the
nine slots as entries takes bank 0 from **4.3% to 8.9%**. Bank 1 has the
same shape with a single entry (`$B086`).

### 2. Five indirect jumps through RAM pointers

```
b5:B7F7  JMP ($004C)      f7:EC69  JMP ($004A)
f7:C0C3  JMP ($006C)      f7:FA44  JMP ($004C)
                          f7:FD13  JMP ($004C)
```

`tools/probe-vectors.lua` watches all three pointers and the SuperGame bank
select together, because on a banked cartridge the answer is two numbers
and not one: an address in `$8000`-`$BFFF` means nothing without the bank
mapped at the time. Two minutes of attract mode gives 94 distinct targets.

Adding the 25 that land in the fixed bank takes **f7 from 58.2% to 61.3%**
-- those need no bank at all, so they are unambiguous. The bank-5 ones add
**b5 9.4% -> 10.9%**.

### The catch, which cost a wrong answer

The probe records the bank selected *when the pointer is written*. The jump
happens later, and the bank can change in between -- so a (bank, address)
pair is a hypothesis, not a fact.

The 26 candidates attributed to bank 3 produced **27 instructions between
them**, which is what a set of wrong guesses looks like: each entry
disassembles a byte or two of data and stops. Bank 3 is therefore left out
of `annotations.json` rather than filed as fact. Bank 5's 35 candidates
produced 241 bytes of real code and are kept.

To settle bank 3 properly the probe needs to sample the bank at the moment
of the jump rather than at the write, which needs either an execution
breakpoint at the five `JMP` sites or a tap that reads the bank register
back. Left as the next step.

### Where that leaves it

```
b0  1458  8.9%      b2 1325  8.1%      f7 10047  61.3%
b1   304  1.9%      b5 1785 10.9%
```

14,919 of 131,072 bytes, up from 13,405. The honest summary is that bank 7
is genuinely mapped and the switched banks are not: banks 3, 4, 6 and 7
still stand at zero, and the graphics-heavy banks may never hold much code
to find.


## Two full-track recordings, and following the code for real

`run-01.inp` (270s, first track) and `run-02.inp` (each of the other
tracks) are the first live sessions this project has had. Pole Position II
was suggested as a reference for a reason worth taking seriously: same
studio-era 7800 driving game, and it turned out to share real architecture
-- an indirect-jump/vector chain in the fixed bank driving a display list,
the same shape as PP2's own "display-interrupt handler table". The manual
(atariage.com/manual_html_page.php?SoftwareID=2171) gave the numbers to
check claims against: Turn response 1-12, Straighten response 1-25, no
brakes, no qualifying lap, a jump button.

### The bank-7 input mirror was the wrong lead

Bank 7 has `sub_F1A9`/`sub_F1BA`, which read `INPT0`/`INPT1`/`SWCHA` and
mirror them into `ram_26A3`-`ram_26A5`. A probe watching that mirror for
270 seconds of continuous driving found almost no changes -- every
transition occurred exactly once, which is what a value read once at boot
looks like, not a car being steered the whole way round a track.

Tapping the hardware registers directly, with the reading PC recorded,
settled it: `sub0_858C` in **bank 0** reads `SWCHA` on 92.5% of frames --
essentially every frame -- against a handful of one-off reads everywhere
else. That is gameplay, not the bank-7 mirror. The lesson is the same one
Food Fight's vectors taught: a routine that stores an input value is not
necessarily the routine driving the game with it, and the way to tell is
to watch the hardware register's actual readers, not a RAM copy of it.

### Bank 0's controller code is the *optional second controller*, not steering

Reading further: `sub0_858C` debounces `SWCHA`, testing `AND #$0F` -- the
**low** nibble only, which is controller 2. `sub0_85B1` decodes that
nibble's four direction bits into a signed (X, Y) pair with four
`LSR`/`BCC` steps. `sub0_8478` (X axis) adds the delta to `ram_26E0`,
clamped to `$0D` (13); `sub0_84C8`'s sibling path (Y axis) clamps `ram_26E1`
to `$1A` (26). 13 and 26 states are exactly the manual's Turn (1-12) and
Straighten (1-25) ranges, off by the usual 1-indexed-display /
0-indexed-internal difference. So this entire tree --
`ram_26E0`/`TurnResponse`, `ram_26E1`/`StraightenResponse`,
`sub0_8580`/`Ctrl2_LatchInit`, `sub0_858C`/`Ctrl2_ReadDebounced`,
`sub0_85B1`/`Ctrl2_DecodeAxes` -- is the manual's "Right Controller
(Optional)" response-time adjustment, not the driver's own controls.
Genuinely player-1 steering, gear and the jump button are still open.

### The fixed-bank vector chain, and a decisive answer on bank 3

`f7:C0C3` is `JMP ($006C)`, called from inside the IRQ handler
(`sub_C272`...`sub_C293`, ending `RTI`), alongside three more in the same
handler: `f7:C299 JMP ($26A8)`, `f7:C29C JMP ($26AA)`, `f7:C29F
JMP ($26AC)`. Together with the three vectors already known
(`$4A`/`$4C` x3/`$6C`), that is nine indirect jumps, all through RAM
pointers a static tracer cannot resolve.

`tools/probe-vectors2.lua` samples all nine properly this time: a read
tap on the `JMP` instruction's own address, firing on the opcode fetch,
reading the bank register and the vector's current value at that instant.
No inference about what the bank was earlier.

Across both full-track recordings the result is clean and, this time,
unambiguous. The switched-bank targets are:

```
bank 0:  $ADCE $ADD1 $ADD4 $ADD7 $ADDA $ADDD $ADE0     (7-slot table)
bank 1:  $B003 $B006 $B009                              (3-slot table)
bank 5:  $B7FA $B818 $B8B8
```

Every other resolution across both sessions -- the great majority of all
samples -- lands in the fixed bank ($C000 and up), regardless of which
bank happened to be switched in at the time; that "bank" is incidental,
selected for some other reason, and irrelevant to where the jump goes.
Declaring the fixed-bank table (`$C083`-`$C0BF`, 21 slots stepping by 3 --
another jump table, the same shape as bank 0 and bank 1's own tables) plus
the individual targets under the other vectors took bank 7 from 61.3% to
67.5%.

**Neither bank 3 nor bank 4 is ever the target of any of the nine jumps,
across two full-track sessions covering all four tracks.** That resolves
what the last session left open the honest way: not "still unresolved",
but a real negative result from better data. Combined with their ~40%
single-value fill (measured before), banks 3 and 4 hold data -- plausibly
per-track tables, which would fit: four tracks, and hills are one of this
game's additions over Pole Position II.

### One vector resolves itself from the ROM alone

`f7:C6DC JMP ($7878)` looked like a tenth case needing a live probe. It is
not: `$7878`/`$7879` sit inside **fixed bank 6** (`$4000`-`$7FFF`,
otherwise unexamined -- only its reset vector is declared) and hold the
constant bytes `$B0 $00`, so the jump always resolves to `$00B0`. That is
zero page, not any ROM bank: a small relocatable stub is evidently
installed there at startup and jumped to via a fixed, hard-coded ROM
pointer. Confirmed by reading the ROM file directly at that offset rather
than by watching it run. Bank 6 itself is still unexamined past its reset
vector and is an obvious next target.

### Where this leaves it

```
b0  1583  9.7%      b2 1325  8.1%      f7 11065  67.5%
b1   339  2.1%      b5 1947 11.9%
```

16,259 of 65,536 mapped bytes (24.8%), up from 14,919, all six emitted
spaces (b0, b1, b2, b5, f6, f7) reassembling byte-identically.

### Open, in rough order of promise

1. **Player 1's actual controls** -- steering, gear, accelerate, jump.
   Bank 0's controller code is ruled out (it is controller 2's UI). The
   IRQ-driven vector chain at `$26A8`/`$26AA`/`$26AC` is the most likely
   home for per-frame physics, now that its dispatch is visible; its
   default targets `$FE68`/`$FE7A` are declared and worth reading next.
2. **Bank 6**, entirely unexamined past the reset vector, and the likely
   home of whatever gets installed at `$00B0`.
3. **Banks 3 and 4** as per-track data -- worth testing against the
   "four tracks" structure directly, the way PP2's track format was
   decoded.


## The three open items, followed up

### Player 1's controls: found

Bank 0's controller code was ruled out as controller 2's UI. Player 1's
own steering runs through the fixed-bank interrupt handler examined for
the vector chain: `sub_C20D` (entered from NMI at `$C0C2`) reads `SWCHB`
first, for edge-detecting Reset/Select/Pause -- that is what dispatches
through `VecIrqA`/`VecIrqB`/`VecIrqC` and the mode-switching code
(`sub_FEAE`/`sub_FEC0`/`sub_FED2`, which bank-switch through 1, 0, 5, 2 in
turn). Past that, the same handler runs a **7-sample-per-frame poll of
`SWCHA`** -- `LDX ram_0042; CPX #$07` -- into one of two double-buffered
7-byte arrays (`ram_2644`/`ram_264B`, selected by `ram_0044`), which is the
real, continuous joystick oversampling a driving game wants for smooth
turning.

The consumer is `sub_F6ED`/`sub_F702` (`Player1SteerRead`/
`Player1SteerScale`): it reads the buffer, and combines it with
`ram_26E6`-`ram_26E9` -- the *same* cells controller 2's response-time UI
scales its settings into. So the two subsystems meet exactly where
expected: controller 2 configures how sharply the car answers the stick
(Turn 1-12, Straighten 1-25), and this routine applies that scale to
player 1's actual joystick sample on every frame.

Confirmed live rather than assumed: across 270 seconds of continuous
driving, `Player1SteerScaled` (`ram_0051`) was written 197,228 times with
**256 distinct values** and `Player1SteerAccum` (`ram_0155`) 17,688 times
with 128 distinct values -- both about as active as a continuous
steering/lean state can look, against the bank-7 mirror's one write per
session that started this whole line of investigation.

`ram_0192`/`ObjKind` was found along the way, in the same bank-0 region:
`AND #$03` (four values) selects between four obstacle kinds, matching the
manual's enemy bikes / arrow signs / cones / ramps, and its consumer
(`sub0_AF3D`/`ObjKindSwitch`) resets a per-kind state cell on change. This
is the thread that led to the answer on banks 3 and 4, below.

### Bank 3 and 4: per-track after all -- a correction to this session's
### own first answer

The first pass through this data named `ram_0192` `ObjKind`, on the
strength of `AND #$03` (four values) matching the manual's four obstacle
kinds. Screenshots proved that wrong within the same session.

Watching `ram_0192` live across `run-02` (three tracks) found only four
changes in 23,985 frames -- at frame 527, frames 12553 and 12580 close
together, and frame 18218. Not the rate of an obstacle indicator during
continuous driving; the rate of something that changes between races.
Screenshotting each transition settled it: all of them land on the same
screen, the **track select screen**, four tiles labelled 1-4 exactly as
in the manual. `ram_0192` is renamed `TrackSelect`.

So `dat_C2EA` at `f7:$C2EA` -- `{$03, $03, $04, $04}` -- is a **per-track**
bank table after all, the guess two sessions ago got right the first time:
tracks 0 and 1's data live in bank 3, tracks 2 and 3's in bank 4, two
tracks sharing each bank. `sub0_AF3D` (`TrackSelectChanged`) resets
per-track state (`ram_26D9,X`/`TrackSelectState`) when the selection
changes, at `AF3D`/`AF47`.

The reason neither bank is ever a `JMP` target still holds regardless of
which reading is right: their content is read with plain absolute-indexed
`LDA` from code that lives entirely in bank 7, never entered as code in
its own right.

**The lesson, worth stating plainly:** a value that is technically
consistent with a hypothesis (four obstacle kinds, `AND #$03`) is not the
same as a value confirmed against what is actually on screen when it
changes. The first reading was reasonable from the code alone and wrong;
watching it live for one session was what caught it inside the same
session rather than carrying the error into another one.

### The `$7878`/`$00B0` stub: found -- part of track/object setup, not a per-frame handler

Live taps answer the two questions a static read could not. `f7:C6DC` is
reached only **4-5 times per session** (once per track load, roughly --
run-01 has one track and 4 hits at the very end; run-02 has three tracks
and 5, clustered at each transition). And `$00B0` genuinely is fetched as
an opcode -- 25,844 times in one session -- so it is real, executed code,
not a dead pointer.

The caller is `sub_D9B4`/`sub_D9E4` (`f7:$D9B4`), a small loop that walks a
table (`dat_D940`, stride 6 bytes: a 16-bit flag/count then two 16-bit
cells) and, for each nonzero entry, installs values into `ram_004A`/`004B`
and `ram_004C`/`004D` -- **the same two RAM-vector pairs** `f7:EC69` and
`f7:FA44`/`FD13`/`b5:B7F7` dispatch through elsewhere. The one real row in
that table loads `$C71E` (real bank-7 code) as one vector and `$259D` (a
plain RAM address, not code) as the other, with a count of `$14` (20)
alongside. `sub_C6DC`'s `JMP ($7878)`/`$00B0` stub is called from inside
this same installer, which is why it is rare: it belongs to
track/object-table setup at a state transition, not to the per-frame
physics loop.

What `$C71E` and the 20-count buffer at `$259D` actually do is still open.

### Bank 6: unreached, and one stale annotation caught

Bank 6 (`f6`, fixed at `$4000`-`$7FFF`) shows **zero instructions reached**
by the tracer, and a grep across every other bank's listing finds not one
`JSR`/`JMP` operand anywhere in `$4000`-`$7FFF`. The hardware vectors,
read straight from the ROM rather than assumed, are `RESET=$C000`,
`NMI=$C0C2`, `IRQ=$C000` -- all in bank 7. Bank 6 has no natural entry.

The `f6:E010` entry declared since the first commit was simply wrong: it
labelled bank 6's Reset, but `$E010` is not even inside bank 6's own
`$4000`-`$7FFF` address range, and correspondingly reached nothing. Caught
by this pass and removed rather than left to keep producing zero.

By inspection its content looks like dithered bitmap patterns
(`$C0,$C0,$30,$0C...`, runs of `$55`/`$AA`), which fits graphics data --
plausibly the hill terrain this game adds over Pole Position II -- but
nothing traced references it yet, so this is a guess from shape rather
than a finding. The earlier `$7878`/`$00B0` self-modifying-code trail
(fixed bank 6 holding a constant pointer to a RAM stub) is the one lead
into it and is still open.
