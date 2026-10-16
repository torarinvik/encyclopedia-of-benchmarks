# Gradient descent on the square function

This benchmark covers the update performed by the pinned Rust `gradient_descent` optimizer with the square-function derivative used in its own test. The generic callback API cannot be represented by the scalar benchmark ABI, so the bounded contract fixes `derivative_fn(x) = 2*x` and reports one caller-selected coordinate of the resulting vector. This is the pinned test's actual callback, not a claim to benchmark arbitrary derivative functions.

## Contract

- The `i64_array_float64` input is `[dimension, selected_index, learning_rate_microunits, iterations, x0, ..., x(dimension-1)]`.
- Dimension is 1 through 64, selected index is a valid zero-based coordinate, learning rate is 1 through 500,000 microunits (the source `f64` rate divided by 1,000,000), and iterations are 0 through 10,000. Initial integer coordinates are in -10 through 10.
- Each iteration computes the complete gradient vector `2*x` from the current vector, then applies the source's element-wise zipped update `x_k -= learning_rate * gradient_k`. Return the selected final coordinate as binary64.
- Malformed arrays or values outside the bounds return `-1e300`. Output tolerance is absolute `1e-10` and relative `1e-12`.
- The bounded workload keeps every update finite. The algorithm uses `O(dimension * iterations)` time and `O(dimension)` auxiliary storage.

## Source

The pinned [Rust `gradient_descent.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/optimization/gradient_descent.rs) accepts a derivative callback, mutates the parameter vector each iteration, computes the gradient once per iteration, and updates parameters by zipping them with the gradient. Its included test supplies `derivative_of_square(params) = 2*params`. This contract preserves that tested behavior, while restricting the callback and inputs so it can be represented consistently across the nine target languages.

## Workload and implementations

[`workload.json`](workload.json) includes both coordinates of the pinned two-value test, zero and one update, a one-dimensional vector, the maximum learning rate, and malformed shapes and bounds. The shared `i64_array_float64` runner checks expected values against [`gradient_descent_oracle.py`](../../gradient_descent_oracle.py), which replays the source-ordered gradient creation and zipped updates.

| Language | Port |
| --- | --- |
| C | [`c/g/gradient_descent.c`](../../../c/g/gradient_descent.c) |
| C3 | [`c3/g/gradient_descent.c3`](../../../c3/g/gradient_descent.c3) |
| C++ | [`cpp/g/gradient_descent.cpp`](../../../cpp/g/gradient_descent.cpp) |
| Elisa | [`elisa/g/gradient_descent.elisa`](../../../elisa/g/gradient_descent.elisa) |
| Nim | [`nim/g/gradient_descent.nim`](../../../nim/g/gradient_descent.nim) |
| Odin | [`odin/g/gradient_descent.odin`](../../../odin/g/gradient_descent.odin) |
| Rust | [`rust/g/gradient_descent.rs`](../../../rust/g/gradient_descent.rs) |
| V | [`v/g/gradient_descent.v`](../../../v/g/gradient_descent.v) |
| Zig | [`zig/g/gradient_descent.zig`](../../../zig/g/gradient_descent.zig) |
