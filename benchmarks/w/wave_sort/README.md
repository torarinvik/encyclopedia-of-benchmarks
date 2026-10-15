# Wave Sort

This benchmark captures the C++ and Rust wave-sort variant (also present in C-Plus-Plus-1): sort values in ascending order, then swap adjacent pairs beginning at index zero. The result follows `a[0] >= a[1] <= a[2] >= a[3] ...`.

## Contract

- Input has 0 through 4,096 signed 64-bit values, each in the signed 32-bit range.
- Return the wave array as signed 32-bit little-endian bytes and the element count.
- Invalid lengths or values return `-1`; insufficient output capacity returns `-2`.
- The ports use a portable in-place heapsort before the adjacent-pair swaps.

The Java `WaveSort` source instead greedily makes even positions peaks. It is tracked separately as [`wave_sort_greedy`](../wave_sort_greedy/README.md), because it produces a different phase and output order.

## Workload and build

[`workload.json`](workload.json) covers empty and singleton inputs, the published examples, duplicates, negatives, signed 32-bit edges, and an out-of-domain value. The byte-output runner checks the exact expected output.

All nine language implementations use the `i64_array_bytes_output` ABI family.

## Upstream sources

- [C++ `wave_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/wave_sort.cpp)
- [C++-1 `wave_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/wave_sort.cpp)
- [Rust `wave_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/wave_sort.rs)
- [Java `WaveSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/WaveSort.java) (greedy variant above)

Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm wave_sort --language c` and record with `benchmarks/run_i64_array_bytes_output.py`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wave_sort.c`](../../../c/w/wave_sort.c) |
| C3 | [`c3/w/wave_sort.c3`](../../../c3/w/wave_sort.c3) |
| C++ | [`cpp/w/wave_sort.cpp`](../../../cpp/w/wave_sort.cpp) |
| Elisa | [`elisa/w/wave_sort.elisa`](../../../elisa/w/wave_sort.elisa) |
| Nim | [`nim/w/wave_sort.nim`](../../../nim/w/wave_sort.nim) |
| Odin | [`odin/w/wave_sort.odin`](../../../odin/w/wave_sort.odin) |
| Rust | [`rust/w/wave_sort.rs`](../../../rust/w/wave_sort.rs) |
| V | [`v/w/wave_sort.v`](../../../v/w/wave_sort.v) |
| Zig | [`zig/w/wave_sort.zig`](../../../zig/w/wave_sort.zig) |
