# Peak

## Contract

Input is `[count, values...]`, where count is 3–64 and each signed 32-bit value is in `[-1,000,000, 1,000,000]`. The array must strictly increase to a unique interior maximum and then strictly decrease. Return that maximum value. Arrays outside this domain return `-1`.

The benchmark mirrors the pinned Python divide-and-conquer strategy. It examines the middle three values; if the middle is a strict peak it returns it, if the left neighbor is lower than the right neighbor it recurses into the right slice, otherwise it recurses into the left slice. For a two-element prefix, the source adjusts the slice by one to preserve a three-element recursive input. The bound enforces an interior peak so the source's three-element indexing is defined.

## Source review

The pinned Python `peak` documents a unimodal list with its peak at index `p >= 1`; it uses middle-three comparisons and recursive slicing rather than a linear maximum scan. The bounded contract makes the strict unimodal precondition explicit and avoids edge cases where the source slice has fewer than three values.

Pinned source: [Python `peak.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/peak.py).

## Workload and implementations

[`workload.json`](workload.json) covers peaks at different interior positions, negative values, invalid monotone arrays, short input, malformed lengths, and out-of-range values. The [runtime oracle](../../peak_oracle.py) follows the bounded recursive search.

| Language | Port |
|---|---|
| C | [`c/p/peak.c`](../../../c/p/peak.c) |
| C3 | [`c3/p/peak.c3`](../../../c3/p/peak.c3) |
| C++ | [`cpp/p/peak.cpp`](../../../cpp/p/peak.cpp) |
| Elisa | [`elisa/p/peak.elisa`](../../../elisa/p/peak.elisa) |
| Nim | [`nim/p/peak.nim`](../../../nim/p/peak.nim) |
| Odin | [`odin/p/peak.odin`](../../../odin/p/peak.odin) |
| Rust | [`rust/p/peak.rs`](../../../rust/p/peak.rs) |
| V | [`v/p/peak.v`](../../../v/p/peak.v) |
| Zig | [`zig/p/peak.zig`](../../../zig/p/peak.zig) |
