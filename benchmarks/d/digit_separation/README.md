# Digit separation

The pinned C++ and Java sources provide two operations: separate a signed integer's decimal digits in reverse order or forward order. Both treat digits independently of the sign and return `[0]` for zero.

## Contract

- The packed input is two signed 64-bit integers: `[number, direction]`.
- `direction = 0` returns digits from least significant to most significant. `direction = 1` returns digits from most significant to least significant.
- Accept every signed 64-bit `number`. Encode each decimal digit as one output byte with numeric value 0 through 9. Return the number of digits.
- Return `-1` if the input length is not two or `direction` is not 0 or 1.
- Return `-2` if the output buffer is too small; do not write output bytes in that case.

The source implementations use the same remainder-and-division method for reverse order; forward order reverses that digit list. Taking the absolute value of each remainder also handles the signed 64-bit minimum without taking its absolute value.

## Workload

[`workload.json`](workload.json) covers zero, both orders, negative inputs, signed 64-bit endpoints, and invalid directions and input lengths. The expected-output oracle in `benchmarks/run_i64_array_bytes_output.py` compares the digit bytes exactly.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `digit_separation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/digit_separation.cpp)
- [TheAlgorithms/Java `DigitSeparation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/DigitSeparation.java)
