# Geometric mean

Compute the signed nth root of the product of the input values, following the pinned Python implementation. This contract uses the existing integer-array-to-binary64 ABI.

## Contract

- The input is the argument list itself: a signed 64-bit integer array with length `n` from 1 through 6. Each value must be in `[-100, 100]`.
- Multiply values from left to right as exact integers. After processing all values, if the final product is negative and the total input length is even, return the shared ABI invalid-input sentinel `-1e300`. The source checks only the final product, so order does not affect validity: `[-2, -2]` returns `2.0`, and both `[0, -1]` and `[-1, 0]` return `0.0`.
- Otherwise calculate `abs(product) ** (1 / n)` and negate the result when the final product is negative. Round that signed root to the nearest integer, and replace it with the rounded value only when raising it to `n` exactly equals the original signed product. This correction also applies to negative perfect roots of odd length. Zero in any nonempty input returns `0.0`.
- The pinned source raises on an empty argument list and when the final product is negative for an even-length argument list; the benchmark maps these cases and inputs outside the length/value bounds to `-1e300`.
- The product magnitude is at most `100^6 = 10^12`, so its integer multiplication is safe in signed 64-bit arithmetic and exactly representable as binary64. The workload uses exact-result cases, including a negative odd-length product.
- Time is `O(n)` and auxiliary space is `O(1)`.

## Source and related algorithms

The pinned [Python `geometric_mean.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/geometric_mean.py) accepts variadic numeric arguments, checks the final product for a forbidden negative value when the total argument count is even, takes an `n`th root, preserves the sign for negative products of odd length, and snaps an exactly representable rounded root to an integer. The `geometricMean` function in the pinned [Haskell `Center.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Statistics/Center.hs) computes the product raised to the reciprocal count; the shared benchmark domain restricts this source to bounded positive integers. The separately named `arithmetic_geometric_mean` candidate iterates the arithmetic and geometric means of two values; it is a different operation.

## Workload and build

[`workload.json`](workload.json) covers lengths one through six, zero, negative inputs, a non-perfect finite root, exact positive perfect powers, the signed odd-root case, and ABI invalid cases. All nine ports use the shared `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm geometric_mean --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/geometric_mean/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/geometric_mean.c`](../../../c/g/geometric_mean.c) |
| C3 | [`c3/g/geometric_mean.c3`](../../../c3/g/geometric_mean.c3) |
| C++ | [`cpp/g/geometric_mean.cpp`](../../../cpp/g/geometric_mean.cpp) |
| Elisa | [`elisa/g/geometric_mean.elisa`](../../../elisa/g/geometric_mean.elisa) |
| Nim | [`nim/g/geometric_mean.nim`](../../../nim/g/geometric_mean.nim) |
| Odin | [`odin/g/geometric_mean.odin`](../../../odin/g/geometric_mean.odin) |
| Rust | [`rust/g/geometric_mean.rs`](../../../rust/g/geometric_mean.rs) |
| V | [`v/g/geometric_mean.v`](../../../v/g/geometric_mean.v) |
| Zig | [`zig/g/geometric_mean.zig`](../../../zig/g/geometric_mean.zig) |
