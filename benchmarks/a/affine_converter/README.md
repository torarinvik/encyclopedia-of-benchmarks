# Affine converter

Applies the conversion `y = slope * x + intercept` using binary64 arithmetic. The benchmark covers the source class's `convert` operation.

## Contract

- Uses the three-input binary64 ABI: `double affine_converter(double slope, double x, double intercept)`.
- Each input is finite and in `[-1000, 1000]`.
- Return `slope * x + intercept`, evaluating the multiplication before the addition as in the source method.
- Results are compared with input-scaled tolerance `1e-12`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Java `AffineConverter`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/AffineConverter.java). Its `convert` method returns `slope * inValue + intercept`. The constructor rejects NaN slope and intercept but permits infinities; the shared workload narrows all three operands to finite values within `[-1000, 1000]` so the results remain bounded and portable. The class's `invert` and `compose` methods are outside this function contract.

## Workload and build

[`workload.json`](workload.json) covers identity, translation, positive and negative slopes, zero slope, fractional inputs, cancellation, and the operand bounds. Build and record with the `float64_triple` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm affine_converter --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/a/affine_converter/rust/build.json
```

The nine implementations are in `c/a/affine_converter.c`, `c3/a/affine_converter.c3`, `cpp/a/affine_converter.cpp`, `elisa/a/affine_converter.elisa`, `nim/a/affine_converter.nim`, `odin/a/affine_converter.odin`, `rust/a/affine_converter.rs`, `v/a/affine_converter.v`, and `zig/a/affine_converter.zig`.
