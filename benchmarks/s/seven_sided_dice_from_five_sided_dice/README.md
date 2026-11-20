# Seven-sided dice from five-sided dice

This benchmark deterministically consumes a finite tape of five-sided-die
draws and emits as many unbiased seven-sided-die faces as the tape supports.
It uses entropy recycling: accepted states produce a face and leave a uniform
quotient reservoir; rejected tail states are retained for the next draw.

## Contract

The `i64_array_bytes_output` symbol is
`seven_sided_dice_from_five_sided_dice`. Input is
`[draw_count, d0, ..., d(draw_count-1)]`, where `0 <= draw_count <= 256` and
every draw is in `0..4` (the five-sided die face minus one). The input must
contain exactly `draw_count + 1` words. Malformed input returns `-1`.

The reservoir begins at `(value, range) = (0, 1)`. For each draw `d`, append
the digit in base five: `value = 5*value + d`, `range = 5*range`. While
`range >= 7`, set `accepted = range - range % 7`. If `value < accepted`, emit
`value % 7 + 1`, then keep the quotient state `(value / 7, accepted / 7)`.
Otherwise subtract `accepted` from both `value` and `range` to keep the
rejected tail. At tape exhaustion, discard the remaining reservoir and return
the faces already emitted. Exhaustion is successful even when it emits no
faces; the algorithm never obtains implicit extra draws.

Each output byte is a face from 1 through 7. The return value is the number of
bytes written. A null output or insufficient capacity returns `-2` without
writing. The valid input bound is 257 words, the parseable frame bound is 258
words, and the maximum output is 256 bytes.

This is distinct from [`unbias_01`](../../u/unbias_01/README.md), which uses
Von Neumann extraction on biased binary pairs and returns one bit. The
seven-sided-die package converts a base-5 entropy stream into multiple
seven-way outcomes while carrying residual entropy forward.

## Workload and references

[`workload.json`](workload.json) covers direct acceptance, rejected-tail
recycling, reuse of accepted quotient entropy, exhaustion after rejection,
zero and insufficient draw tapes, malformed frames, and output-buffer errors.
The primary reservoir implementation is in
[`primary_oracle.py`](primary_oracle.py). The independent reference models
each step as accepted seven-face buckets plus a residual interval in
[`independent_oracle.py`](independent_oracle.py). Source provenance is recorded
in [`RIGHTS.md`](RIGHTS.md); [`verify_workload.py`](verify_workload.py) checks
the static package inventory.

The algorithmic task comes from [Rosetta Code](https://rosettacode.org/wiki/Seven-sided_dice_from_five-sided_dice).
This package uses a finite supplied tape rather than ambient randomness so
every benchmark call has deterministic output.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/seven_sided_dice_from_five_sided_dice.c`](../../../c/s/seven_sided_dice_from_five_sided_dice.c) |
| C3 | [`c3/s/seven_sided_dice_from_five_sided_dice.c3`](../../../c3/s/seven_sided_dice_from_five_sided_dice.c3) |
| C++ | [`cpp/s/seven_sided_dice_from_five_sided_dice.cpp`](../../../cpp/s/seven_sided_dice_from_five_sided_dice.cpp) |
| Elisa | [`elisa/s/seven_sided_dice_from_five_sided_dice.elisa`](../../../elisa/s/seven_sided_dice_from_five_sided_dice.elisa) |
| Mojo | [`mojo/s/seven_sided_dice_from_five_sided_dice.mojo`](../../../mojo/s/seven_sided_dice_from_five_sided_dice.mojo) |
| Nim | [`nim/s/seven_sided_dice_from_five_sided_dice.nim`](../../../nim/s/seven_sided_dice_from_five_sided_dice.nim) |
| Odin | [`odin/s/seven_sided_dice_from_five_sided_dice.odin`](../../../odin/s/seven_sided_dice_from_five_sided_dice.odin) |
| Rust | [`rust/s/seven_sided_dice_from_five_sided_dice.rs`](../../../rust/s/seven_sided_dice_from_five_sided_dice.rs) |
| V | [`v/s/seven_sided_dice_from_five_sided_dice.v`](../../../v/s/seven_sided_dice_from_five_sided_dice.v) |
| Zig | [`zig/s/seven_sided_dice_from_five_sided_dice.zig`](../../../zig/s/seven_sided_dice_from_five_sided_dice.zig) |
