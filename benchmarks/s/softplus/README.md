# Softplus

This benchmark ports the pinned Python `softplus` activation. It evaluates the source expression `log(1 + exp(x))` on a one-element input array, represented here by the shared scalar ABI.

## Contract

- The `float64_unary` ABI accepts one finite binary64 value `x` in `[-100, 100]` and returns a binary64 value.
- The calculation preserves the source order: evaluate `exp(x)`, add `1`, then take the natural logarithm. This direct expression can round very small positive outputs to zero; for example, the source expression at `x=-100` returns `0` in binary64. The ports keep this behavior instead of substituting a numerically stabilized formula.
- Non-finite and out-of-range inputs return `-1e300`.
- The workload uses relative and absolute tolerances of `1e-12` for binary64 library rounding.

Softplus is `log(1 + exp(x))`. It is a distinct activation from the repository's sigmoid, ReLU, and swish benchmarks. The pinned Python function accepts NumPy arrays and applies this operation elementwise; the benchmark scalarizes a one-element array.

## Source

- [TheAlgorithms/Python `softplus.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/neural_network/activation_functions/softplus.py)

## Workload and build

[`workload.json`](workload.json) includes the pinned examples, zero, both domain endpoints, and invalid boundary values. All nine ports use the `float64_unary` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm softplus --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/softplus/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/softplus.c`](../../../c/s/softplus.c) |
| C3 | [`c3/s/softplus.c3`](../../../c3/s/softplus.c3) |
| C++ | [`cpp/s/softplus.cpp`](../../../cpp/s/softplus.cpp) |
| Elisa | [`elisa/s/softplus.elisa`](../../../elisa/s/softplus.elisa) |
| Nim | [`nim/s/softplus.nim`](../../../nim/s/softplus.nim) |
| Odin | [`odin/s/softplus.odin`](../../../odin/s/softplus.odin) |
| Rust | [`rust/s/softplus.rs`](../../../rust/s/softplus.rs) |
| V | [`v/s/softplus.v`](../../../v/s/softplus.v) |
| Zig | [`zig/s/softplus.zig`](../../../zig/s/softplus.zig) |
