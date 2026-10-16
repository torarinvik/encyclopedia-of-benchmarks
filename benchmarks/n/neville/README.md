# Neville interpolation

Evaluate the unique polynomial through a bounded set of points at a target coordinate using Neville’s in-place recurrence.

## Contract

- The `i64_array_float64` input is `[count, target, x0, y0, ...]`; count is 1 through 16 and all coordinates/values are integers in `[-1,000,000, 1,000,000]`.
- The input length must be exactly `2*count + 2`, and all x-coordinates must be distinct. Invalid input returns `-1e300`.
- The result is the interpolated binary64 value using the recurrence and update order in the pinned Java method. Result comparisons use absolute and relative tolerance `1e-12`.

[`workload.json`](workload.json) covers constant, linear, and quadratic interpolation, node evaluation, one-point input, duplicate coordinates, malformed lengths, and bounds.

The pinned implementation is [Java `Neville`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Neville.java).

## Implementations

- C: [`c/n/neville.c`](../../../c/n/neville.c)
- C3: [`c3/n/neville.c3`](../../../c3/n/neville.c3)
- C++: [`cpp/n/neville.cpp`](../../../cpp/n/neville.cpp)
- Elisa: [`elisa/n/neville.elisa`](../../../elisa/n/neville.elisa)
- Nim: [`nim/n/neville.nim`](../../../nim/n/neville.nim)
- Odin: [`odin/n/neville.odin`](../../../odin/n/neville.odin)
- Rust: [`rust/n/neville.rs`](../../../rust/n/neville.rs)
- V: [`v/n/neville.v`](../../../v/n/neville.v)
- Zig: [`zig/n/neville.zig`](../../../zig/n/neville.zig)
