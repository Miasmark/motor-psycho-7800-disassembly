# Motor Psycho -- Project Summary

## ROM Information

| Property | Value |
|----------|-------|
| File | Motor Psycho (NTSC) (Atari) (1990) (1E219482).a78 |
| Size | 131,200 bytes (128-byte header + 128 KB ROM) |
| Mapper | SuperGame 64K (cart type 0x0112) |
| NTSC/PAL | NTSC |

## Memory Map

```
$4000-$7FFF  fixed  -> ROM bank 6 (file offset $18000-$1BFFF)
$8000-$BFFF  banked -> ROM banks 0-7 (file offset $0000-$17FFF)
$C000-$FFFF  fixed  -> ROM bank 7 (file offset $1C000-$1FFFF)
```

## Current Coverage

| Bank | Space | Bytes | Instructions | % | was |
|------|-------|-------|--------------|----|-----|
| 7 | f7 | 11,050 | 5,026 | 67.4% | 61.3% |
| 5 | b5 | 1,947 | 906 | 11.9% | 10.9% |
| 0 | b0 | 1,583 | 734 | 9.7% | 8.9% |
| 2 | b2 | 1,325 | 644 | 8.1% | 8.1% |
| 1 | b1 | 339 | 158 | 2.1% | 1.9% |
| 3,4,6 | - | 0 | 0 | 0% | 0% |

**Total traced:** 16,244 bytes / 7,468 instructions (24.8%), up from 14,919.
Reassembly is byte-identical across all six emitted spaces.
Corrected 2026-11-08: bank 7 was 11,065 bytes / 5,036 instructions until
14 phantom entries were removed. They were copy sources (HUD text, DLL
tails, display lists, palette sets), not code; see
[`docs/DISCOVERY.md`](docs/DISCOVERY.md).

Three things asked for from these recordings, all in
[`docs/DISCOVERY.md`](docs/DISCOVERY.md): **player 1's steering**, one
`SWCHA` sample per frame taken inside the NMI handler and buffered until the
next road update (up to 7), with each sample run through a scale factor the
response-time UI configures (corrected 2026-11-08: this said 7 samples a
frame, but `$42` counts frames, not samples); **banks 3 and 4**, confirmed
*per-track* after a same-session correction -- a first reading called the
selector `ObjKind` on the strength of `AND #$03` matching the manual's
four obstacle kinds, and screenshotting every change of that cell showed
it only ever changes on the track-select screen, so it is `TrackSelect`
and the bank table pairs two tracks per bank; and **bank 6**, confirmed
unreached by anything traced (the hardware vectors all point into bank 7),
which also caught a stale annotation -- `f6:E010` was never a valid
address inside that bank at all. There is no `$7878`/`$00B0` stub
(corrected 2026-11-08). `f7:C6DC` is four bytes of HUD text that a phantom
entry listed as `JMP ($7878)`. `sub_D9B4` runs the copy scripts that put
the HUD text and display lists in RAM. The HUD itself confirms `TurnResponse`/`StraightenResponse`
outright -- it reads "STRAIGHTEN: 20" and "TURN: 10" on screen, live,
matching those cells exactly rather than by numeric coincidence with the
manual. And **bank 6 is confirmed graphics**, not guessed: tapping every
read of its address range catches MARIA's own DMA the same way it would a
CPU fetch, and across one three-track session that comes to 43.6 million
reads touching 80% of the bank's bytes.

Two full-track recordings (`run-01.inp`, `run-02.inp`, all four tracks
between them) let the nine known indirect jumps be sampled properly this
time -- a read tap on the `JMP` instruction itself, catching the bank
register and the vector's value at the instant of the jump, rather than
inferring it from when the pointer was last written. That settled the
question the previous pass left open: **neither bank 3 nor bank 4 is ever
a jump target across either recording**, so they hold data, not code --
plausibly per-track tables, consistent with their ~40% single-value fill.
It also corrected a wrong turn: the input-mirroring code in bank 7 that
looked like the controller reader barely changes across 270 seconds of
continuous driving, because it turns out to be **controller 2's optional
response-time adjustment**, not player 1's steering. See
[`docs/DISCOVERY.md`](docs/DISCOVERY.md) for both.

## Free Space

- **40,445 bytes** (30.8%) of zero-padding in 938 regions of 16+ bytes
- **86,585 bytes** of actual ROM data
- Banks 2-5 have the most slack (8,358-8,536 bytes each)
- Slack patterns: trailing zeros at bank boundaries, 128-byte padding at $04000

## Identified Labels

- `f6:E010` - Reset handler (in bank 6)
- `f7:C000` - Reset handler (in bank 7)
- `f7:C0C2` - NMI handler (in bank 7)

## Bank Switch Sites

The code switches banks at `$8000` to access additional ROM banks. 13 of 32
bank-switch sites are resolved; 19 remain unresolved and require runtime
tracing to resolve.

## Audio

The audio trace found only 2 stores to TIA AUDV0/AUDV1 in one routine, both
writing constants (initialization or silence). The sound player may be in an
untraced bank or installed via RAM vector.

## Next Steps

1. Decode `Player1SteerAccum` (`$0155`) against actual steering/gear
   behaviour -- the pipeline is found, its output is not yet read as a
   number.
2. What writes the repeated fill values seen in the HUD text line at
   `$259D` (corrected 2026-11-08: `$C71E` is the message TIME REMAINING
   BONUS and `$259D` is a text line, not a per-object buffer; there is no
   `$7878` stub).
3. Bank 6 is **confirmed graphics** -- MARIA's own DMA reads it 43.6
   million times across one three-track session, 80% of its bytes
   touched -- but nothing yet says which visual element specifically.
2. Trace the DLI chain via `JMP ($004A)` / `JMP ($004C)` / `JMP ($006C)`
3. Record gameplay to capture audio and identify untraced routines
4. Analyze the most-referenced RAM addresses for game state
5. Search for graphics, sound, and music data in untraced banks

## Files

- `rom.a78` - ROM image
- `src/rom.asm` - Assembly template
- `annotations.json` - Analysis annotations
- `docs/DISCOVERY.md` - Detailed discovery log
- `docs/pitfalls.md` - Reference pitfalls
