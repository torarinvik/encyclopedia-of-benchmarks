# Modular multiplicative inverse

The pinned C# implementation calls extended Euclid, rejects a non-unit gcd, and normalizes the Bézout coefficient for `a` into `[0,n)`.

## Contract

Input is `[a, n]` as signed 64-bit integers. The benchmark restricts `2 <= n <= 1,000,000` and `0 <= a < n`. It returns the unique inverse `x` in `[0,n)` such that `a*x ≡ 1 (mod n)`. Invalid inputs and non-coprime pairs return `-1`; this sentinel represents the source's arithmetic exception for values without an inverse.

The operand bounds keep all Euclidean coefficient arithmetic within signed 64-bit range. See [`workload.json`](workload.json) and the runtime [oracle](../../modular_multiplicative_inverse_oracle.py).

Pinned source: [TheAlgorithms/C-Sharp `ModularMultiplicativeInverse.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/ModularArithmetic/ModularMultiplicativeInverse.cs).

| Language | Port |
|---|---|
| C | [`c/m/modular_multiplicative_inverse.c`](../../../c/m/modular_multiplicative_inverse.c) |
| C3 | [`c3/m/modular_multiplicative_inverse.c3`](../../../c3/m/modular_multiplicative_inverse.c3) |
| C++ | [`cpp/m/modular_multiplicative_inverse.cpp`](../../../cpp/m/modular_multiplicative_inverse.cpp) |
| Elisa | [`elisa/m/modular_multiplicative_inverse.elisa`](../../../elisa/m/modular_multiplicative_inverse.elisa) |
| Nim | [`nim/m/modular_multiplicative_inverse.nim`](../../../nim/m/modular_multiplicative_inverse.nim) |
| Odin | [`odin/m/modular_multiplicative_inverse.odin`](../../../odin/m/modular_multiplicative_inverse.odin) |
| Rust | [`rust/m/modular_multiplicative_inverse.rs`](../../../rust/m/modular_multiplicative_inverse.rs) |
| V | [`v/m/modular_multiplicative_inverse.v`](../../../v/m/modular_multiplicative_inverse.v) |
| Zig | [`zig/m/modular_multiplicative_inverse.zig`](../../../zig/m/modular_multiplicative_inverse.zig) |
