# Long division

This benchmark ports the pinned Java digit-by-digit long division routine. It converts the magnitudes to decimal digits, brings down one digit at a time, and obtains each quotient digit through repeated subtraction. The result truncates toward zero; the source returns zero for a zero divisor.

## Contract

Input is `[dividend, divisor]`, with dividend in `[-1000000,1000000]` and divisor in `[-10000,10000]`. These bounds avoid the Java `int` minimum-value overflow and keep all quotients within range. A zero divisor returns zero. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../long_division_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/LongDivision.java).

| Language | Port |
|---|---|
| C | [`c/l/long_division.c`](../../../c/l/long_division.c) |
| C3 | [`c3/l/long_division.c3`](../../../c3/l/long_division.c3) |
| C++ | [`cpp/l/long_division.cpp`](../../../cpp/l/long_division.cpp) |
| Elisa | [`elisa/l/long_division.elisa`](../../../elisa/l/long_division.elisa) |
| Nim | [`nim/l/long_division.nim`](../../../nim/l/long_division.nim) |
| Odin | [`odin/l/long_division.odin`](../../../odin/l/long_division.odin) |
| Rust | [`rust/l/long_division.rs`](../../../rust/l/long_division.rs) |
| V | [`v/l/long_division.v`](../../../v/l/long_division.v) |
| Zig | [`zig/l/long_division.zig`](../../../zig/l/long_division.zig) |
