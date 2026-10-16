# Recursive matrix exponentiation

This benchmark follows the pinned JavaScript `MatrixExponentiationRecursive` algorithm: exponent zero returns the identity; odd powers recursively compute `A^(m-1)` and multiply by `A`; even powers recursively compute `A^(m/2)` and square it.

## Contract

Input is `[exponent, a00, a01, a10, a11]` in the `i64_array_bytes_output` ABI. The exponent is in `[0,30]` and each matrix entry is in `[-1,1]`. The fixed 2×2 domain keeps all results within signed 64-bit range. Output is the four row-major cells encoded as little-endian signed i64 values. Success returns `4`; malformed or out-of-domain input returns `-2`; insufficient output capacity returns `-3`.

The recursive branch structure is retained across ports. The benchmark uses the JavaScript source’s right multiplication order for odd exponents.

Pinned source: [TheAlgorithms/JavaScript `MatrixExponentiationRecursive.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MatrixExponentiationRecursive.js).

[`workload.json`](workload.json) covers identity, odd/even powers, negative entries, the maximum exponent, and invalid input/capacity cases. The runtime oracle is [`benchmarks/matrix_exponentiation_recursive_oracle.py`](../../matrix_exponentiation_recursive_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/matrix_exponentiation_recursive.c`](../../../c/m/matrix_exponentiation_recursive.c) |
| C3 | [`c3/m/matrix_exponentiation_recursive.c3`](../../../c3/m/matrix_exponentiation_recursive.c3) |
| C++ | [`cpp/m/matrix_exponentiation_recursive.cpp`](../../../cpp/m/matrix_exponentiation_recursive.cpp) |
| Elisa | [`elisa/m/matrix_exponentiation_recursive.elisa`](../../../elisa/m/matrix_exponentiation_recursive.elisa) |
| Nim | [`nim/m/matrix_exponentiation_recursive.nim`](../../../nim/m/matrix_exponentiation_recursive.nim) |
| Odin | [`odin/m/matrix_exponentiation_recursive.odin`](../../../odin/m/matrix_exponentiation_recursive.odin) |
| Rust | [`rust/m/matrix_exponentiation_recursive.rs`](../../../rust/m/matrix_exponentiation_recursive.rs) |
| V | [`v/m/matrix_exponentiation_recursive.v`](../../../v/m/matrix_exponentiation_recursive.v) |
| Zig | [`zig/m/matrix_exponentiation_recursive.zig`](../../../zig/m/matrix_exponentiation_recursive.zig) |
