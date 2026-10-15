# Bitwise Minimum

This package benchmarks the pinned [TheAlgorithms/Go `Bitwise` implementation](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/min/bitwisemin.go). The source folds a variadic list by selecting between the running minimum and each new value with a sign-bit mask.

The `i64_array_scalar` ABI accepts 1..4096 signed integers, each in `0..2,147,483,647`. The source's `base` parameter is fixed at 31, matching its signed-32-bit convention; the bounded values keep each subtraction in signed-32-bit range so bit 31 is a valid sign indicator. Invalid lengths or values return `-1`, outside the valid result range.

Runtime is O(n) for n input values and auxiliary space is O(1).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bitwisemin.c`](../../../c/b/bitwisemin.c) |
| C3 | [`c3/b/bitwisemin.c3`](../../../c3/b/bitwisemin.c3) |
| C++ | [`cpp/b/bitwisemin.cpp`](../../../cpp/b/bitwisemin.cpp) |
| Elisa | [`elisa/b/bitwisemin.elisa`](../../../elisa/b/bitwisemin.elisa) |
| Nim | [`nim/b/bitwisemin.nim`](../../../nim/b/bitwisemin.nim) |
| Odin | [`odin/b/bitwisemin.odin`](../../../odin/b/bitwisemin.odin) |
| Rust | [`rust/b/bitwisemin.rs`](../../../rust/b/bitwisemin.rs) |
| V | [`v/b/bitwisemin.v`](../../../v/b/bitwisemin.v) |
| Zig | [`zig/b/bitwisemin.zig`](../../../zig/b/bitwisemin.zig) |
