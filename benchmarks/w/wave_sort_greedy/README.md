# Greedy Wave Sort

This benchmark captures Java's `WaveSort`: scan even indices, swapping each value with its left neighbor if it is too small, then with its right neighbor if it is too small. Even indices are peaks, so the result follows `a[0] >= a[1] <= a[2] >= a[3] ...`.

## Contract

- Input has 0 through 4,096 signed 64-bit values, each in the signed 32-bit range.
- Return the wave array as signed 32-bit little-endian bytes and the element count.
- Invalid lengths or values return `-1`; insufficient output capacity returns `-2`.
- The scan uses O(n) time and O(n) temporary storage for the output copy.

This greedy method can return a different permutation from [`wave_sort`](../wave_sort/README.md), whose C++ and Rust sources fully sort the values before swapping adjacent pairs.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton inputs, the published examples, duplicates, negatives, signed 32-bit edges, and an out-of-domain value. The byte-output runner checks the exact expected output.

All nine language implementations use the `i64_array_bytes_output` ABI family.

## Upstream source

[Java `WaveSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/WaveSort.java)

Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm wave_sort_greedy --language c` and record with `benchmarks/run_i64_array_bytes_output.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wave_sort_greedy.c`](../../../c/w/wave_sort_greedy.c) |
| C3 | [`c3/w/wave_sort_greedy.c3`](../../../c3/w/wave_sort_greedy.c3) |
| C++ | [`cpp/w/wave_sort_greedy.cpp`](../../../cpp/w/wave_sort_greedy.cpp) |
| Elisa | [`elisa/w/wave_sort_greedy.elisa`](../../../elisa/w/wave_sort_greedy.elisa) |
| Nim | [`nim/w/wave_sort_greedy.nim`](../../../nim/w/wave_sort_greedy.nim) |
| Odin | [`odin/w/wave_sort_greedy.odin`](../../../odin/w/wave_sort_greedy.odin) |
| Rust | [`rust/w/wave_sort_greedy.rs`](../../../rust/w/wave_sort_greedy.rs) |
| V | [`v/w/wave_sort_greedy.v`](../../../v/w/wave_sort_greedy.v) |
| Zig | [`zig/w/wave_sort_greedy.zig`](../../../zig/w/wave_sort_greedy.zig) |
