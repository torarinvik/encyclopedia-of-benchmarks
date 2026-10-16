# largest_of_very_large_numbers

This package adapts the comparison in the pinned [TheAlgorithms/Python `maths/largest_of_very_large_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/largest_of_very_large_numbers.py). The source compares powers by calculating `exponent * log10(base)` instead of constructing the potentially large powers.

## Contract

- The signed-i64 input is `[base_a, exponent_a, base_b, exponent_b]`. Each value must be in `0..1,000,000,000,000`; other shapes or values return `-2`.
- Each base must be zero or an exact decimal power `10^k` for `k` in `0..12`. Exponents may be paired arbitrarily. A positive base outside this set, or any out-of-range value, returns `-2`.
- The benchmark models the exact mathematical identities `log10(10^k) = k`, not bit-for-bit results from arbitrary platform `libm` implementations. Thus a positive base with positive exponent has exact integer score `k * exponent` when the base is `10^k`.
- The source branch order is preserved: a zero base scores `0`, including `0^0`; otherwise a zero exponent scores `1`; otherwise the exact score is `k * exponent`. This retains the source's zero-base-first behavior.
- Return `1` when the first score is greater, `-1` when the second score is greater, and `0` when scores compare equal. Arbitrary valid pairings and ties are accepted.
- The largest score is `12,000,000,000,000`, which fits signed i64 and is exactly representable in binary64, although the benchmark compares exact integers and does not call `log10`.

The independent oracle is [`benchmarks/largest_of_very_large_numbers_oracle.py`](../../largest_of_very_large_numbers_oracle.py). The workload covers every zero-branch combination, arbitrary pairings, exact score ties, maximum bounds, invalid non-power bases, and invalid shape/range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/largest_of_very_large_numbers.c`](../../../c/l/largest_of_very_large_numbers.c) |
| C3 | [`c3/l/largest_of_very_large_numbers.c3`](../../../c3/l/largest_of_very_large_numbers.c3) |
| C++ | [`cpp/l/largest_of_very_large_numbers.cpp`](../../../cpp/l/largest_of_very_large_numbers.cpp) |
| Elisa | [`elisa/l/largest_of_very_large_numbers.elisa`](../../../elisa/l/largest_of_very_large_numbers.elisa) |
| Nim | [`nim/l/largest_of_very_large_numbers.nim`](../../../nim/l/largest_of_very_large_numbers.nim) |
| Odin | [`odin/l/largest_of_very_large_numbers.odin`](../../../odin/l/largest_of_very_large_numbers.odin) |
| Rust | [`rust/l/largest_of_very_large_numbers.rs`](../../../rust/l/largest_of_very_large_numbers.rs) |
| V | [`v/l/largest_of_very_large_numbers.v`](../../../v/l/largest_of_very_large_numbers.v) |
| Zig | [`zig/l/largest_of_very_large_numbers.zig`](../../../zig/l/largest_of_very_large_numbers.zig) |
