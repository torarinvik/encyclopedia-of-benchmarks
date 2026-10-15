# Arithmetic Mean Using AND and XOR

This package benchmarks the overflow-safe `MeanUsingAndXor` method in the pinned [TheAlgorithms/Go source](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/arithmeticmean.go). It computes the floor of the arithmetic mean with `((a ^ b) >> 1) + (a & b)`.

The `i64_array_scalar` ABI accepts exactly two signed integers in this order: `[a, b]`. Each value is bounded to `0..9,000,000,000,000,000,000`, a nonnegative subset of the source's `int` domain on 64-bit Go. The nonnegative domain makes right shift semantics consistent across ports and the large boundary cases exercise the overflow-safe identity. Invalid lengths or values return `-1`, outside the valid result range.

The Go file also contains `MeanUsingRightShift`; this benchmark covers `MeanUsingAndXor`. Runtime and auxiliary space are O(1).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arithmeticmean.c`](../../../c/a/arithmeticmean.c) |
| C3 | [`c3/a/arithmeticmean.c3`](../../../c3/a/arithmeticmean.c3) |
| C++ | [`cpp/a/arithmeticmean.cpp`](../../../cpp/a/arithmeticmean.cpp) |
| Elisa | [`elisa/a/arithmeticmean.elisa`](../../../elisa/a/arithmeticmean.elisa) |
| Nim | [`nim/a/arithmeticmean.nim`](../../../nim/a/arithmeticmean.nim) |
| Odin | [`odin/a/arithmeticmean.odin`](../../../odin/a/arithmeticmean.odin) |
| Rust | [`rust/a/arithmeticmean.rs`](../../../rust/a/arithmeticmean.rs) |
| V | [`v/a/arithmeticmean.v`](../../../v/a/arithmeticmean.v) |
| Zig | [`zig/a/arithmeticmean.zig`](../../../zig/a/arithmeticmean.zig) |
