# Primitive Root Search by Order Factorization

Input is the one-element array `[p]`, where `2<=p<=4093` must be prime. The
ports validate primality by trial division. The result is the least primitive
root modulo `p`; malformed, composite, or out-of-profile input returns `-1`.

For odd `p`, factor `p-1` into its distinct prime divisors `q`. A candidate
`g` is a generator exactly when `g^((p-1)/q) != 1 (mod p)` for every such `q`.
The search tests candidates in ascending order and returns the first one that
passes all checks. The modulus `p=2` returns `1`. This method uses the
factorization of the group order and modular exponentiation.

The local [`primitive_root`](../primitive_root/README.md) profile tests each
candidate by generating `p-1` powers and checking that no residue repeats.
That exhaustive residue-cycle method differs from the prime-factor order
criterion here. [`multiplicative_order`](../../m/multiplicative_order/README.md)
uses order reduction for one supplied residue; it does not search for a
generator. The primary reference uses the factor test, while the independent
reference explicitly constructs each candidate's residue cycle. The method
follows [CP-Algorithms' Primitive Root article](https://cp-algorithms.com/algebra/primitive-root.html);
only algorithmic ideas were consulted. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/p/primitive_root_factorization.c](../../../c/p/primitive_root_factorization.c) |
| C3 | [c3/p/primitive_root_factorization.c3](../../../c3/p/primitive_root_factorization.c3) |
| C++ | [cpp/p/primitive_root_factorization.cpp](../../../cpp/p/primitive_root_factorization.cpp) |
| Elisa | [elisa/p/primitive_root_factorization.elisa](../../../elisa/p/primitive_root_factorization.elisa) |
| Mojo | [mojo/p/primitive_root_factorization.mojo](../../../mojo/p/primitive_root_factorization.mojo) |
| Nim | [nim/p/primitive_root_factorization.nim](../../../nim/p/primitive_root_factorization.nim) |
| Odin | [odin/p/primitive_root_factorization.odin](../../../odin/p/primitive_root_factorization.odin) |
| Rust | [rust/p/primitive_root_factorization.rs](../../../rust/p/primitive_root_factorization.rs) |
| V | [v/p/primitive_root_factorization.v](../../../v/p/primitive_root_factorization.v) |
| Zig | [zig/p/primitive_root_factorization.zig](../../../zig/p/primitive_root_factorization.zig) |
