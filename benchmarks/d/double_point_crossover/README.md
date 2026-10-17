# Double-point crossover

This benchmark makes the pinned MATLAB genetic-algorithm operator deterministic by including the two crossover positions in each input. The source chooses two distinct positions uniformly with `randperm`; this contract replays the same splice for an explicit pair of positions.

## Contract

- Input is `[n, j1, j2, parent1..., parent2...]`. `n` is 2 through 64, each parent has exactly `n` genes, and each gene is a signed 32-bit integer represented exactly by MATLAB's numeric array.
- `j1` and `j2` are 1-based positions satisfying `1 <= j1 < j2 <= n`, matching the sorted output of the source's two random positions. Each child keeps its parent's genes through `j1`, copies the other parent's genes from `j1 + 1` through `j2`, then keeps its parent's suffix after `j2`.
- The output serializes all `n` genes of child 1 followed by all `n` genes of child 2, each as little-endian signed 64-bit integers. The function returns the output byte count (`16*n`), `-1` for malformed input, and `-2` when the output buffer is too small.
- The output workspace is 1,024 bytes, enough for the maximum 64-gene parents.

[`workload.json`](workload.json) covers boundary and interior cuts, negative and repeated genes, signed 32-bit gene limits, the maximum length, malformed shapes and cuts, and short capacity. The independent oracle is [`double_point_crossover_oracle.py`](../../double_point_crossover_oracle.py).

## Pinned source

[MATLAB-Octave `DoublePointCrossover.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/DoublePointCrossover.m) draws a random permutation of gene positions and sorts its first two positions as cuts `j1 < j2`. Child 1 copies parent 2 from 1-based position `j1 + 1` through `j2` inclusive, while keeping parent 1 through `j1` and after `j2`; child 2 does the reciprocal splice.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm double_point_crossover --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm double_point_crossover
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/double_point_crossover.c`](../../../c/d/double_point_crossover.c) |
| C3 | [`c3/d/double_point_crossover.c3`](../../../c3/d/double_point_crossover.c3) |
| C++ | [`cpp/d/double_point_crossover.cpp`](../../../cpp/d/double_point_crossover.cpp) |
| Elisa | [`elisa/d/double_point_crossover.elisa`](../../../elisa/d/double_point_crossover.elisa) |
| Nim | [`nim/d/double_point_crossover.nim`](../../../nim/d/double_point_crossover.nim) |
| Odin | [`odin/d/double_point_crossover.odin`](../../../odin/d/double_point_crossover.odin) |
| Rust | [`rust/d/double_point_crossover.rs`](../../../rust/d/double_point_crossover.rs) |
| V | [`v/d/double_point_crossover.v`](../../../v/d/double_point_crossover.v) |
| Zig | [`zig/d/double_point_crossover.zig`](../../../zig/d/double_point_crossover.zig) |
