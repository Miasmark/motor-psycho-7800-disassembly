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
