# Egyptian fraction

Decompose a bounded nonnegative fraction with `0 <= numerator <= denominator` into an ordered sum of unique unit fractions using the Java greedy algorithm.

## Contract

- ABI: signed i64 array to byte output. Input is `[numerator, denominator]`, with `0 <= numerator <= denominator <= 10` and a positive denominator.
- Repeatedly choose `x = ceil(denominator / numerator)`, append the unit fraction `1/x`, then update the numerator to `numerator * x - denominator` and denominator to `denominator * x`. A zero numerator returns an empty list; an equal numerator and denominator returns `1/1`.
- The Java source returns an ordered `List<String>` containing values such as `1/2`. The byte ABI stores the same ordered terms losslessly as little-endian signed i32 denominators: each integer `x` represents the source string `1/x`.
- Invalid shapes or values return `-1`. Insufficient output capacity returns `-2` without writing. The input bound keeps every source-style int update small.

## Source and workload

This package follows [TheAlgorithms/Java `EgyptianFraction.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/EgyptianFraction.java). The bounded workload exhaustively covers every `0 <= numerator <= denominator <= 10` pair. The longest decomposition in that finite domain has three terms, so the output workspace is 12 bytes; the workload also covers malformed inputs and a short buffer. The independent oracle uses exact rational arithmetic.

Build and record Rust with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm egyptian_fraction --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/e/egyptian_fraction/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm egyptian_fraction --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/egyptian_fraction.c`](../../../c/e/egyptian_fraction.c) |
| C3 | [`c3/e/egyptian_fraction.c3`](../../../c3/e/egyptian_fraction.c3) |
| C++ | [`cpp/e/egyptian_fraction.cpp`](../../../cpp/e/egyptian_fraction.cpp) |
| Elisa | [`elisa/e/egyptian_fraction.elisa`](../../../elisa/e/egyptian_fraction.elisa) |
| Nim | [`nim/e/egyptian_fraction.nim`](../../../nim/e/egyptian_fraction.nim) |
| Odin | [`odin/e/egyptian_fraction.odin`](../../../odin/e/egyptian_fraction.odin) |
| Rust | [`rust/e/egyptian_fraction.rs`](../../../rust/e/egyptian_fraction.rs) |
| V | [`v/e/egyptian_fraction.v`](../../../v/e/egyptian_fraction.v) |
| Zig | [`zig/e/egyptian_fraction.zig`](../../../zig/e/egyptian_fraction.zig) |
