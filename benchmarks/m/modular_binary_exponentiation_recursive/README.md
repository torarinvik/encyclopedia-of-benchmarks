# Recursive modular binary exponentiation

The pinned JavaScript routine recursively computes a modular power by exponentiation by squaring: exponent zero returns `1`, odd exponents recurse on `n-1` and multiply by the base, and even exponents square the result for `n/2`.

## Contract

Input is `[base, exponent, modulus]` as signed 64-bit integers, with base 0..1,000,000, exponent 0..60, and modulus 2..1,000,000. Output is the source recurrence's result; in particular, exponent zero returns exactly `1`. Invalid input returns `-1`. Bounds keep intermediate products within exact integer range for the pinned JavaScript Number implementation and signed 64-bit ports.

See [`workload.json`](workload.json) and the runtime [oracle](../../modular_binary_exponentiation_recursive_oracle.py).

Pinned source: [TheAlgorithms/JavaScript `ModularBinaryExponentiationRecursive.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ModularBinaryExponentiationRecursive.js).

| Language | Port |
|---|---|
| C | [`c/m/modular_binary_exponentiation_recursive.c`](../../../c/m/modular_binary_exponentiation_recursive.c) |
| C3 | [`c3/m/modular_binary_exponentiation_recursive.c3`](../../../c3/m/modular_binary_exponentiation_recursive.c3) |
| C++ | [`cpp/m/modular_binary_exponentiation_recursive.cpp`](../../../cpp/m/modular_binary_exponentiation_recursive.cpp) |
| Elisa | [`elisa/m/modular_binary_exponentiation_recursive.elisa`](../../../elisa/m/modular_binary_exponentiation_recursive.elisa) |
| Nim | [`nim/m/modular_binary_exponentiation_recursive.nim`](../../../nim/m/modular_binary_exponentiation_recursive.nim) |
| Odin | [`odin/m/modular_binary_exponentiation_recursive.odin`](../../../odin/m/modular_binary_exponentiation_recursive.odin) |
| Rust | [`rust/m/modular_binary_exponentiation_recursive.rs`](../../../rust/m/modular_binary_exponentiation_recursive.rs) |
| V | [`v/m/modular_binary_exponentiation_recursive.v`](../../../v/m/modular_binary_exponentiation_recursive.v) |
| Zig | [`zig/m/modular_binary_exponentiation_recursive.zig`](../../../zig/m/modular_binary_exponentiation_recursive.zig) |
