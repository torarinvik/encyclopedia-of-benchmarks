# largest_of_very_large_numbers

This package adapts the comparison in the pinned [TheAlgorithms/Python `maths/largest_of_very_large_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/largest_of_very_large_numbers.py). The source compares powers by calculating `exponent * log10(base)` instead of constructing the potentially large powers.

## Contract

- The signed-i64 input is `[base_a, exponent_a, base_b, exponent_b]`. Each value must be in `0..1,000,000,000,000`; other shapes or values return `-2`.
- To keep binary64 `log10` comparisons portable, valid pairs satisfy either `exponent_a == exponent_b`, or `base_a == base_b` and both exponents are on the same zero/nonzero branch. Equal zero bases are valid for any exponents because the source helper returns score 0 before examining the exponent. Other cross-base, cross-exponent pairs return `-2`.
- For a nonzero base and exponent, each score is `exponent * log10(base)`. The source returns score `0` whenever the base is zero, including `0^0`; when only the exponent is zero, it returns score `1`. The benchmark preserves these branches.
- Return `1` when the first score is greater, `-1` when the second score is greater, and `0` when scores compare equal. The result records the source script's winner or its “both equal” outcome without formatting text.
- The bounds keep scores finite and safe from integer overflow in the packed input. Floating-point comparisons follow the source's direct `>` and `<` comparisons. Within the accepted domain, unequal-base comparisons share an exponent; adjacent integer bases remain separated by over 160 binary64 ulps under the stated one-ulp `log10` assumption. Equal-base comparisons share the same computed logarithm.

The independent oracle is [`benchmarks/largest_of_very_large_numbers_oracle.py`](../../largest_of_very_large_numbers_oracle.py). The workload covers equal-exponent comparisons (including adjacent bases at the upper bound), equal-base comparisons, zero-base and zero-exponent branches, large bounded values, and invalid relation/shape inputs.

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
