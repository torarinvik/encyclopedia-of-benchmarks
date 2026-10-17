# Joint probability distribution

This package adapts the pinned Python `joint_probability_distribution` function, which forms the independent Cartesian product and assigns each pair probability `px * py`.

## Contract

- ABI: `float64_slice_io`. Input is `[nx, ny, x_values..., y_values..., x_probabilities..., y_probabilities...]`; `nx` and `ny` are each in `[1, 4]`, and the packed length must be exactly `2 + 2*nx + 2*ny`.
- Supports are unique integer-valued numbers in `[-1000, 1000]`. Probability arrays are aligned with their supports and contain finite numbers in `[-1,000,000, 1,000,000]`.
- Output is a flat sequence of triples `[x, y, px*py]`, with x values in outer-loop order and y values in inner-loop order. The function returns the number of output float64 elements, which is `3*nx*ny`; insufficient output capacity returns `-2`, and malformed or out-of-domain inputs return `-1`.
- Probabilities are multiplied as supplied. The adapter does not normalize either marginal distribution.

The Python source uses `zip` and a dictionary comprehension. The bounded contract requires aligned arrays and unique supports, so zip truncation and duplicate tuple-key overwrites cannot occur for accepted inputs. The output order follows the source's x-major nested loops and preserves dictionary insertion order on this domain.

## Workload and source

[`workload.json`](workload.json) covers the pinned example, single-pair output, unnormalized and negative probabilities, maximum support sizes, and invalid counts/framing/supports/probabilities. The verifier also probes insufficient output capacity. The independent [oracle](../../joint_probability_distribution_oracle.py) follows the Cartesian product and direct multiplication without normalization.

Pinned source: [TheAlgorithms/Python `joint_probability_distribution.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/joint_probability_distribution.py), function `joint_probability_distribution`.

## Implementations

| Language | Port |
|---|---|
| C | [`c/j/joint_probability_distribution.c`](../../../c/j/joint_probability_distribution.c) |
| C3 | [`c3/j/joint_probability_distribution.c3`](../../../c3/j/joint_probability_distribution.c3) |
| C++ | [`cpp/j/joint_probability_distribution.cpp`](../../../cpp/j/joint_probability_distribution.cpp) |
| Elisa | [`elisa/j/joint_probability_distribution.elisa`](../../../elisa/j/joint_probability_distribution.elisa) |
| Nim | [`nim/j/joint_probability_distribution.nim`](../../../nim/j/joint_probability_distribution.nim) |
| Odin | [`odin/j/joint_probability_distribution.odin`](../../../odin/j/joint_probability_distribution.odin) |
| Rust | [`rust/j/joint_probability_distribution.rs`](../../../rust/j/joint_probability_distribution.rs) |
| V | [`v/j/joint_probability_distribution.v`](../../../v/j/joint_probability_distribution.v) |
| Zig | [`zig/j/joint_probability_distribution.zig`](../../../zig/j/joint_probability_distribution.zig) |
