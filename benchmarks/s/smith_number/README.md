# Smith number

Checks whether a composite positive integer has the same decimal digit sum as its prime factors, counted with multiplicity.

## Contract

- Uses the unary scalar ABI: `int64_t smith_number(int64_t value)`.
- Inputs in `[1, 2,147,395,599]` are accepted. Values outside the range return `-1`.
- Return `1` when the input is composite and its decimal digit sum equals the sum of the decimal digit sums of its prime factors, including repeated factors; otherwise return `0`.
- The source's prime-number guard is preserved. The positive-only domain excludes the source's zero false positive: its prime helper returns false for zero, and both digit sums are zero, so the Java method otherwise reports zero as Smith.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `SmithNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SmithNumber.java), including its [prime check](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/PrimeCheck.java) and [digit-sum helper](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SumOfDigits.java). The Java method first rejects prime inputs, then compares the original value's digit sum with the digit sums of each prime factor occurrence. Trial division divides out repeated factors and adds each factor's digit sum each time. The contract caps inputs below `46,340²` at `2,147,395,599`; this prevents the pinned Java `int` loop condition `i * i <= num` from overflowing when `i` reaches 46,341. Larger signed-int values return `-1` in this benchmark.

## Workload and build

[`workload.json`](workload.json) covers prime and non-Smith composites, Smith examples with repeated factors, the highest safe input, the first value above that bound, and invalid values. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm smith_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/smith_number/c/build.json
```

The nine implementations are in `c/s/smith_number.c`, `c3/s/smith_number.c3`, `cpp/s/smith_number.cpp`, `elisa/s/smith_number.elisa`, `nim/s/smith_number.nim`, `odin/s/smith_number.odin`, `rust/s/smith_number.rs`, `v/s/smith_number.v`, and `zig/s/smith_number.zig`.

Verify the nine ports against the independent prime-factor digit-sum oracle with `python3 benchmarks/verify_scalar.py --algorithms smith_number`.
