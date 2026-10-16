# Gauss-Legendre

Compute an approximation of pi using the pinned Java Gauss-Legendre iteration.

## Contract

- The `float64_unary` input is one finite binary64 value representing an integer iteration count from 0 through 8.
- The Java source demonstrates counts 1, 2, and 3. Count 0 follows its zero-iteration loop behavior; 0 through 8 bounds the work and keeps the recurrence well-conditioned.
- Non-integral, non-finite, negative, or above-bound inputs return `-1e300` as the benchmark's invalid-input result.
- Each iteration updates the arithmetic mean, geometric mean, correction term, and doubling factor in the order used by the source. The oracle evaluates the same recurrence at higher decimal precision.
- Valid results are compared with relative and absolute tolerance `1e-12`.

## Pinned source

The benchmark follows [`GaussLegendre.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/GaussLegendre.java). Its `pi` method starts with `a = 1`, `b = 2^-0.5`, `t = 0.25`, and `p = 1`, then applies the four-state update before returning `(a + b)^2 / (4t)`.

[`workload.json`](workload.json) includes the source's 1–3 iteration examples, both iteration boundaries, and malformed numeric inputs.

## Build and record

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm gauss_legendre --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/g/gauss_legendre/rust/build.json
python3 benchmarks/verify_float64_unary.py --algorithm gauss_legendre
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gauss_legendre.c`](../../../c/g/gauss_legendre.c) |
| C3 | [`c3/g/gauss_legendre.c3`](../../../c3/g/gauss_legendre.c3) |
| C++ | [`cpp/g/gauss_legendre.cpp`](../../../cpp/g/gauss_legendre.cpp) |
| Elisa | [`elisa/g/gauss_legendre.elisa`](../../../elisa/g/gauss_legendre.elisa) |
| Nim | [`nim/g/gauss_legendre.nim`](../../../nim/g/gauss_legendre.nim) |
| Odin | [`odin/g/gauss_legendre.odin`](../../../odin/g/gauss_legendre.odin) |
| Rust | [`rust/g/gauss_legendre.rs`](../../../rust/g/gauss_legendre.rs) |
| V | [`v/g/gauss_legendre.v`](../../../v/g/gauss_legendre.v) |
| Zig | [`zig/g/gauss_legendre.zig`](../../../zig/g/gauss_legendre.zig) |
