# Problem 016 power digit sum

Compute the sum of the decimal digits of a bounded single-digit base raised to a bounded exponent, using the pinned Project Euler 16 digit-vector algorithm.

## Contract

- Input is exactly two signed 64-bit integers: `[base, exponent]`.
- `base` is in `[0, 9]`; `exponent` is in `[0, 1000]`.
- The source stores decimal digits least-significant first and multiplies the digit vector by the base for each remaining power.
- Preserve the pinned edge behavior: exponent zero returns the base itself, so `[2, 0]` returns `2`, rather than the usual digit sum of one.
- Return a signed 64-bit integer containing the digit sum. The result is at most 8,595 because `9^1000` has 955 decimal digits. Invalid length or values return `-1`.

This package uses the distinct slug `problem016_power_digit_sum`; the existing `problem16` package implements exponent-only `2^n` and remains separate.

## Pinned source

[TheAlgorithms/JavaScript Project-Euler/Problem016.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Project-Euler/Problem016.js), export `powerDigitSum`.

## Workload and oracle

[workload.json](workload.json) covers the source example, exponent-zero behavior, zero and one bases, the exponent bound, and malformed input. The independent oracle is [problem016_power_digit_sum_oracle.py](../../problem016_power_digit_sum_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem016_power_digit_sum.c](../../../c/p/problem016_power_digit_sum.c) |
| C3 | [c3/p/problem016_power_digit_sum.c3](../../../c3/p/problem016_power_digit_sum.c3) |
| C++ | [cpp/p/problem016_power_digit_sum.cpp](../../../cpp/p/problem016_power_digit_sum.cpp) |
| Elisa | [elisa/p/problem016_power_digit_sum.elisa](../../../elisa/p/problem016_power_digit_sum.elisa) |
| Nim | [nim/p/problem016_power_digit_sum.nim](../../../nim/p/problem016_power_digit_sum.nim) |
| Odin | [odin/p/problem016_power_digit_sum.odin](../../../odin/p/problem016_power_digit_sum.odin) |
| Rust | [rust/p/problem016_power_digit_sum.rs](../../../rust/p/problem016_power_digit_sum.rs) |
| V | [v/p/problem016_power_digit_sum.v](../../../v/p/problem016_power_digit_sum.v) |
| Zig | [zig/p/problem016_power_digit_sum.zig](../../../zig/p/problem016_power_digit_sum.zig) |
