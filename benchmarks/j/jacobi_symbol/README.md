# Jacobi symbol by quadratic reciprocity

This benchmark computes the Jacobi symbol for a canonical numerator and a
positive odd denominator, which may be composite. The primary repeatedly
removes powers of two, applies the supplementary law for 2 and quadratic
reciprocity, then reduces like the Euclidean algorithm. It does not factor the
denominator.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is `jacobi_symbol`. Input is
`[a,n]`, with `1 <= n <= 1,000,000,000`, `n` odd, and `0 <= a < n`. The exact
valid frame length is 2 words; the parseable length is 3. Null, malformed,
even/zero/oversized denominator, negative numerator, or noncanonical
numerator returns `-1`.

To keep the invalid sentinel separate from valid Jacobi values, the scalar
encodes symbol `-1` as 0, symbol 0 as 1, and symbol `+1` as 2. The algorithm
returns zero when the final reduced denominator is not 1. For `n=1`, the
symbol is defined as `+1`, so the only canonical input `[0,1]` returns 2.

The Jacobi symbol is defined as a product of prime Legendre symbols, but the
primary computes it without factoring. For composite `n`, Jacobi `+1` does
not prove that `a` is a square modulo `n`; for example, `(2/15)=+1` although
2 is not a square modulo 15. This differs from the local
[`quadratic_residue`](../../q/quadratic_residue/README.md) benchmark, which
computes the Legendre symbol for an explicitly prime denominator using Euler's
criterion. The independent oracle uses trial factorization and the product
definition, providing a structurally different reference.

## Provenance

The definition, reciprocity identities, and computation without factoring
are described in [Ben Lynn's Stanford notes on quadratic reciprocity](https://crypto.stanford.edu/pbc/notes/numbertheory/quadrecip.html)
and Victor Shoup's [*A Computational Introduction to Number Theory and Algebra*](https://www.shoup.net/ntb/ntb-v2_0.pdf), §12.3. The algorithm and symbol semantics are used as mathematical references only; all ports, references, fixtures, and documentation are clean-room work. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
| --- | --- |
| C | [c/j/jacobi_symbol.c](../../../c/j/jacobi_symbol.c) |
| C3 | [c3/j/jacobi_symbol.c3](../../../c3/j/jacobi_symbol.c3) |
| C++ | [cpp/j/jacobi_symbol.cpp](../../../cpp/j/jacobi_symbol.cpp) |
| Elisa | [elisa/j/jacobi_symbol.elisa](../../../elisa/j/jacobi_symbol.elisa) |
| Mojo | [mojo/j/jacobi_symbol.mojo](../../../mojo/j/jacobi_symbol.mojo) |
| Nim | [nim/j/jacobi_symbol.nim](../../../nim/j/jacobi_symbol.nim) |
| Odin | [odin/j/jacobi_symbol.odin](../../../odin/j/jacobi_symbol.odin) |
| Rust | [rust/j/jacobi_symbol.rs](../../../rust/j/jacobi_symbol.rs) |
| V | [v/j/jacobi_symbol.v](../../../v/j/jacobi_symbol.v) |
| Zig | [zig/j/jacobi_symbol.zig](../../../zig/j/jacobi_symbol.zig) |

Fixtures cover the supplementary law for 2, both directions of a reciprocity
sign flip, the published `(31/103)` example, prime and composite denominators,
a nonresidue with composite Jacobi value `+1`, zero and noncoprime inputs,
`n=1`, the maximum odd denominator, and invalid frames. The package-local
`verify_workload.py` is a static inventory description and is not run here.
