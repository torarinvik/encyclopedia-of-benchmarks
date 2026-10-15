# Finding the number of digits using a logarithm

Count decimal digits with the pinned source's `floor(log10(abs(n)) + 1)` method. This is the second, logarithmic routine in the C++ source file.

## Contract

- Input is a signed 64-bit integer in `[-1,000,000, 1,000,000]`. This bounded integer subset is exactly representable as binary64, the source method's input type.
- Return `0` for zero. Otherwise, return `floor(log10(abs(n)) + 1)` as an integer scalar.
- Values outside the input range return `-1` as the shared invalid-input sentinel.
- Time and auxiliary space are `O(1)`.

This source method accepts `double`, handles negative values by taking their absolute value, and returns a `double` count. The benchmark supplies bounded integral inputs through the scalar ABI and encodes its integer-valued result as `int64_t`. The primary division-loop routine in the same source is preserved separately as `finding_number_of_digits_in_a_number`.

The pinned implementation is [`finding_number_of_digits_in_a_number_using_log`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/finding_number_of_digits_in_a_number.cpp). The C-Plus-Plus-1 repository contains the division-loop method but not this logarithmic variant.

[`workload.json`](workload.json) covers zero, positive and negative magnitudes, decimal boundaries, and invalid values.

All nine ports use the unary `scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm finding_number_of_digits_in_a_number_using_log --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/f/finding_number_of_digits_in_a_number_using_log/rust/build.json
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
