# Arithmetic Mean

Compute the arithmetic mean of a nonempty integer sequence.

## Contract

- Uses the `i64_array_float64_call` ABI with one signed 64-bit integer array.
- Accepts 1 through 64 signed integer values, each in [-1,000,000, 1,000,000]. The bounded sum fits signed 64-bit arithmetic; output is binary64.
- The source sums the integer values and divides by list length using true division. It raises on empty/non-list input; invalid lengths and values map to -1e300 in this ABI.
- The result follows the source operation: `sum(values) / length`.

## Source semantics

This follows [TheAlgorithms Python `arithmetic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/arithmetic.py) and the `arithmeticMean` function in the pinned [Haskell `Center.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Statistics/Center.hs); both sum the values and divide by their count. The Python file also contains the separately benchmarked routine `is_arithmetic_series`. These ports implement the bounded integer-list subset.

## Workload

[`workload.json`](workload.json) covers source-like values, singleton behavior, signed values, and invalid lengths or elements.

## Verification

Run the independent array oracle against the supported language ports with:

```sh
python3 benchmarks/verify_arithmetic_mean.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_mean.c`](../../../c/a/arithmetic_mean.c) |
| C3 | [`c3/a/arithmetic_mean.c3`](../../../c3/a/arithmetic_mean.c3) |
| CPP | [`cpp/a/arithmetic_mean.cpp`](../../../cpp/a/arithmetic_mean.cpp) |
| ELISA | [`elisa/a/arithmetic_mean.elisa`](../../../elisa/a/arithmetic_mean.elisa) |
| NIM | [`nim/a/arithmetic_mean.nim`](../../../nim/a/arithmetic_mean.nim) |
| ODIN | [`odin/a/arithmetic_mean.odin`](../../../odin/a/arithmetic_mean.odin) |
| RUST | [`rust/a/arithmetic_mean.rs`](../../../rust/a/arithmetic_mean.rs) |
| V | [`v/a/arithmetic_mean.v`](../../../v/a/arithmetic_mean.v) |
| ZIG | [`zig/a/arithmetic_mean.zig`](../../../zig/a/arithmetic_mean.zig) |
