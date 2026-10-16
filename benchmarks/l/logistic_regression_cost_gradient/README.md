# Logistic Regression Cost and Gradient

This benchmark follows the pinned MATLAB-Octave `costfunction.m` and its `Sigmoid.m` helper. It evaluates binary logistic-regression loss and the gradient with respect to each supplied parameter; it does not train or update the parameters.

## Contract

The signed 64-bit input array is `[sample_count, feature_count, row_major_features_q1e6..., theta_q1e6..., labels...]`. There are 1–64 observations and 1–8 feature columns. Feature and parameter integers are in `[-1,000,000, 1,000,000]` and are divided by 1,000,000. Labels must be 0 or 1. The input length is exactly `2 + sample_count * feature_count + feature_count + sample_count`.

For each row, the score is the row-feature dot product with `theta`, and `p = 1 / (1 + exp(-score))`. The output vector is `[mean(-y*ln(p) - (1-y)*ln(1-p)), mean((p-y)*x_0), ..., mean((p-y)*x_(d-1))]`. The loss and gradient use input row order. Output values are little-endian IEEE-754 binary64 values; the function returns the output byte count. Malformed inputs return `-1`; insufficient output capacity returns `-2` without writing. Absolute output tolerance is `1e-10` and relative tolerance is `1e-12`.

This contract uses a rectangular design matrix and a column label vector, matching the source's intended matrix dimensions. It bounds score magnitude by eight, so probabilities remain strictly between zero and one and the source's logarithms are finite.

## Workload and build

[`workload.json`](workload.json) covers positive and negative labels, zero scores, multi-row and multi-feature gradients, malformed inputs, and insufficient output capacity. The shared byte-output runner checks the vector against an independent array oracle.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm logistic_regression_cost_gradient --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/logistic_regression_cost_gradient/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/logistic_regression_cost_gradient.c`](../../../c/l/logistic_regression_cost_gradient.c) |
| C3 | [`c3/l/logistic_regression_cost_gradient.c3`](../../../c3/l/logistic_regression_cost_gradient.c3) |
| C++ | [`cpp/l/logistic_regression_cost_gradient.cpp`](../../../cpp/l/logistic_regression_cost_gradient.cpp) |
| Elisa | [`elisa/l/logistic_regression_cost_gradient.elisa`](../../../elisa/l/logistic_regression_cost_gradient.elisa) |
| Nim | [`nim/l/logistic_regression_cost_gradient.nim`](../../../nim/l/logistic_regression_cost_gradient.nim) |
| Odin | [`odin/l/logistic_regression_cost_gradient.odin`](../../../odin/l/logistic_regression_cost_gradient.odin) |
| Rust | [`rust/l/logistic_regression_cost_gradient.rs`](../../../rust/l/logistic_regression_cost_gradient.rs) |
| V | [`v/l/logistic_regression_cost_gradient.v`](../../../v/l/logistic_regression_cost_gradient.v) |
| Zig | [`zig/l/logistic_regression_cost_gradient.zig`](../../../zig/l/logistic_regression_cost_gradient.zig) |

## Pinned MATLAB-Octave sources

- [`costfunction.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/costfunction.m)
- [`Sigmoid.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Logistic-Regression/Sigmoid.m)
