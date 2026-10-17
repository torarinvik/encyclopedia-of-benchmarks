# Binary mutation

This benchmark ports the pinned MATLAB `Mutate(x, mu)` operator over one binary row vector. For each gene, it flips `0` to `1` or `1` to `0` exactly when that gene's uniform draw is strictly less than `mu`. The workload supplies the draws so every language evaluates the same decisions; it does not benchmark a random-number generator.

## Contract

- ABI: `float64_slice_io`. Input is `[mu, n, genes..., draws...]`, with exactly `2 + 2*n` values. `n` is an exactly integral binary64 value in `[0, 64]`; the genome and draw sequence are matching one-dimensional row vectors of length `n`.
- `mu` is finite and in `[0, 1]`. Each gene is exactly `0` or `1`; each supplied draw is finite and in `[0, 1)`. These bounds select a portable subset of the MATLAB source's inputs.
- For each index `i`, output `1 - genes[i]` if `draws[i] < mu`; otherwise output `genes[i]`. Equality does not flip a gene. The output is the mutated row vector, with one value per input gene.
- Success returns `n`. Malformed framing, nonfinite values, or values outside the domain return `-1`. For valid input, a null output pointer or capacity below `n` returns `-2` without writing output; null output is invalid even when `n` is zero. A valid empty genome is encoded as `[mu, 0]` and returns an empty output with result `0` when the output pointer is nonnull.
- Maximum input length is 130 values and maximum output capacity is 64 values. Comparisons use zero absolute and relative tolerance.

The pinned source draws `rand(size(x))`, copies `x`, and replaces selected entries with `1 - x`. Supplying one draw per gene makes that threshold operator deterministic while preserving the source's strict comparison and per-position behavior. The contract covers row vectors only and does not claim arbitrary matrix-shape behavior.

## Workload and oracle

[`workload.json`](workload.json) covers `mu` at zero and one, draws below/equal/above the threshold, an empty genome, the 64-gene bound, malformed frames, invalid genes and draws, nonfinite inputs, and null/short output capacity. The independent [oracle](../../mutate_oracle.py) applies the threshold rule directly.

## Pinned source

[TheAlgorithms/MATLAB-Octave `Mutate.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/Mutate.m) implements `flag = rand(size(x)) < mu`, initializes `y = x`, then assigns `y(flag) = 1 - x(flag)`.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm mutate --language rust
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/m/mutate/rust/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm mutate --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/m/mutate.c`](../../../c/m/mutate.c) |
| C3 | [`c3/m/mutate.c3`](../../../c3/m/mutate.c3) |
| C++ | [`cpp/m/mutate.cpp`](../../../cpp/m/mutate.cpp) |
| Elisa | [`elisa/m/mutate.elisa`](../../../elisa/m/mutate.elisa) |
| Nim | [`nim/m/mutate.nim`](../../../nim/m/mutate.nim) |
| Odin | [`odin/m/mutate.odin`](../../../odin/m/mutate.odin) |
| Rust | [`rust/m/mutate.rs`](../../../rust/m/mutate.rs) |
| V | [`v/m/mutate.v`](../../../v/m/mutate.v) |
| Zig | [`zig/m/mutate.zig`](../../../zig/m/mutate.zig) |
