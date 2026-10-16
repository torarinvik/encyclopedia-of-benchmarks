# Median Finder

This benchmark ports the pinned Java `MedianFinder` two-heap stream algorithm. After every insertion it emits the current median as an IEEE-754 binary64 value.

## Contract

- Input is `[n, value0, ..., value(n-1)]`, with `1 <= n <= 64` and each value in `[-1,000,000, 1,000,000]`.
- The lower max-heap contains the smaller values and may contain one more item than the upper min-heap. Each insertion follows the source's insert-then-rebalance behavior.
- At the maximum count, a lower-heap insertion that would temporarily exceed 32 slots first moves the lower root to the upper heap, then inserts the value. This yields the same post-insertion partition and median as the source while keeping both fixed heaps within 32 slots.
- After each insertion, return the lower heap's root for an odd item count, or the average of the two heap roots for an even count. Even medians retain half values as binary64; they are not truncated.
- Output contains `n` little-endian IEEE-754 binary64 values in insertion order and is exactly `n * 8` bytes. The function returns that byte count.
- Malformed input returns `-1`. A null output pointer or capacity below `n * 8` returns `-2` without writing to the output.
- The value bound keeps the source's integer comparator and pairwise sum within signed 32-bit range. Two fixed 32-element i64 heaps use 512 bytes of heap storage; maximum output is also 512 bytes.

The independent [`median_finder_oracle.py`](../../median_finder_oracle.py) sorts each input prefix, rather than using heaps, and encodes the resulting medians with Python `struct`.

## Pinned source

[TheAlgorithms/Java `MedianFinder.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/MedianFinder.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/median_finder.c`](../../../c/m/median_finder.c) |
| C3 | [`c3/median_finder.c3`](../../../c3/m/median_finder.c3) |
| C++ | [`cpp/median_finder.cpp`](../../../cpp/m/median_finder.cpp) |
| Elisa | [`elisa/median_finder.elisa`](../../../elisa/m/median_finder.elisa) |
| Nim | [`nim/median_finder.nim`](../../../nim/m/median_finder.nim) |
| Odin | [`odin/median_finder.odin`](../../../odin/m/median_finder.odin) |
| Rust | [`rust/median_finder.rs`](../../../rust/m/median_finder.rs) |
| V | [`v/median_finder.v`](../../../v/m/median_finder.v) |
| Zig | [`zig/median_finder.zig`](../../../zig/m/median_finder.zig) |
