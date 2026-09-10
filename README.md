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
| 7 | f7 | 10,047 | 4,589 | 61.3% | 58.2% |
| 5 | b5 | 1,785 | 832 | 10.9% | 9.4% |
| 0 | b0 | 1,458 | 679 | 8.9% | 4.3% |
| 2 | b2 | 1,325 | 644 | 8.1% | 8.1% |
| 1 | b1 | 304 | 143 | 1.9% | 1.9% |
| 3,4,6 | - | 0 | 0 | 0% | 0% |

**Total traced:** 14,919 bytes / 6,887 instructions (22.8%), up from 13,405.
Reassembly is byte-identical across all six emitted spaces.

The gain came from two things, both described in
[`docs/DISCOVERY.md`](docs/DISCOVERY.md): each switched bank opens with a
**jump table** the tracer can only follow one entry of, and five **indirect
jumps through RAM pointers** whose targets were read off a live run. The
second needs care -- the bank recorded when a pointer is written is not
necessarily the bank mapped when it is jumped through, and 26 candidates
attributed to bank 3 that way produced 27 instructions between them, so
bank 3 is deliberately left out rather than filed as fact.

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

1. Resolve bank 3 properly: sample the bank register at the moment of the
   `JMP`, not when the pointer is written. Needs an execution breakpoint at
   the five jump sites or a read-back of the bank register.
2. Add the remaining unresolved bank-switch targets to `entries`
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
