# Next permutation

Transform an integer sequence to its immediate lexicographically greater permutation. If it is already the last permutation, reverse it to the lexicographically smallest ordering. The operation modifies one sequence; it does not enumerate permutations.

## Contract

- Input is `[n, values...]`, with `n` from 0 through 128 and exactly `n` signed 32-bit values.
- Output is the transformed sequence as `n` little-endian signed 32-bit values. The return value is `n`.
- Empty and singleton sequences are unchanged. Duplicate values are supported; the successor is among distinct value orderings.
- Malformed input or values outside signed 32-bit range return `-1`. Insufficient output capacity returns `-2`.
- This bounded signed-32-bit subset preserves the pinned Go algorithm's integer ordering while keeping the output buffer small (at most 512 bytes).

## Source and related algorithms

This follows the pinned Go [`NextPermutation`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/permutation/next_permutation.go). It scans from the right for the last ascent, swaps that pivot with the rightmost greater value, then reverses the suffix. With no ascent, it reverses the whole sequence. The pinned Go source accepts `[]int`; this benchmark uses signed 32-bit values as a portable bounded subset. The byte-output runner computes the same successor as its workload oracle.

This differs from [`all_permutations`](../../a/all_permutations/README.md), which emits every positional ordering and retains repeated rows, and [`unique_permutation`](../../u/unique_permutation/README.md), which enumerates every distinct arrangement. `next_permutation` emits one successor in place, and wraps the final arrangement to the first.

## Workload and ports

[`workload.json`](workload.json) covers empty/singleton inputs, ordinary and duplicate values, the last permutation, signed values, and malformed inputs. The shared `i64_array_bytes_output` ABI represents the transformed array as little-endian signed 32-bit values.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm next_permutation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm next_permutation
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm next_permutation --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/n/next_permutation.c`](../../../c/n/next_permutation.c) |
| C3 | [`c3/n/next_permutation.c3`](../../../c3/n/next_permutation.c3) |
| C++ | [`cpp/n/next_permutation.cpp`](../../../cpp/n/next_permutation.cpp) |
| Elisa | [`elisa/n/next_permutation.elisa`](../../../elisa/n/next_permutation.elisa) |
| Nim | [`nim/n/next_permutation.nim`](../../../nim/n/next_permutation.nim) |
| Odin | [`odin/n/next_permutation.odin`](../../../odin/n/next_permutation.odin) |
| Rust | [`rust/n/next_permutation.rs`](../../../rust/n/next_permutation.rs) |
| V | [`v/n/next_permutation.v`](../../../v/n/next_permutation.v) |
| Zig | [`zig/n/next_permutation.zig`](../../../zig/n/next_permutation.zig) |
