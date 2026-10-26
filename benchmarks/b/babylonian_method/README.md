# Babylonian method, bounded C++ path

This benchmark preserves the terminating non-square path of the pinned C++ `babylonian_method` implementation. It returns the first Newton-style Babylonian update from the integer square-root floor.

## Contract

- Input is one finite binary64 value that is an integer radicand in `[2, 999999]` and is not a perfect square.
- The algorithm finds `k = floor(sqrt(n))` by the source's incrementing integer loop, then returns `(n / k + k) / 2` using binary64 arithmetic.
- Inputs that are nonintegral, outside the bound, or perfect squares return `-1.0`. The square exclusion avoids the pinned source's nonterminating loop case.
- Valid inputs return the source's first update. Invalid inputs return `-1.0`; the ABI uses constant time auxiliary space and an integer-search loop bounded by 1,000 steps.

## Source semantics

Both pinned C++ snapshots use the same implementation: [TheAlgorithms/C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/babylonian_method.cpp) and [TheAlgorithms/C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/babylonian_method.cpp). After calculating the first update, the source loops while the difference between the two estimates is *less than* `0.0001`. For a non-square integer in this benchmark's range, that first difference is at least `1 / (2 * 999)`, so the source returns the first update without entering the loop. A perfect square has a zero difference and would repeat forever; the benchmark rejects those inputs.

This behavior is distinct from the Julia [`babylonian_sqrt`](../../b/babylonian_sqrt/README.md), which iterates from half the input using a squared-residual threshold. The Java [`square_root_with_babylonian_method`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SquareRootWithBabylonianMethod.java) is an algorithm-level alias of that canonical square-root benchmark; its binary32 state and loop condition are source-profile details.

[`workload.json`](workload.json) covers small and large nonsquare radicands, the pinned C++ examples, perfect squares, fractional values, and the numeric bounds. The shared `float64_unary` oracle checks the bounded first-update behavior.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm babylonian_method --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/b/babylonian_method/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/babylonian_method.c](../../../c/b/babylonian_method.c) |
| C3 | [c3/b/babylonian_method.c3](../../../c3/b/babylonian_method.c3) |
| C++ | [cpp/b/babylonian_method.cpp](../../../cpp/b/babylonian_method.cpp) |
| Elisa | [elisa/b/babylonian_method.elisa](../../../elisa/b/babylonian_method.elisa) |
| Nim | [nim/b/babylonian_method.nim](../../../nim/b/babylonian_method.nim) |
| Odin | [odin/b/babylonian_method.odin](../../../odin/b/babylonian_method.odin) |
| Rust | [rust/b/babylonian_method.rs](../../../rust/b/babylonian_method.rs) |
| V | [v/b/babylonian_method.v](../../../v/b/babylonian_method.v) |
| Zig | [zig/b/babylonian_method.zig](../../../zig/b/babylonian_method.zig) |
