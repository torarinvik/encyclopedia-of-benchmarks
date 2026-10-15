# Bitwise Maximum

This package benchmarks the pinned [TheAlgorithms/Go `Bitwise` implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/max/bitwisemax.go). It selects the greater input by extracting the sign bit of `a - b` and applying `a - (sign * (a - b))`, without a comparison in the selection formula.

The `i64_array_scalar` ABI accepts exactly two signed integers in this order: `[a, b]`. Both inputs are bounded to `0..2,147,483,647`, and the source's `base` argument is fixed at 31, as in its 32-bit tests. This domain keeps the difference in signed-32-bit range so bit 31 indicates whether `a - b` is negative. Invalid ABI lengths or values return `-1`, outside the nonnegative result range.

The source also has test cases for other base widths; this package models its 32-bit base variant. Runtime and auxiliary space are O(1).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bitwisemax.c`](../../../c/b/bitwisemax.c) |
| C3 | [`c3/b/bitwisemax.c3`](../../../c3/b/bitwisemax.c3) |
| C++ | [`cpp/b/bitwisemax.cpp`](../../../cpp/b/bitwisemax.cpp) |
| Elisa | [`elisa/b/bitwisemax.elisa`](../../../elisa/b/bitwisemax.elisa) |
| Nim | [`nim/b/bitwisemax.nim`](../../../nim/b/bitwisemax.nim) |
| Odin | [`odin/b/bitwisemax.odin`](../../../odin/b/bitwisemax.odin) |
| Rust | [`rust/b/bitwisemax.rs`](../../../rust/b/bitwisemax.rs) |
| V | [`v/b/bitwisemax.v`](../../../v/b/bitwisemax.v) |
| Zig | [`zig/b/bitwisemax.zig`](../../../zig/b/bitwisemax.zig) |
