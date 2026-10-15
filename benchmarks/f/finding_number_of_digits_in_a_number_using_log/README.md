# Finding the number of digits using a logarithm

Preserve the pinned source's logarithmic calculation on a bounded binary64 input: `floor(log10(abs(x)) + 1)`, with a separate zero case.

## Contract

- Uses the unary binary64 ABI: `double finding_number_of_digits_in_a_number_using_log(double value)`.
- Finite inputs in `[-1,000,000, 1,000,000]` are accepted. Non-finite and out-of-range inputs return `-1e300`.
- Return `0.0` when the input equals zero. Otherwise take the absolute value, compute `log10`, add `1.0`, and apply `floor`, preserving the pinned source's operation order and floating-point semantics.
- This formula is defined for nonzero fractional values too: for example, `0.5` returns `0.0`, while `0.05` returns `-1.0`. Negative inputs use their magnitude.
- The output is an integer-valued binary64 result; it is not the repeated-division integer-digit algorithm. At values extremely close to powers of ten, exact `log10` rounding can affect the floor, as in the source.
- The benchmark adds the finite range and invalid sentinel; the pinned source itself has no such input bound.

This is the second method in the pinned [C++ `finding_number_of_digits_in_a_number.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/finding_number_of_digits_in_a_number.cpp). Its `double` routine returns `0` for zero, replaces negative inputs with their magnitude, then returns `floor(log10(n) + 1)`. The separate C-Plus-Plus-1 repository contains only the unsigned repeated-division routine, so this logarithmic method is represented by the primary C++ source candidate.

The integer division-loop method remains separately benchmarked as [`finding_number_of_digits_in_a_number`](../finding_number_of_digits_in_a_number/README.md).

The pinned implementation is [`finding_number_of_digits_in_a_number_using_log`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/finding_number_of_digits_in_a_number.cpp). The C-Plus-Plus-1 repository contains the division-loop method but not this logarithmic variant.

[`workload.json`](workload.json) covers zero, positive and negative inputs, fractions below one, values just below/at/above powers of ten, and both finite bounds. The runner uses relative and absolute tolerances of `1e-12` for binary64 results.

All nine ports use the unary `scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm finding_number_of_digits_in_a_number_using_log --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/finding_number_of_digits_in_a_number_using_log/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/finding_number_of_digits_in_a_number_using_log.c`](../../../c/f/finding_number_of_digits_in_a_number_using_log.c) |
| C3 | [`c3/f/finding_number_of_digits_in_a_number_using_log.c3`](../../../c3/f/finding_number_of_digits_in_a_number_using_log.c3) |
| C++ | [`cpp/f/finding_number_of_digits_in_a_number_using_log.cpp`](../../../cpp/f/finding_number_of_digits_in_a_number_using_log.cpp) |
| Elisa | [`elisa/f/finding_number_of_digits_in_a_number_using_log.elisa`](../../../elisa/f/finding_number_of_digits_in_a_number_using_log.elisa) |
| Nim | [`nim/f/finding_number_of_digits_in_a_number_using_log.nim`](../../../nim/f/finding_number_of_digits_in_a_number_using_log.nim) |
| Odin | [`odin/f/finding_number_of_digits_in_a_number_using_log.odin`](../../../odin/f/finding_number_of_digits_in_a_number_using_log.odin) |
| Rust | [`rust/f/finding_number_of_digits_in_a_number_using_log.rs`](../../../rust/f/finding_number_of_digits_in_a_number_using_log.rs) |
| V | [`v/f/finding_number_of_digits_in_a_number_using_log.v`](../../../v/f/finding_number_of_digits_in_a_number_using_log.v) |
| Zig | [`zig/f/finding_number_of_digits_in_a_number_using_log.zig`](../../../zig/f/finding_number_of_digits_in_a_number_using_log.zig) |
