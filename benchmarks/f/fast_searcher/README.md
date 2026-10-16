# Fast searcher

Search a strictly increasing integer array with the hybrid probe strategy from the pinned C# `FastSearcher`: calculate an interpolation estimate, pair it with the binary midpoint, select the segment that can contain the target, and recurse into that segment.

## Contract

- Input is `[count, sorted_values..., target]`. The array has 0 through 64 values, all in `[-1000, 1000]`; values must be strictly increasing. The target is also in `[-1000, 1000]`.
- Return the zero-based index of a matching value. Return `-1` when the array is empty or the target is absent, including a target outside the array bounds.
- Malformed length, invalid count, out-of-range values, duplicate or descending values, null input, or an out-of-range target returns `-2`.
- Miss exceptions from the C# source are represented by `-1`. The strict-order and value bounds preserve its first-match result and keep its 32-bit interpolation arithmetic in range.
- The parser accepts 67 values so a 65-element over-limit case can reach the function.

## Workload and oracle

[`workload.json`](workload.json) covers empty, singleton, first/middle/last hits, in-range and out-of-range misses, the maximum valid array, and malformed inputs. The independent oracle uses a linear scan: [`fast_searcher_oracle.py`](../../fast_searcher_oracle.py).

## Reviewed source

[TheAlgorithms/C-Sharp `FastSearcher.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/FastSearcher.cs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm fast_searcher --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm fast_searcher
python3 benchmarks/verify_i64_array_scalar.py --algorithm fast_searcher
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fast_searcher.c`](../../../c/f/fast_searcher.c) |
| C3 | [`c3/f/fast_searcher.c3`](../../../c3/f/fast_searcher.c3) |
| C++ | [`cpp/f/fast_searcher.cpp`](../../../cpp/f/fast_searcher.cpp) |
| Elisa | [`elisa/f/fast_searcher.elisa`](../../../elisa/f/fast_searcher.elisa) |
| Nim | [`nim/f/fast_searcher.nim`](../../../nim/f/fast_searcher.nim) |
| Odin | [`odin/f/fast_searcher.odin`](../../../odin/f/fast_searcher.odin) |
| Rust | [`rust/f/fast_searcher.rs`](../../../rust/f/fast_searcher.rs) |
| V | [`v/f/fast_searcher.v`](../../../v/f/fast_searcher.v) |
| Zig | [`zig/f/fast_searcher.zig`](../../../zig/f/fast_searcher.zig) |
