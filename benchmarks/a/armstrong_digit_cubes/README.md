# Armstrong digit-cubes predicate

This package preserves the fixed-cube predicate in the pinned [TheAlgorithms/C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/is_armstrong.c): return `1` when the input equals the sum of the cubes of its signed decimal digits, and `0` otherwise. The C program reads an `int`; this benchmark exposes the predicate through a scalar ABI and bounds inputs to signed 32-bit values.

Negative inputs follow C's signed-digit behavior. For example, `-153` matches because the digit cubes sum to `-153`. Zero also matches because both the digit loop and sum are zero. Values outside `[-2,147,483,648, 2,147,483,647]` return `-1` in the benchmark ABI.

This is distinct from the existing [`armstrong`](../armstrong/README.md) benchmark, which raises digits to the number of digits. The similarly named MATLAB-Octave `is_armstrong` file is a decimal-palindrome predicate and has separate semantics.

Runtime is O(d) for d decimal digits, with O(1) auxiliary space.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/armstrong_digit_cubes.c`](../../../c/a/armstrong_digit_cubes.c) |
| C3 | [`c3/a/armstrong_digit_cubes.c3`](../../../c3/a/armstrong_digit_cubes.c3) |
| C++ | [`cpp/a/armstrong_digit_cubes.cpp`](../../../cpp/a/armstrong_digit_cubes.cpp) |
| Elisa | [`elisa/a/armstrong_digit_cubes.elisa`](../../../elisa/a/armstrong_digit_cubes.elisa) |
| Nim | [`nim/a/armstrong_digit_cubes.nim`](../../../nim/a/armstrong_digit_cubes.nim) |
| Odin | [`odin/a/armstrong_digit_cubes.odin`](../../../odin/a/armstrong_digit_cubes.odin) |
| Rust | [`rust/a/armstrong_digit_cubes.rs`](../../../rust/a/armstrong_digit_cubes.rs) |
| V | [`v/a/armstrong_digit_cubes.v`](../../../v/a/armstrong_digit_cubes.v) |
| Zig | [`zig/a/armstrong_digit_cubes.zig`](../../../zig/a/armstrong_digit_cubes.zig) |
