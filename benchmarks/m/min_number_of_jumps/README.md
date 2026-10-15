# Minimum Number of Jumps (Dynamic Programming)

Compute the minimum number of forward jumps needed to reach the final array index. This package preserves the pinned Dart source’s quadratic dynamic-programming recurrence and its `1_000_000_000_000` value for an unreachable destination. It is distinct from greedy jump-game variants.

## Contract

The `i64_array_scalar` ABI accepts a nonempty array of 1 to 64 nonnegative jump lengths, each in `[0, 64]`. At index `j`, a value `a[j]` allows a jump to any later index `i` with `i <= j + a[j]`. The result is the minimum jump count for the last index; a single-element array returns zero. If the last index cannot be reached, the source sentinel `1_000_000_000_000` is returned. Invalid length, null input, or a value outside the bound returns `-1`.

For each destination index, the implementation examines every earlier position and updates its DP value when the earlier position can reach it, matching the source traversal. The input array is read only.

## Workload and source

[`workload.json`](workload.json) includes the pinned source examples, direct and multi-step routes, unreachable destinations, the bounds, and malformed inputs.

The shared scalar-array runner validates the workload by replaying the same quadratic destination-by-source DP and preserving the `1e12` unreachable value.

- Dart [`min_number_of_jumps.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/dynamic_programming/min_number_of_jumps.dart)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm min_number_of_jumps --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/min_number_of_jumps/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/min_number_of_jumps.c`](../../../c/m/min_number_of_jumps.c) |
| C3 | [`c3/m/min_number_of_jumps.c3`](../../../c3/m/min_number_of_jumps.c3) |
| C++ | [`cpp/m/min_number_of_jumps.cpp`](../../../cpp/m/min_number_of_jumps.cpp) |
| Elisa | [`elisa/m/min_number_of_jumps.elisa`](../../../elisa/m/min_number_of_jumps.elisa) |
| Nim | [`nim/m/min_number_of_jumps.nim`](../../../nim/m/min_number_of_jumps.nim) |
| Odin | [`odin/m/min_number_of_jumps.odin`](../../../odin/m/min_number_of_jumps.odin) |
| Rust | [`rust/m/min_number_of_jumps.rs`](../../../rust/m/min_number_of_jumps.rs) |
| V | [`v/m/min_number_of_jumps.v`](../../../v/m/min_number_of_jumps.v) |
| Zig | [`zig/m/min_number_of_jumps.zig`](../../../zig/m/min_number_of_jumps.zig) |
