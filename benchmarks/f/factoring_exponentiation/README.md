# Binary exponentiation by factoring

This profile computes `a*x^y mod 2^d` for an odd base and `3<=d<=32`. It uses a 2-adic logarithm to represent each odd unit as a product of factors `2^k+1`, multiplies the resulting logarithm by the exponent, then reconstructs the power. This is materially different from the repository's general repeated-squaring modular-exponentiation packages; the independent oracle uses repeated squaring only as a correctness reference.

## Contract

The exported `i64_array_scalar` function accepts `[a,x,y,d]`. The remainder `a` and odd base `x` must lie in `[0,2^d)` and `[1,2^d)` respectively; the exponent is in `0..2^32-1`, and `d` is in `3..32`. The result is `a*x^y mod 2^d`. Malformed input, including an even base or a trailing word, returns `-1`. Valid and parseable lengths are 4 and 5 i64 values.

The primary performs the sign normalization for bases congruent to 3 modulo 4, extracts the 2-adic logarithm in one bit pass, scales it by `y`, and reconstructs the result in a second bit pass. It takes O(d) time and O(1) auxiliary space. The independent oracle computes the same mathematical result by ordinary modular repeated squaring in O(log y) time. The fixed table stores the published 32-bit 2-adic logarithm constants; no source implementation is copied.

## Provenance and rights

The algorithm follows the high-level method in CP-Algorithms' [Binary Exponentiation by Factoring article](https://cp-algorithms.com/algebra/factoring-exp.html). The source is licensed CC BY-SA 4.0. This clean-room profile uses the algorithm description and its mathematical constants, with independently written ports, contract, oracle, and fixtures. See [`RIGHTS.md`](RIGHTS.md) and [`workload.json`](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [`factoring_exponentiation.c`](../../../c/f/factoring_exponentiation.c) |
| C3 | [`factoring_exponentiation.c3`](../../../c3/f/factoring_exponentiation.c3) |
| C++ | [`factoring_exponentiation.cpp`](../../../cpp/f/factoring_exponentiation.cpp) |
| Elisa | [`factoring_exponentiation.elisa`](../../../elisa/f/factoring_exponentiation.elisa) |
| Mojo | [`factoring_exponentiation.mojo`](../../../mojo/f/factoring_exponentiation.mojo) |
| Nim | [`factoring_exponentiation.nim`](../../../nim/f/factoring_exponentiation.nim) |
| Odin | [`factoring_exponentiation.odin`](../../../odin/f/factoring_exponentiation.odin) |
| Rust | [`factoring_exponentiation.rs`](../../../rust/f/factoring_exponentiation.rs) |
| V | [`factoring_exponentiation.v`](../../../v/f/factoring_exponentiation.v) |
| Zig | [`factoring_exponentiation.zig`](../../../zig/f/factoring_exponentiation.zig) |

The shared scalar suite registers the workload and checks it against both the factoring oracle and the independent repeated-squaring oracle.
