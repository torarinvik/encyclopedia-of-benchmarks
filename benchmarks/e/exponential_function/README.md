# Exponential function Taylor sum

Approximate `e^power` with the pinned JavaScript implementation's truncated Taylor sum.

## Contract

The `float64_pair` ABI accepts `[power, term_count]`. `power` must be in `[-10, 10]`, and `term_count` must be an integer in `0..32`; invalid inputs return `-1e300`. For `term_count == 0`, return `1`. Otherwise, initialize `output = 0` and `factorial = 1`, then for `i = 0` through `term_count - 1` add `power^i / factorial` to the output and update `factorial *= i + 1`.

This preserves the source accumulation and factorial update order. The benchmark bounds keep the result finite and avoid factorial overflow. Valid outputs use absolute and relative tolerance `1e-12`.

## Source

The pinned JavaScript [`ExponentialFunction.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ExponentialFunction.js) computes a finite Taylor-series approximation rather than calling the platform exponential function. The source expects an integer order; the benchmark uses a bounded integral term count so that every port follows the same loop domain.

## Workload and recording

[`workload.json`](workload.json) includes the pinned example, zero and one term, positive and negative powers, the term-count boundary, invalid fractional counts, and out-of-range inputs.

The package uses the shared `float64_pair` benchmark ABI.

| Language | Source |
| --- | --- |
| C | [`c/e/exponential_function.c`](../../../c/e/exponential_function.c) |
| C3 | [`c3/e/exponential_function.c3`](../../../c3/e/exponential_function.c3) |
| C++ | [`cpp/e/exponential_function.cpp`](../../../cpp/e/exponential_function.cpp) |
| Elisa | [`elisa/e/exponential_function.elisa`](../../../elisa/e/exponential_function.elisa) |
| Nim | [`nim/e/exponential_function.nim`](../../../nim/e/exponential_function.nim) |
| Odin | [`odin/e/exponential_function.odin`](../../../odin/e/exponential_function.odin) |
| Rust | [`rust/e/exponential_function.rs`](../../../rust/e/exponential_function.rs) |
| V | [`v/e/exponential_function.v`](../../../v/e/exponential_function.v) |
| Zig | [`zig/e/exponential_function.zig`](../../../zig/e/exponential_function.zig) |
