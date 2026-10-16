# Fisher–Yates Shuffle

Shuffle a bounded sequence using the canonical in-place Fisher–Yates algorithm. A shared Park–Miller stream and swap order make results deterministic across languages. This normalizes the pinned sources rather than preserving each source's random-number behavior: JavaScript follows the canonical loop, while Dart's `nextInt(i - 1)` bound excludes legal swap choices and Rust's `0..(len - 2)` loop omits the last forward swap and underflows on slices shorter than two elements. The Ruby alias also reaches `rand(0)` on its final iteration. These source defects are corrected by the benchmark contract.

## Contract

Input is a signed 64-bit array `[seed, value...]`. The seed is in `1..=2,147,483,646`; there are at most 1,024 values, each in the signed i32 range. The benchmark uses the Park–Miller recurrence `state = (state * 48,271) mod 2,147,483,647`. Starting with `remaining = count` and decreasing through 2, it swaps index `remaining - 1` with `next_random() mod remaining`. This fixes the random stream and draw order across implementations.

Output is the shuffled values as four-byte little-endian two’s-complement i32 values. The return value is the number of values. Invalid input returns `-1`; insufficient output capacity returns `-2`. The algorithm takes `O(n)` time and `O(n)` auxiliary storage for validated input.

See [`workload.json`](workload.json) for representative vectors. The independent byte oracle is [`benchmarks/fisher_yates_shuffle_oracle.py`](../../fisher_yates_shuffle_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fisher_yates_shuffle.c`](../../../c/f/fisher_yates_shuffle.c) |
| C3 | [`c3/f/fisher_yates_shuffle.c3`](../../../c3/f/fisher_yates_shuffle.c3) |
| C++ | [`cpp/f/fisher_yates_shuffle.cpp`](../../../cpp/f/fisher_yates_shuffle.cpp) |
| Elisa | [`elisa/f/fisher_yates_shuffle.elisa`](../../../elisa/f/fisher_yates_shuffle.elisa) |
| Nim | [`nim/f/fisher_yates_shuffle.nim`](../../../nim/f/fisher_yates_shuffle.nim) |
| Odin | [`odin/f/fisher_yates_shuffle.odin`](../../../odin/f/fisher_yates_shuffle.odin) |
| Rust | [`rust/f/fisher_yates_shuffle.rs`](../../../rust/f/fisher_yates_shuffle.rs) |
| V | [`v/f/fisher_yates_shuffle.v`](../../../v/f/fisher_yates_shuffle.v) |
| Zig | [`zig/f/fisher_yates_shuffle.zig`](../../../zig/f/fisher_yates_shuffle.zig) |
