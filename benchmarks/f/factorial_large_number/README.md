# Factorial of Large Numbers

This package ports the pinned C algorithm that stores a nonnegative integer as little-endian decimal digits, then multiplies those digits by every factor from 2 through `n`.

## Contract

- Input is a signed integer `n` in `[0, 100]`.
- The output is the decimal representation of `n!` as most-significant-first ASCII bytes, without a trailing NUL byte. For `n=0` or `n=1`, the result is `1`.
- Invalid inputs return `-1`; insufficient output capacity returns `-2`.

The bound keeps the result within 160 decimal digits and the output buffer's 256-byte limit. [`workload.json`](workload.json) includes small values, representative larger factorials, the maximum input, and invalid boundaries. The runner oracle computes the exact factorial and compares its decimal bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/factorial_large_number.c`](../../../c/f/factorial_large_number.c) |
| C3 | [`c3/f/factorial_large_number.c3`](../../../c3/f/factorial_large_number.c3) |
| C++ | [`cpp/f/factorial_large_number.cpp`](../../../cpp/f/factorial_large_number.cpp) |
| Elisa | [`elisa/f/factorial_large_number.elisa`](../../../elisa/f/factorial_large_number.elisa) |
| Nim | [`nim/f/factorial_large_number.nim`](../../../nim/f/factorial_large_number.nim) |
| Odin | [`odin/f/factorial_large_number.odin`](../../../odin/f/factorial_large_number.odin) |
| Rust | [`rust/f/factorial_large_number.rs`](../../../rust/f/factorial_large_number.rs) |
| V | [`v/f/factorial_large_number.v`](../../../v/f/factorial_large_number.v) |
| Zig | [`zig/f/factorial_large_number.zig`](../../../zig/f/factorial_large_number.zig) |

## Upstream source

- [TheAlgorithms/C `factorial_large_number.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/factorial_large_number.c)
