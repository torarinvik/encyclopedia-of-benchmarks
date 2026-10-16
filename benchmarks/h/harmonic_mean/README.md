# Harmonic mean

Compute the harmonic mean of a nonempty list of positive values, following the pinned Java `Means.harmonic` method.

## Contract

- The `i64_array_float64` ABI receives the values directly, with length 1 through 64.
- Each value is a positive integer from 1 through 1,000. Zero and negative values are excluded because the source formula sums reciprocals.
- Return `n / sum(1 / value)` as binary64, using relative and absolute tolerance `1e-12`.
- Empty input or out-of-range values return `-1e300`.
- The method takes `O(n)` time and constant auxiliary storage.

## Source

This follows the `harmonic` method in the pinned [TheAlgorithms Java `Means.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Means.java), the `harmonicMean` function in the pinned [Haskell `Center.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Statistics/Center.hs), and the `harmonic_mean` function in pinned [TheAlgorithms Python `harmonic.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/harmonic.py). They compute the count divided by the sum of the reciprocals. The Python file also defines `is_harmonic_series`, a separate predicate that is not covered by this benchmark. The benchmark uses a bounded positive integer subset from 1 through 1,000 and maps the source's empty-list exception to the sentinel.

## Workload

[`workload.json`](workload.json) covers singleton, equal values, the source example, reciprocal sums, the upper value and length bounds, and invalid input.

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_harmonic_mean.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/harmonic_mean.c`](../../../c/h/harmonic_mean.c) |
| C3 | [`c3/h/harmonic_mean.c3`](../../../c3/h/harmonic_mean.c3) |
| C++ | [`cpp/h/harmonic_mean.cpp`](../../../cpp/h/harmonic_mean.cpp) |
| Elisa | [`elisa/h/harmonic_mean.elisa`](../../../elisa/h/harmonic_mean.elisa) |
| Nim | [`nim/h/harmonic_mean.nim`](../../../nim/h/harmonic_mean.nim) |
| Odin | [`odin/h/harmonic_mean.odin`](../../../odin/h/harmonic_mean.odin) |
| Rust | [`rust/h/harmonic_mean.rs`](../../../rust/h/harmonic_mean.rs) |
| V | [`v/h/harmonic_mean.v`](../../../v/h/harmonic_mean.v) |
| Zig | [`zig/h/harmonic_mean.zig`](../../../zig/h/harmonic_mean.zig) |

All ports use portable scalar operations and the shared `i64_array_float64` ABI.
