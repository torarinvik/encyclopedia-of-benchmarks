# Single-point crossover

This benchmark isolates the `SinglePointCrossover` helper from the pinned
[TheAlgorithms/MATLAB-Octave source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/SinglePointCrossover.m).
It specializes the source's equal-length numeric row vectors to finite binary64
genes and supplies the cut explicitly so every port receives the same input.

## Contract

- ABI: `float64_slice_io`. The flat input is `[n, j, x1[0:n], x2[0:n]]`;
  `n` and `j` must be exactly integral binary64 values. Parent length `n` is in
  `[2, 31]`, and the prefix length `j` is in `[1, n-1]`. The input length must
  be exactly `2 + 2*n`. Every gene must be finite. The maximum valid input has
  64 elements.
- The source chooses `j` uniformly in MATLAB's one-based range `1..n-1`, then
  returns `[x1(1:j), x2(j+1:end)]` and `[x2(1:j), x1(j+1:end)]`. Here `j` is
  the number of prefix genes retained from each parent; in zero-based slices,
  each child copies the prefix `[0, j)` and swaps the suffix `[j, n)`. The
  benchmark makes the random cut an input and does not measure random-number
  generation.
- Output is `child1[0:n]` followed by `child2[0:n]`. Success returns `2*n`.
  Invalid input returns `-1`; a null output pointer or capacity below `2*n`
  returns `-2` without writing, after input validation. Since the operator only
  copies genes, output comparison is exact (`atol=0`, `rtol=0`).
- The largest valid call uses 64 input and 62 output elements. A 66-element
  malformed call is parseable to check `n=32` rejection.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/s/single_point_crossover.c`](../../../c/s/single_point_crossover.c) |
| C3 | [`c3/s/single_point_crossover.c3`](../../../c3/s/single_point_crossover.c3) |
| C++ | [`cpp/s/single_point_crossover.cpp`](../../../cpp/s/single_point_crossover.cpp) |
| Elisa | [`elisa/s/single_point_crossover.elisa`](../../../elisa/s/single_point_crossover.elisa) |
| Nim | [`nim/s/single_point_crossover.nim`](../../../nim/s/single_point_crossover.nim) |
| Odin | [`odin/s/single_point_crossover.odin`](../../../odin/s/single_point_crossover.odin) |
| Rust | [`rust/s/single_point_crossover.rs`](../../../rust/s/single_point_crossover.rs) |
| V | [`v/s/single_point_crossover.v`](../../../v/s/single_point_crossover.v) |
| Zig | [`zig/s/single_point_crossover.zig`](../../../zig/s/single_point_crossover.zig) |

## Workload and oracle

[`workload.json`](workload.json) covers both parents' minimum length, first,
middle, and last legal cuts, signed and fractional genes, duplicate and zero
genes, the maximum parent length, and malformed finite inputs. The independent
[oracle](../../single_point_crossover_oracle.py) applies the same prefix/suffix
copy operation. ABI probes also check nonfinite genes, null output, and short
output capacity.

