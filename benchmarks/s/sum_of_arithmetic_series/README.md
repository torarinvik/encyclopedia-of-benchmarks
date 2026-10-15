# Sum of arithmetic series

Compute the sum of the first `n` terms of an arithmetic series with first term `a` and common difference `d`.

## Contract

- The packed signed 64-bit input is exactly `[a, d, n]`.
- Accept `a` and `d` in `[-1000, 1000]` and term count `n` in `[1, 1000]`.
- Return the binary64 value of `n * (2*a + (n-1)*d) / 2`. The largest absolute result in this domain is 500,500,000, so the formula's integer intermediates and result are exact in signed 64-bit arithmetic and binary64.
- Return `-1e300` for a malformed input or values outside the benchmark domain.
- This is the finite first-n-terms sum. It differs from the `arithmetic_progression` benchmark, which sums an inclusive interval using a step. The pinned Python source raises for `n <= 0`; Java rejects negative `n` but returns zero for `n == 0`; Julia evaluates its formula for zero. The benchmark uses positive `n`, where all three sources agree.
- The computation takes `O(1)` time and `O(1)` auxiliary space.

## Sources

- [Java `SumOfArithmeticSeries.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumOfArithmeticSeries.java) returns `numOfTerms / 2.0 * (2 * firstTerm + (numOfTerms - 1) * commonDiff)`.
- [Julia `sum_of_arithmetic_series.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/sum_of_arithmetic_series.jl) uses the same formula and argument order.
- [Python `sum_of_arithmetic_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sum_of_arithmetic_series.py) returns the same result using integer arithmetic and raises for nonpositive term counts.

## Workload and build

[`workload.json`](workload.json) covers positive, zero and negative common differences, one term, signed results, the maximum term count, and invalid packed inputs. All nine ports use the `i64_array_float64` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm sum_of_arithmetic_series --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/sum_of_arithmetic_series/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_arithmetic_series.c`](../../../c/s/sum_of_arithmetic_series.c) |
| C3 | [`c3/s/sum_of_arithmetic_series.c3`](../../../c3/s/sum_of_arithmetic_series.c3) |
| C++ | [`cpp/s/sum_of_arithmetic_series.cpp`](../../../cpp/s/sum_of_arithmetic_series.cpp) |
| Elisa | [`elisa/s/sum_of_arithmetic_series.elisa`](../../../elisa/s/sum_of_arithmetic_series.elisa) |
| Nim | [`nim/s/sum_of_arithmetic_series.nim`](../../../nim/s/sum_of_arithmetic_series.nim) |
| Odin | [`odin/s/sum_of_arithmetic_series.odin`](../../../odin/s/sum_of_arithmetic_series.odin) |
| Rust | [`rust/s/sum_of_arithmetic_series.rs`](../../../rust/s/sum_of_arithmetic_series.rs) |
| V | [`v/s/sum_of_arithmetic_series.v`](../../../v/s/sum_of_arithmetic_series.v) |
| Zig | [`zig/s/sum_of_arithmetic_series.zig`](../../../zig/s/sum_of_arithmetic_series.zig) |
