# Kaprekar number

A positive integer is Kaprekar when its square can be split into a nonzero right part and a left part whose sum is the original integer. For example, `45² = 20 | 25`, and `20 + 25 = 45`.

## Contract

- Input is a signed 64-bit integer. Values below `1` return `0`, matching the source's false result for nonpositive integers. Inputs above `2,000,000,000` return `-1`.
- For valid positive inputs, return `1` if any decimal split of `n²` has a nonzero right part and `left + right = n`; otherwise return `0`. The single-digit number `1` is explicitly Kaprekar.
- The input bound keeps `n²` within signed 64-bit range. Implementations examine decimal powers `10, 100, 1,000, ...` as split positions and stop before multiplying the power past the square.

The benchmark follows the pinned [TheAlgorithms Python source `kaprekar_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/kaprekar_number.py). It checks all decimal split widths smaller than the square's digit count and requires the right part to be nonzero. Inputs above the shared safe bound return `-1`.

[`workload.json`](workload.json) covers zero and negative inputs, known Kaprekar values, nonmatches, and both sides of the upper input bound. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm kaprekar_number --language c
python3 benchmarks/run_scalar.py --algorithm kaprekar_number
```

Implementations: `c/k/kaprekar_number.c`, `c3/k/kaprekar_number.c3`, `cpp/k/kaprekar_number.cpp`, `elisa/k/kaprekar_number.elisa`, `nim/k/kaprekar_number.nim`, `odin/k/kaprekar_number.odin`, `rust/k/kaprekar_number.rs`, `v/k/kaprekar_number.v`, and `zig/k/kaprekar_number.zig`.
