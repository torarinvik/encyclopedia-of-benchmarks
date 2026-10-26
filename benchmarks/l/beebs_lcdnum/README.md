# `beebs_lcdnum`

This package exposes the digit-to-seven-segment lookup in the pinned BEEBS
`lcdnum` benchmark as a deterministic byte operation. It accepts exactly five
raw byte values, masks each value to its low nibble, then returns the five
source-table masks in input order. The table order is the source order for
nibbles `0` through `15`:

`00 24 5d 6d 2e 5d 7b 25 7f 6f 3f 7a 53 7c 5b 1b`.

The source benchmark performs ten volatile port scans. Only the first five
values are converted and written; the last five scans have no output effect.
This profile makes the first five conversions observable as five output bytes,
and excludes device-port reads/writes, the five ignored scans, and the original
benchmark's missing output verifier. It therefore benchmarks the source lookup
kernel rather than simulating hardware.

The ABI symbol is `beebs_lcdnum` in the `i64_array_bytes_output` family. Input
must contain exactly five signed 64-bit integers in `[0,255]`. Each is reduced
to its low nibble before lookup. A null input, wrong length, or out-of-range
value returns `-1`. A null output pointer or output capacity below five returns
`-2`. Errors write no output. A valid call writes exactly five masks and returns
`5`.

## Source and rights

The source is pinned to [`mageec/beebs` `src/lcdnum/liblcdnum.c`](https://github.com/mageec/beebs/blob/049ded9f3aeb5591f553879d3a0376b8614e9422/src/lcdnum/liblcdnum.c)
at commit `049ded9f3aeb5591f553879d3a0376b8614e9422`. The file declares
GPL-3.0-or-later and attributes copyright to Embecosm Limited and the
University of Bristol, with James Pallister as a contributor. See
[LICENSE.txt](LICENSE.txt) and [NOTICE.txt](NOTICE.txt). The nine ports are
clean-room implementations of the bounded lookup profile; no upstream
implementation text was copied or translated.

## Files

- `workload.json` records the source pin, byte bounds, projection, and fixtures.
- `../../beebs_lcdnum_oracle.py` is the independent reference implementation.
- Ports: [C](../../../c/l/beebs_lcdnum.c), [C3](../../../c3/l/beebs_lcdnum.c3),
  [C++](../../../cpp/l/beebs_lcdnum.cpp), [Elisa](../../../elisa/l/beebs_lcdnum.elisa),
  [Nim](../../../nim/l/beebs_lcdnum.nim), [Odin](../../../odin/l/beebs_lcdnum.odin),
  [Rust](../../../rust/l/beebs_lcdnum.rs), [V](../../../v/l/beebs_lcdnum.v), and
  [Zig](../../../zig/l/beebs_lcdnum.zig).
