# Decimal to uppercase hexadecimal

This package ports the pinned [TheAlgorithms/JavaScript `decimalToHex`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/DecimalToHex.js). It repeatedly takes base-16 remainders, prepends each digit, and spells values 10 through 15 as uppercase `A` through `F`. The JavaScript source returns a number for inputs 0..9 and a string for larger inputs; this byte-output ABI uses the source's visible digit text for both so all ports share one representation.

The `i64_scalar_bytes_output` ABI accepts JavaScript safe integers `0..9007199254740991`. Negative and out-of-range values return `-1`; insufficient output capacity returns `-2`; otherwise the function writes most-significant-first uppercase hexadecimal ASCII and returns its byte length. This preserves the uppercase output behavior and is distinct from the lowercase `decimal_to_hexadecimal` benchmark.

[`workload.json`](workload.json) covers digit boundaries, uppercase letters, large safe integers, and invalid/capacity cases.

The shared scalar-bytes runner derives uppercase hexadecimal output with the JavaScript safe-integer bounds and validates capacity-failure records.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/decimal_to_hex.c`](../../../c/d/decimal_to_hex.c) |
| C3 | [`c3/d/decimal_to_hex.c3`](../../../c3/d/decimal_to_hex.c3) |
| C++ | [`cpp/d/decimal_to_hex.cpp`](../../../cpp/d/decimal_to_hex.cpp) |
| Elisa | [`elisa/d/decimal_to_hex.elisa`](../../../elisa/d/decimal_to_hex.elisa) |
| Nim | [`nim/d/decimal_to_hex.nim`](../../../nim/d/decimal_to_hex.nim) |
| Odin | [`odin/d/decimal_to_hex.odin`](../../../odin/d/decimal_to_hex.odin) |
| Rust | [`rust/d/decimal_to_hex.rs`](../../../rust/d/decimal_to_hex.rs) |
| V | [`v/d/decimal_to_hex.v`](../../../v/d/decimal_to_hex.v) |
| Zig | [`zig/d/decimal_to_hex.zig`](../../../zig/d/decimal_to_hex.zig) |
