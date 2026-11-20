# Newton divided-difference interpolation

Evaluate the unique polynomial of degree below `N` passing through `N`
distinct points in `F_998244353`. The primary constructs Newton coefficients
in place with divided differences and evaluates the nested Newton form. The
independent reference evaluates the Lagrange sum directly.

## Contract

The `i64_array_scalar` input is `[N,x[0..N-1],y[0..N-1],query]`. `N` is
1–12; every node, ordinate, and query is a canonical residue in
`0..998244352`; nodes must be distinct. The exact input length is `2+2*N`.
The scalar result is the interpolant at `query` modulo `998244353`.
Malformed or null input returns `-1`. Maximum valid and parseable lengths are
26 and 27 words.

For each divided-difference order `k`, the primary scans indices downward and
replaces `d[i]` by `(d[i]-d[i-1])/(x[i]-x[i-k])`. Fermat inversion is valid
because the modulus is prime and the nodes are distinct. The result is then
evaluated by nested multiplication in the Newton basis. The primary takes
`O(N² log MODULUS)` field operations because it computes each inverse with
modular exponentiation; its auxiliary storage is `O(N)`. The independent
Lagrange-form oracle is also `O(N² log MODULUS)` and follows a separate formula.

This is the Newton divided-difference evaluation method from NIST's
[DLMF §3.3](https://dlmf.nist.gov/3.3). It solves the same interpolation
problem as local [`polynomial_interpolation`](../../p/polynomial_interpolation/README.md),
but uses divided differences and nested Newton evaluation rather than
constructing and summing Lagrange basis polynomials to emit all monomial
coefficients. It is also distinct from
[`conversion_from_monomial_basis_to_newton_basis`](../../c/conversion_from_monomial_basis_to_newton_basis/README.md),
which transforms given monomial coefficients at supplied nodes without
interpolating sample values.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and [`verify_workload.py`](verify_workload.py).
The NIST reference provides the mathematical formula; all ports, fixtures, and
the finite-field workload are independently authored. See [`RIGHTS.md`](RIGHTS.md).

| Language | Source |
|---|---|
| C | [c/n/newton_divided_difference_interpolation.c](../../../c/n/newton_divided_difference_interpolation.c) |
| C3 | [c3/n/newton_divided_difference_interpolation.c3](../../../c3/n/newton_divided_difference_interpolation.c3) |
| C++ | [cpp/n/newton_divided_difference_interpolation.cpp](../../../cpp/n/newton_divided_difference_interpolation.cpp) |
| Elisa | [elisa/n/newton_divided_difference_interpolation.elisa](../../../elisa/n/newton_divided_difference_interpolation.elisa) |
| Mojo | [mojo/n/newton_divided_difference_interpolation.mojo](../../../mojo/n/newton_divided_difference_interpolation.mojo) |
| Nim | [nim/n/newton_divided_difference_interpolation.nim](../../../nim/n/newton_divided_difference_interpolation.nim) |
| Odin | [odin/n/newton_divided_difference_interpolation.odin](../../../odin/n/newton_divided_difference_interpolation.odin) |
| Rust | [rust/n/newton_divided_difference_interpolation.rs](../../../rust/n/newton_divided_difference_interpolation.rs) |
| V | [v/n/newton_divided_difference_interpolation.v](../../../v/n/newton_divided_difference_interpolation.v) |
| Zig | [zig/n/newton_divided_difference_interpolation.zig](../../../zig/n/newton_divided_difference_interpolation.zig) |
