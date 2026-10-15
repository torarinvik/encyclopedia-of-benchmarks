# Finding the number of digits in an unsigned integer

Count decimal digits by repeatedly dividing the value by ten. This package follows the primary `uint64_t` routine in the pinned C++ source.

## Contract

- Input is a signed 64-bit scalar ABI value in `[0, INT64_MAX]`, a bounded subset of the source's `uint64_t` domain.
- Return the number of base-10 digits. The source returns `0` for input zero.
- Negative ABI inputs return `-1` as the shared invalid-input sentinel.
- Time is `O(number of decimal digits)`; auxiliary space is `O(1)`.

This is distinct from the existing `number_of_digits` contract, which treats zero as having one digit, and from the logarithmic method in the same source file.

The pinned implementation is [`finding_number_of_digits_in_a_number`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/finding_number_of_digits_in_a_number.cpp) in TheAlgorithms/C-Plus-Plus; the additional C++ repository contains the same routine.

[`workload.json`](workload.json) covers zero, digit-boundary transitions, and the maximum signed 64-bit value.

All nine ports use the unary `scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm finding_number_of_digits_in_a_number --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/f/finding_number_of_digits_in_a_number/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/finding_number_of_digits_in_a_number.c`](../../../c/f/finding_number_of_digits_in_a_number.c) |
| C3 | [`c3/f/finding_number_of_digits_in_a_number.c3`](../../../c3/f/finding_number_of_digits_in_a_number.c3) |
| C++ | [`cpp/f/finding_number_of_digits_in_a_number.cpp`](../../../cpp/f/finding_number_of_digits_in_a_number.cpp) |
| Elisa | [`elisa/f/finding_number_of_digits_in_a_number.elisa`](../../../elisa/f/finding_number_of_digits_in_a_number.elisa) |
| Nim | [`nim/f/finding_number_of_digits_in_a_number.nim`](../../../nim/f/finding_number_of_digits_in_a_number.nim) |
| Odin | [`odin/f/finding_number_of_digits_in_a_number.odin`](../../../odin/f/finding_number_of_digits_in_a_number.odin) |
| Rust | [`rust/f/finding_number_of_digits_in_a_number.rs`](../../../rust/f/finding_number_of_digits_in_a_number.rs) |
| V | [`v/f/finding_number_of_digits_in_a_number.v`](../../../v/f/finding_number_of_digits_in_a_number.v) |
| Zig | [`zig/f/finding_number_of_digits_in_a_number.zig`](../../../zig/f/finding_number_of_digits_in_a_number.zig) |
