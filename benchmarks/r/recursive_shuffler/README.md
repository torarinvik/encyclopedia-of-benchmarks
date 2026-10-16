# Recursive shuffler

Shuffle a bounded i32 array with the recursive, forward Fisher–Yates procedure described by the pinned C# `RecursiveShuffler<T>`.

## Contract

- The `i64_array_bytes_output` input is `[seed, value_0, ..., value_(n-1)]`; `n` is 0–64, values are signed i32 values, and the seed is in 1–2,147,483,646.
- The source calls itself recursively down to item 1, then chooses a swap index on the way back up. The benchmark uses the Park–Miller stream `state = state * 48,271 mod 2,147,483,647`, starts from the supplied seed, and for each item index `i` from 1 through `n-1` swaps `values[i]` with `values[state mod (i+1)]`.
- Output is the shuffled array as four-byte little-endian two’s-complement i32 values. The return value is the number of values. Invalid input returns `-1`; insufficient output capacity returns `-2`.
- The 64-value limit bounds recursive stack depth. The input parser accepts 66 integers so a row with one value beyond the valid maximum can be rejected by the implementation.

The pinned C# method swaps the same pair twice, cancelling every shuffle, and constructs a new `Random` from the same seed at every recursion level. This benchmark follows the documented recursive Fisher–Yates intent, uses one portable random stream, and removes both defects so all languages produce a reproducible permutation.

[`workload.json`](workload.json) contains empty, singleton, seeded, repeated-value, signed-boundary, maximum-size, and malformed cases. The independent byte oracle is [`recursive_shuffler_oracle.py`](../../recursive_shuffler_oracle.py).

## Pinned source

- [TheAlgorithms/C-Sharp `RecursiveShuffler.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbb6c/Algorithms/Shufflers/RecursiveShuffler.cs)

## Build and verify

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm recursive_shuffler --language rust
    python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/recursive_shuffler/rust/build.json
    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm recursive_shuffler

All nine ports passed 336 oracle inputs each and recorded all 13 workload cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/recursive_shuffler.c`](../../../c/r/recursive_shuffler.c) |
| C3 | [`c3/r/recursive_shuffler.c3`](../../../c3/r/recursive_shuffler.c3) |
| C++ | [`cpp/r/recursive_shuffler.cpp`](../../../cpp/r/recursive_shuffler.cpp) |
| Elisa | [`elisa/r/recursive_shuffler.elisa`](../../../elisa/r/recursive_shuffler.elisa) |
| Nim | [`nim/r/recursive_shuffler.nim`](../../../nim/r/recursive_shuffler.nim) |
| Odin | [`odin/r/recursive_shuffler.odin`](../../../odin/r/recursive_shuffler.odin) |
| Rust | [`rust/r/recursive_shuffler.rs`](../../../rust/r/recursive_shuffler.rs) |
| V | [`v/r/recursive_shuffler.v`](../../../v/r/recursive_shuffler.v) |
| Zig | [`zig/r/recursive_shuffler.zig`](../../../zig/r/recursive_shuffler.zig) |
