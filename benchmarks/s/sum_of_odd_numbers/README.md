# Sum of the first n odd numbers

Returns the sum of the first `n` positive odd integers using the source's square identity.

## Contract

- Uses the unary scalar ABI: `int64_t sum_of_odd_numbers(int64_t n)`.
- Inputs in `[0, 46,340]` are accepted. Values outside that range return `-1`.
- Returns exactly `n * n`; zero returns zero.
- The bound keeps the result within Java's signed int range: `46,340² = 2,147,395,600`, while `46,341²` exceeds `INT32_MAX`.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `SumOfOddNumbers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumOfOddNumbers.java). Its `sumOfFirstNOddNumbers` rejects negative `n` and returns `n * n` directly, rather than iterating over odd terms. The shared ABI uses signed 64-bit values, so the contract bounds inputs to the nonnegative Java int range that also keeps this multiplication exact and free of int32 overflow; invalid values map to `-1`.

## Workload and build

[`workload.json`](workload.json) covers zero, small values, the maximum safe Java int result, and invalid bounds. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm sum_of_odd_numbers --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/sum_of_odd_numbers/c/build.json
```

The nine implementations are in `c/s/sum_of_odd_numbers.c`, `c3/s/sum_of_odd_numbers.c3`, `cpp/s/sum_of_odd_numbers.cpp`, `elisa/s/sum_of_odd_numbers.elisa`, `nim/s/sum_of_odd_numbers.nim`, `odin/s/sum_of_odd_numbers.odin`, `rust/s/sum_of_odd_numbers.rs`, `v/s/sum_of_odd_numbers.v`, and `zig/s/sum_of_odd_numbers.zig`.
