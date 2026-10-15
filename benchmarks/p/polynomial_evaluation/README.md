# Polynomial evaluation with Horner's method

Evaluates a polynomial using the Horner routine in the pinned Python source.

## Contract

- Uses `i64_array_scalar` with packed input `[coefficient_count, x, coefficient_0, ..., coefficient_(n-1)]`.
- Coefficients are ordered by ascending degree: `coefficient_i` multiplies `x^i`.
- `coefficient_count` is `0..8`; `x` is `-10..10`; every coefficient is `-1000..1000`.
- Return the exact integer-valued result of Horner's recurrence. The recurrence starts at zero and processes coefficients in descending index order: `result = result * x + coefficient`.
- An empty coefficient list returns `0`.
- Return `INT64_MIN` for malformed packing or values outside the stated bounds.

The largest possible absolute result is at most `1000 * (1 + 10 + ... + 10^7) = 11,111,111,000`, below `2^53`. Thus all selected inputs and results are exactly representable as binary64 as well as signed 64-bit integers; the integer ports preserve the source's arithmetic exactly.

## Source semantics

This follows pinned [TheAlgorithms Python `polynomial_evaluation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/polynomial_evaluation.py), specifically its `horner` routine. The same file also contains `evaluate_poly`, which evaluates each power directly; this benchmark covers only Horner's method and keeps its reverse coefficient traversal and multiply-then-add order. The separate JavaScript `Polynomial` source constructs a display string and is not an evaluation routine.

## Workload and build

[`workload.json`](workload.json) includes empty, constant, sparse, positive and negative coefficient sets, and boundary values. Build and record with the existing array scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm polynomial_evaluation --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/p/polynomial_evaluation/rust/build.json
```

The nine implementations are in `c/p/polynomial_evaluation.c`, `c3/p/polynomial_evaluation.c3`, `cpp/p/polynomial_evaluation.cpp`, `elisa/p/polynomial_evaluation.elisa`, `nim/p/polynomial_evaluation.nim`, `odin/p/polynomial_evaluation.odin`, `rust/p/polynomial_evaluation.rs`, `v/p/polynomial_evaluation.v`, and `zig/p/polynomial_evaluation.zig`.
