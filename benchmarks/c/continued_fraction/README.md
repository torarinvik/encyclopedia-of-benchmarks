# Continued fraction

Convert an exact rational number to its finite simple continued-fraction
coefficients, preserving the pinned Python implementation's floor-based
behavior for negative values.

## Contract

Input is two signed 64-bit values `[numerator, denominator]`. Both magnitudes
must be at most 1,000,000 and the denominator must be nonzero. The values are
normalized as a rational number, matching `Fraction`; a negative denominator
moves its sign to the numerator. The algorithm repeatedly appends
`floor(numerator / denominator)`, subtracts that integer part, then swaps the
denominator and remainder. In particular, `-9/4` becomes `[-3, 1, 3]`.

The variable-length coefficient array is encoded as consecutive little-endian
signed 64-bit integers. Success returns the output byte count; invalid input
returns `-1`, and insufficient output capacity returns `-2`. The bounded
domain has at most 32 coefficients and a 256-byte maximum output.

## Source and workload

Pinned source: [TheAlgorithms/Python `continued_fraction.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/continued_fraction.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

[`workload.json`](workload.json) covers the pinned examples, exact integers,
reduced and unreduced fractions, negative values and denominators, the input
bounds, malformed inputs, and capacity failures. The source-shaped oracle is
[`continued_fraction_oracle.py`](../../continued_fraction_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/c/continued_fraction.c](../../../c/c/continued_fraction.c) |
| C3 | [c3/c/continued_fraction.c3](../../../c3/c/continued_fraction.c3) |
| C++ | [cpp/c/continued_fraction.cpp](../../../cpp/c/continued_fraction.cpp) |
| Elisa | [elisa/c/continued_fraction.elisa](../../../elisa/c/continued_fraction.elisa) |
| Nim | [nim/c/continued_fraction.nim](../../../nim/c/continued_fraction.nim) |
| Odin | [odin/c/continued_fraction.odin](../../../odin/c/continued_fraction.odin) |
| Rust | [rust/c/continued_fraction.rs](../../../rust/c/continued_fraction.rs) |
| V | [v/c/continued_fraction.v](../../../v/c/continued_fraction.v) |
| Zig | [zig/c/continued_fraction.zig](../../../zig/c/continued_fraction.zig) |

## Verification

Verify all nine implementations with
`python3 benchmarks/verify_i64_array_bytes_output.py --algorithm continued_fraction`.
