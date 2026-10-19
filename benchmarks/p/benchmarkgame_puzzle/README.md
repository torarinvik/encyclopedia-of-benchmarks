# BenchmarkGame puzzle

This workload ports the deterministic duplicate-finding benchmark in the pinned `lac-dcc/Benchmarks` `BenchmarkGame/puzzle/puzzle.c` source. The repository's separate `find_all_duplicates_in_array` benchmark solves a related problem over caller-provided input; this one includes the source's local random-number generator, array construction, shuffle, and repeated XOR scan.

## Contract

The `i64_array_bytes_output` input is `[array_size, arrays_to_generate, scans_per_array]`. The array size is 1–100,000, the generated-array count is 1–8, and scan repetitions are 1–64. The source seed is fixed at 1 once per call and its random stream continues across generated arrays. Each array starts with the values 0 through `array_size`, replaces element 0 with a deterministic value in 1 through `array_size`, and applies the source's descending Fisher-Yates shuffle. The duplicate-finding pass evaluates the source XOR expression. Each output is that duplicate as a little-endian signed 32-bit integer; the function returns the number of output bytes.

The source defaults (500,000 elements, five arrays, 200 scans per array) are scaled down to bounded inputs. Repeated scans are retained in every implementation, even though the immutable array makes each scan's answer identical. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2`.

The RNG preserves the source's 64-bit unsigned wrap, 32-bit truncation of the shifted state, and 1–32767 result range. `workload.json` includes the first deterministic draw, multiple generated arrays at the minimum size, repeat scans, malformed inputs, and output-buffer errors. The oracle is [`benchmarkgame_puzzle_oracle.py`](../../benchmarkgame_puzzle_oracle.py).

The source is pinned to commit [`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/puzzle/puzzle.c), whose Git blob ID is `b86d38a55c3a1719e43771929030429f75da9ab5`.

Build and record using the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm benchmarkgame_puzzle --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm benchmarkgame_puzzle
```

| Language | Source |
| --- | --- |
| C | [`c/p/benchmarkgame_puzzle.c`](../../../c/p/benchmarkgame_puzzle.c) |
| C3 | [`c3/p/benchmarkgame_puzzle.c3`](../../../c3/p/benchmarkgame_puzzle.c3) |
| C++ | [`cpp/p/benchmarkgame_puzzle.cpp`](../../../cpp/p/benchmarkgame_puzzle.cpp) |
| Elisa | [`elisa/p/benchmarkgame_puzzle.elisa`](../../../elisa/p/benchmarkgame_puzzle.elisa) |
| Nim | [`nim/p/benchmarkgame_puzzle.nim`](../../../nim/p/benchmarkgame_puzzle.nim) |
| Odin | [`odin/p/benchmarkgame_puzzle.odin`](../../../odin/p/benchmarkgame_puzzle.odin) |
| Rust | [`rust/p/benchmarkgame_puzzle.rs`](../../../rust/p/benchmarkgame_puzzle.rs) |
| V | [`v/p/benchmarkgame_puzzle.v`](../../../v/p/benchmarkgame_puzzle.v) |
| Zig | [`zig/p/benchmarkgame_puzzle.zig`](../../../zig/p/benchmarkgame_puzzle.zig) |
