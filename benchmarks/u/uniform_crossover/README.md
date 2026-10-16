# Uniform crossover

This benchmark replays the pinned MATLAB genetic-algorithm operator with an explicit per-locus mask. The source draws a random binary array; the benchmark supplies that draw so each call is deterministic.

## Contract

- Input is `[n, alpha..., parent1..., parent2...]`. `n` is 1 through 64, the mask and both parents each contain exactly `n` entries, and each parent gene is a signed 32-bit integer represented exactly by MATLAB numeric values.
- Every `alpha` is 0 or 1. For `alpha[i] == 1`, child 1 keeps parent 1's gene and child 2 keeps parent 2's gene. For `alpha[i] == 0`, the two genes are exchanged.
- The output serializes all genes of child 1 followed by all genes of child 2, each as little-endian signed 64-bit integers. The function returns the output byte count (`16*n`), `-1` for malformed input, and `-2` when the output buffer is too small.
- The output workspace is 1,024 bytes, enough for the maximum 64-gene parents.

[`workload.json`](workload.json) covers one-locus masks, all-zero and all-one masks, alternating selections, repeated and negative genes, signed 32-bit gene limits, maximum length, malformed input, and short capacity. The independent oracle is [`uniform_crossover_oracle.py`](../../uniform_crossover_oracle.py).

## Pinned source

[MATLAB-Octave `UniformCrossover.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/UniformCrossover.m) draws `alpha` with `randi([0,1], size(x1))` and selects each output gene using `alpha*x1 + (1-alpha)*x2` and the reciprocal expression. The shared contract bounds the genes to signed 32-bit integers, where those expressions select the exact input value.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm uniform_crossover --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm uniform_crossover
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/u/uniform_crossover.c`](../../../c/u/uniform_crossover.c) |
| C3 | [`c3/u/uniform_crossover.c3`](../../../c3/u/uniform_crossover.c3) |
| C++ | [`cpp/u/uniform_crossover.cpp`](../../../cpp/u/uniform_crossover.cpp) |
| Elisa | [`elisa/u/uniform_crossover.elisa`](../../../elisa/u/uniform_crossover.elisa) |
| Nim | [`nim/u/uniform_crossover.nim`](../../../nim/u/uniform_crossover.nim) |
| Odin | [`odin/u/uniform_crossover.odin`](../../../odin/u/uniform_crossover.odin) |
| Rust | [`rust/u/uniform_crossover.rs`](../../../rust/u/uniform_crossover.rs) |
| V | [`v/u/uniform_crossover.v`](../../../v/u/uniform_crossover.v) |
| Zig | [`zig/u/uniform_crossover.zig`](../../../zig/u/uniform_crossover.zig) |
