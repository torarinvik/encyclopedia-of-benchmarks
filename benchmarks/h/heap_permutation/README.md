# Heap permutation

This benchmark ports the pinned Rust `heap_permute` routine and preserves its exact emitted row order. The source handles an empty input as one empty row. For nonempty inputs, it loops over `i` from 0 to `k - 1`, swaps index `i` with `k - 1` when `k` is even (otherwise index 0 with `k - 1`), then recurses on `k - 1`. It performs each swap before recursion and does not swap back, so its observable row sequence can repeat rows even when the input values are distinct. The package preserves those rows and their order.

## Contract

Input is a signed 64-bit array `[n, values...]`, where `n` is from 0 through 7, the array contains exactly `n + 1` values, and each value fits a signed 32-bit integer. Invalid input returns `-1`.

Output contains `n!` rows, each with `n` little-endian signed 32-bit integers. The row order is the pinned routine's swap-before-recursion order; repeated rows are retained. For `n=0`, output has zero bytes and the function returns 1. Otherwise the function returns the number of rows. Insufficient output capacity returns `-2` without writing. At `n=7`, the output is 5,040 rows and 141,120 bytes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm heap_permutation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/heap_permutation/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/heap_permutation.c`](../../../c/a/heap_permutation.c) |
| C3 | [`c3/a/heap_permutation.c3`](../../../c3/a/heap_permutation.c3) |
| C++ | [`cpp/a/heap_permutation.cpp`](../../../cpp/a/heap_permutation.cpp) |
| Elisa | [`elisa/a/heap_permutation.elisa`](../../../elisa/a/heap_permutation.elisa) |
| Nim | [`nim/a/heap_permutation.nim`](../../../nim/a/heap_permutation.nim) |
| Odin | [`odin/a/heap_permutation.odin`](../../../odin/a/heap_permutation.odin) |
| Rust | [`rust/a/heap_permutation.rs`](../../../rust/a/heap_permutation.rs) |
| V | [`v/a/heap_permutation.v`](../../../v/a/heap_permutation.v) |
| Zig | [`zig/a/heap_permutation.zig`](../../../zig/a/heap_permutation.zig) |

## Pinned source

- Rust [`heap.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/permutations/heap.rs)
