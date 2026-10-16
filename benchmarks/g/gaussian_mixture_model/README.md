# Gaussian Mixture Model

The pinned Python class fits a Gaussian mixture with the expectation-maximization (EM) algorithm, evaluates component densities, updates mixture weights, means, and covariances, stops when log-likelihood change falls below a tolerance, and predicts the most likely component. This contract specializes that algorithm to one-dimensional data and two components. It uses the first and last sorted samples as deterministic initial means, equal initial weights, and the source's global sample covariance plus `1e-6` for both initial variances. This replaces the source's random mean selection so every language starts from the same state. The source's SciPy, NumPy, printing, and plotting wrappers are excluded.

## Contract

Input is `[sample_count, max_iterations, tolerance_micro, samples_milli...]`. Sample count is 2 through 16, iteration limit is 1 through 20, and tolerance is 1 through 1000 millionths. Samples are sorted nondecreasing integers from `-5000` through `5000`, interpreted as thousandths. The M-step adds the source's `1e-6` covariance regularizer. Invalid input or a degenerate E-step returns `-1`.

Output is one byte with the number of EM iterations performed, followed by one label byte per sample (`0` or `1`). Posterior ties select component zero. The return value is the number of output bytes. Insufficient capacity returns `-2`.

The input has at most 19 signed 64-bit values and output at most 17 bytes. See [`workload.json`](workload.json) for separated modes, identical samples, invalid input, and capacity cases.

Focused verification passed for C, C3, C++, Nim, Odin, Rust, V, and Zig (146 oracle inputs and 5 workload records per port). With the configured Elisa stage1 compiler, the source is declined because the backend rejects the helper call expression used by the Gaussian density; no Elisa function symbol is emitted, so that port is not counted as verified.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian_mixture_model.c`](../../../c/g/gaussian_mixture_model.c) |
| C3 | [`c3/g/gaussian_mixture_model.c3`](../../../c3/g/gaussian_mixture_model.c3) |
| C++ | [`cpp/g/gaussian_mixture_model.cpp`](../../../cpp/g/gaussian_mixture_model.cpp) |
| Elisa | [`elisa/g/gaussian_mixture_model.elisa`](../../../elisa/g/gaussian_mixture_model.elisa) |
| Nim | [`nim/g/gaussian_mixture_model.nim`](../../../nim/g/gaussian_mixture_model.nim) |
| Odin | [`odin/g/gaussian_mixture_model.odin`](../../../odin/g/gaussian_mixture_model.odin) |
| Rust | [`rust/g/gaussian_mixture_model.rs`](../../../rust/g/gaussian_mixture_model.rs) |
| V | [`v/g/gaussian_mixture_model.v`](../../../v/g/gaussian_mixture_model.v) |
| Zig | [`zig/g/gaussian_mixture_model.zig`](../../../zig/g/gaussian_mixture_model.zig) |

## Pinned source

[TheAlgorithms/Python `gaussian_mixture_model.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/gaussian_mixture_model.py)
