# Multiplicative order modulo an integer

For a supplied residue that is coprime to its modulus, return the least positive exponent `k` for which `a^k ≡ 1 (mod m)`. This scalar profile uses the order-reduction method described by the Primitive Root article's relation between primitive roots and element orders.

## Contract

- Input is exactly `[a,m]`, with `2 <= m <= 1000` and `0 <= a < m`.
- If `gcd(a,m) != 1`, return `0` because the residue is not a unit and has no multiplicative order in the unit group.
- Otherwise return the exact least positive order. Invalid framing or out-of-profile values return `-1`.
- The primary factors `φ(m)`, then removes prime factors from the candidate order whenever modular exponentiation proves the order divides the reduced candidate. The independent reference multiplies successive powers directly until it returns to one.
- Runtime is bounded by trial factorization through `sqrt(m)` and logarithmic modular exponentiations; the independent reference takes at most `m` modular multiplications.

## Provenance and rights

The order-reduction criterion appears in the [CP-Algorithms Primitive Root article](https://cp-algorithms.com/algebra/primitive-root.html), licensed CC BY-SA 4.0. The package applies that criterion to one supplied unit and returns its order. The contract, fixtures, references, and all ten ports are independently authored; no upstream code, prose, or examples were copied. See [RIGHTS.md](RIGHTS.md) and [workload.json](workload.json).

## Language ports

| Language | Source |
|---|---|
| C | [multiplicative_order.c](../../../c/m/multiplicative_order.c) |
| C3 | [multiplicative_order.c3](../../../c3/m/multiplicative_order.c3) |
| C++ | [multiplicative_order.cpp](../../../cpp/m/multiplicative_order.cpp) |
| Elisa | [multiplicative_order.elisa](../../../elisa/m/multiplicative_order.elisa) |
| Mojo | [multiplicative_order.mojo](../../../mojo/m/multiplicative_order.mojo) |
| Nim | [multiplicative_order.nim](../../../nim/m/multiplicative_order.nim) |
| Odin | [multiplicative_order.odin](../../../odin/m/multiplicative_order.odin) |
| Rust | [multiplicative_order.rs](../../../rust/m/multiplicative_order.rs) |
| V | [multiplicative_order.v](../../../v/m/multiplicative_order.v) |
| Zig | [multiplicative_order.zig](../../../zig/m/multiplicative_order.zig) |

The shared scalar-suite registration is maintained separately.
