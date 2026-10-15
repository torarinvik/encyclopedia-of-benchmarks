# Keith number

Checks whether a positive decimal integer occurs in the recurrence seeded by its own digits.

## Contract

- Uses the unary scalar ABI: `int64_t keith_number(int64_t number)`.
- Inputs in `[10, 999999]` are accepted. The function returns `1` when the recurrence reaches the input and `0` otherwise. Inputs outside the range return `-1`.
- For an input with `d` decimal digits, the initial terms are its digits from left to right. Each following term is the sum of the preceding `d` terms. The search stops as soon as a generated term is greater than or equal to the input.

## Source semantics

The benchmark follows pinned [TheAlgorithms Java `KeithNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/KeithNumber.java) and [TheAlgorithms Python `keith_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/keith_number.py). Both implement the digit-seeded recurrence and return whether it reaches the input. Java starts the first sum from the digit terms; Python maintains the rolling sum of its digit window. These methods produce the same predicate on the benchmark domain.

The sources differ for one-digit inputs: Java's first generated term equals the digit, while Python explicitly excludes numbers below 10. The contract starts at 10, where the sources agree. It stops at 999,999 so the Java implementation's signed 32-bit recurrence accumulator remains safe: there are at most six terms per sum, each preceding term is less than the tested input, and each sum is below 6,000,000. The catalog's separate C# `keith_number_checker` source describes the same Keith/repfigit predicate and is a candidate for aliasing to this package.

## Workload and build

[`workload.json`](workload.json) includes known Keith numbers, non-Keith examples, and invalid values around the accepted range. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm keith_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/k/keith_number/c/build.json
```

The nine implementations are in `c/k/keith_number.c`, `c3/k/keith_number.c3`, `cpp/k/keith_number.cpp`, `elisa/k/keith_number.elisa`, `nim/k/keith_number.nim`, `odin/k/keith_number.odin`, `rust/k/keith_number.rs`, `v/k/keith_number.v`, and `zig/k/keith_number.zig`.
