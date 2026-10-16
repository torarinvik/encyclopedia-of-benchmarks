# Modular arithmetic operations

This benchmark captures the validated `ModRing` addition, subtraction, and multiplication methods in the pinned JavaScript source. The source's `divide` method is excluded: it calls the extended-Euclidean routine on both operands and returns one Bézout coefficient, rather than multiplying a numerator by a modular inverse.

## Contract

Input is `[operation, modulus, a, b]` in the `i64_array_scalar` ABI. Operation `0` adds, `1` subtracts, and `2` multiplies. The modulus is in `[1,1,000,000]`, and both operands are canonical residues in `[0,modulus)`. Output is the least nonnegative result of the corresponding source expression. Invalid input returns `-1`.

The operand bounds keep multiplication below 10^12, so every source intermediate is exact in JavaScript's binary64 number representation. The `modulus=1` case is valid and only permits zero operands.

Pinned source: [TheAlgorithms/JavaScript `ModularArithmetic.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/ModularArithmetic.js). [`workload.json`](workload.json) covers all three operations, residues, modulus one, and invalid inputs.

| Language | Port |
|---|---|
| C | [`c/m/modular_arithmetic.c`](../../../c/m/modular_arithmetic.c) |
| C3 | [`c3/m/modular_arithmetic.c3`](../../../c3/m/modular_arithmetic.c3) |
| C++ | [`cpp/m/modular_arithmetic.cpp`](../../../cpp/m/modular_arithmetic.cpp) |
| Elisa | [`elisa/m/modular_arithmetic.elisa`](../../../elisa/m/modular_arithmetic.elisa) |
| Nim | [`nim/m/modular_arithmetic.nim`](../../../nim/m/modular_arithmetic.nim) |
| Odin | [`odin/m/modular_arithmetic.odin`](../../../odin/m/modular_arithmetic.odin) |
| Rust | [`rust/m/modular_arithmetic.rs`](../../../rust/m/modular_arithmetic.rs) |
| V | [`v/m/modular_arithmetic.v`](../../../v/m/modular_arithmetic.v) |
| Zig | [`zig/m/modular_arithmetic.zig`](../../../zig/m/modular_arithmetic.zig) |
