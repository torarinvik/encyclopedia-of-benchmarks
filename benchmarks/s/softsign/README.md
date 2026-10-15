# Softsign

This benchmark ports the pinned Python softsign activation, `vector / (1 + abs(vector))`, applied elementwise to a one-element vector and exposed through the shared `float64_unary` ABI.

## Contract

- The input is a finite binary64 value `x` in `[-1e100, 1e100]`.
- Return `x / (1 + abs(x))` in binary64, preserving the source's division and denominator order.
- Non-finite and out-of-range inputs return `-1e300`.
- The workload allows relative and absolute error up to `1e-12` for platform floating-point rounding.

The source accepts NumPy vectors; this benchmark scalarizes a one-element vector. Softsign maps finite inputs into `(-1, 1)` and approaches the endpoints algebraically. It differs from the existing `tanh` benchmark, whose implementation uses a hyperbolic tangent, and from the sigmoid, softplus, ReLU, and swish activation packages.

## Source

- [TheAlgorithms/Python `softsign.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/softsign.py)

## Workload and build

[`workload.json`](workload.json) covers zero, positive and negative values, large magnitudes, the domain endpoints, and invalid boundary values. All nine ports use the `float64_unary` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm softsign --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/softsign/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/softsign.c`](../../../c/s/softsign.c) |
| C3 | [`c3/s/softsign.c3`](../../../c3/s/softsign.c3) |
| C++ | [`cpp/s/softsign.cpp`](../../../cpp/s/softsign.cpp) |
| Elisa | [`elisa/s/softsign.elisa`](../../../elisa/s/softsign.elisa) |
| Nim | [`nim/s/softsign.nim`](../../../nim/s/softsign.nim) |
| Odin | [`odin/s/softsign.odin`](../../../odin/s/softsign.odin) |
| Rust | [`rust/s/softsign.rs`](../../../rust/s/softsign.rs) |
| V | [`v/s/softsign.v`](../../../v/s/softsign.v) |
| Zig | [`zig/s/softsign.zig`](../../../zig/s/softsign.zig) |
