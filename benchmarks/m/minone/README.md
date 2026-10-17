# `minone` sum-of-squares objective

The pinned MATLAB function is an objective function, not a minimization routine: it applies element-wise squaring and sums a vector. This bounded adapter uses integer vectors so every input square and the final result are exact in the source's binary64 arithmetic.

## Contract

- Input is a nonempty signed 64-bit integer vector of length 1 through 64. Every element must be in `[-1,000,000, 1,000,000]`.
- Return `sum(x[i] * x[i])` as a signed 64-bit scalar. A null input pointer, invalid length, or out-of-range value returns `-1`.
- The largest possible result is `64,000,000,000,000`, below `2^53`; MATLAB represents each square and the sum exactly as a double.
- The vector restriction keeps MATLAB's default `sum` dimension scalar. Matrix column-sum behavior is outside this adapter.

[`workload.json`](workload.json) covers zero, singleton and mixed-sign vectors, value limits, maximum length, and invalid inputs. The independent oracle is [`minone_oracle.py`](../../minone_oracle.py).

## Pinned source

The pinned MATLAB-Octave [`minone.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/Genetic-Algorithm/Minimization%20of%20polynomial%20function/minone.m) computes `sum(x.^2)`. This benchmark is distinct from the existing `sum_of_squares` candidate, which returns the minimum number of square summands for an integer.

| Language | Source |
| --- | --- |
| C | [`c/m/minone.c`](../../../c/m/minone.c) |
| C3 | [`c3/m/minone.c3`](../../../c3/m/minone.c3) |
| C++ | [`cpp/m/minone.cpp`](../../../cpp/m/minone.cpp) |
| Elisa | [`elisa/m/minone.elisa`](../../../elisa/m/minone.elisa) |
| Nim | [`nim/m/minone.nim`](../../../nim/m/minone.nim) |
| Odin | [`odin/m/minone.odin`](../../../odin/m/minone.odin) |
| Rust | [`rust/m/minone.rs`](../../../rust/m/minone.rs) |
| V | [`v/m/minone.v`](../../../v/m/minone.v) |
| Zig | [`zig/m/minone.zig`](../../../zig/m/minone.zig) |
