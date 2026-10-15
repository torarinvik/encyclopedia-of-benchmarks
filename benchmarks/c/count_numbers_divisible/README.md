# Count numbers divisible in a range

Counts positive multiples of a divisor in an inclusive integer interval. The formula subtracts the number of multiples below the interval start from the number at or below its end.

## Contract

- Uses the three-input binary64 ABI: `double count_numbers_divisible(double first, double last, double divisor)`.
- Each input is an integer in `1..=2,147,483,647`, with `first <= last`.
- Return `floor(last / divisor) - floor((first - 1) / divisor)` as an exactly represented binary64 integer.
- The interval is inclusive. `first == last` is valid and returns one exactly when that value is divisible by the divisor.
- Inputs are bounded to signed 32-bit positive integers, so all inputs and the result are exactly representable in binary64.

## Source semantics

The benchmark follows the pinned [TheAlgorithms JavaScript `CountNumbersDivisible.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/CountNumbersDivisible.js). The source counts multiples in `[num1, num2]`; its code throws when `num1 > num2` and accepts equal endpoints, despite a comment saying `num1 < num2`. It returns zero when the divisor exceeds the upper endpoint. For positive integer inputs within the shared bound, the integer formula is equivalent to the source's quotient difference, lower-end divisibility adjustment, and `Math.round`, while avoiding floating-point quotient rounding.

## Workload and build

[`workload.json`](workload.json) covers divisible and nondivisible endpoints, equal endpoints, a divisor larger than the interval, and large bounded values. Build and record with the `float64_triple` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm count_numbers_divisible --language c
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/c/count_numbers_divisible/c/build.json
```

The nine implementations are in `c/c/count_numbers_divisible.c`, `c3/c/count_numbers_divisible.c3`, `cpp/c/count_numbers_divisible.cpp`, `elisa/c/count_numbers_divisible.elisa`, `nim/c/count_numbers_divisible.nim`, `odin/c/count_numbers_divisible.odin`, `rust/c/count_numbers_divisible.rs`, `v/c/count_numbers_divisible.v`, and `zig/c/count_numbers_divisible.zig`.
