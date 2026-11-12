# Conversion from Monomial Basis to Newton Basis

Given monomial coefficients `a_i` and nodes `p_i` over F_998244353, this
package finds the coefficients `b_i` satisfying

`f(x) = Σ_i b_i · Π_{j<i}(x-p_j)`.

## Bounded contract

The `i64_array_bytes_output` input is `[N, a_0, ..., a_(N-1), p_0, ..., p_(N-1)]`,
with `1<=N<=12` and all coefficients and nodes in `[0,998244352]`. Nodes may
repeat. The output is N little-endian signed 64-bit Newton-basis coefficients
in order and returns `8*N` bytes. Malformed input returns `-1`; a null output
or a capacity below `8*N` returns `-2` without writes. Maximum input length is
25 words, maximum output is 96 bytes.

## Algorithms

The ports repeatedly evaluate the current residual at the next node, record
that value as `b_i`, then divide the residual by `(x-p_i)` with synthetic
division. This takes O(N²) field operations and O(N) coefficient storage.
The independent oracle explicitly constructs every Newton basis polynomial
and solves the resulting unit-triangular coefficient system with modular
Gaussian elimination (O(N³) operations and O(N²) storage). The two approaches
use different state representations and conversion procedures.

The local N limit is far below the official maximum of 131072; it keeps the
quadratic conversion suitable for a small cross-language benchmark profile.

## Provenance

The operation is from Library Checker’s
[Conversion from Monomial Basis to Newton Basis task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/conversion_from_monomial_basis_to_newton_basis/task.md)
and [parameter file](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/conversion_from_monomial_basis_to_newton_basis/info.toml).
The task repository is Apache-2.0. See [RIGHTS.md](RIGHTS.md) for the clean-room
reuse scope. [workload.json](workload.json) contains named fixtures and ABI
bounds; [verify_workload.py](verify_workload.py) is a static package inventory
and fixture checker. Root-level suite registration is complete in the
`i64_array_bytes_output` runner and verifier. No programs, tests, checkers,
builds, compilers, or benchmarks were run during integration.

| Language | Source |
|---|---|
| C | [c/c/conversion_from_monomial_basis_to_newton_basis.c](../../../c/c/conversion_from_monomial_basis_to_newton_basis.c) |
| C3 | [c3/c/conversion_from_monomial_basis_to_newton_basis.c3](../../../c3/c/conversion_from_monomial_basis_to_newton_basis.c3) |
| C++ | [cpp/c/conversion_from_monomial_basis_to_newton_basis.cpp](../../../cpp/c/conversion_from_monomial_basis_to_newton_basis.cpp) |
| Elisa | [elisa/c/conversion_from_monomial_basis_to_newton_basis.elisa](../../../elisa/c/conversion_from_monomial_basis_to_newton_basis.elisa) |
| Mojo | [mojo/c/conversion_from_monomial_basis_to_newton_basis.mojo](../../../mojo/c/conversion_from_monomial_basis_to_newton_basis.mojo) |
| Nim | [nim/c/conversion_from_monomial_basis_to_newton_basis.nim](../../../nim/c/conversion_from_monomial_basis_to_newton_basis.nim) |
| Odin | [odin/c/conversion_from_monomial_basis_to_newton_basis.odin](../../../odin/c/conversion_from_monomial_basis_to_newton_basis.odin) |
| Rust | [rust/c/conversion_from_monomial_basis_to_newton_basis.rs](../../../rust/c/conversion_from_monomial_basis_to_newton_basis.rs) |
| V | [v/c/conversion_from_monomial_basis_to_newton_basis.v](../../../v/c/conversion_from_monomial_basis_to_newton_basis.v) |
| Zig | [zig/c/conversion_from_monomial_basis_to_newton_basis.zig](../../../zig/c/conversion_from_monomial_basis_to_newton_basis.zig) |
