# Barycentric Lagrange evaluation

Evaluate the unique degree-below-`N` polynomial through distinct points over
`F_998244353` at one supplied query, using the second barycentric formula.

## Contract

The `i64_array_scalar` input is
`[N,x_0,...,x_(N-1),y_0,...,y_(N-1),q]`, with `1<=N<=8`, canonical field
residues, and pairwise-distinct nodes. Its exact length is `2+2*N`; the
maximum valid and parseable frames are 18 and 19 words. The scalar result is
the interpolant's value at `q` in `[0,998244352]`. A query equal to a node
returns that node's ordinate. Null, malformed, noncanonical, duplicate-node,
or trailing-frame input returns `-1`.

For each node, the primary computes the reciprocal nodal-product weight
`w_i = 1 / product_(j!=i)(x_i-x_j)`. Away from the nodes it evaluates
`(sum_i w_i*y_i/(q-x_i))/(sum_i w_i/(q-x_i))` in the field. Distinct nodes
make every required difference invertible; the denominator is nonzero away
from the node set because it equals the reciprocal nodal polynomial. A fixed
eight-entry weight array plus scalar state stays within the 128-byte native
workspace cap. The primary uses `O(N^2 + N log p)` field operations. The
independent reference solves the Vandermonde system by modular Gauss-Jordan
elimination, then evaluates the recovered monomial polynomial by Horner's
rule, using `O(N^3 + N log p)` operations and `O(N^2)` reference storage.

## Distinction and provenance

NIST DLMF [§3.3(i), Eq. 3.3.1](https://dlmf.nist.gov/3.3.i#E1) gives the
barycentric Lagrange form, with reciprocal nodal-product weights in
[Eq. 3.3.3_1](https://dlmf.nist.gov/3.3.i#E3_1). This profile differs from
local `polynomial_interpolation`, which constructs and emits monomial
coefficients, and `newton_divided_difference_interpolation`, which evaluates
the Newton form. The package's inputs, finite-field bounds, references,
fixtures, prose, and ports are independently authored; see [RIGHTS.md](RIGHTS.md).

## Workload and language ports

`workload.json` pins exact outputs and malformed-frame cases. The static
references are `primary_oracle.py` and `independent_oracle.py`; package-local
inventory and workload APIs live in `check_inventory.py` and
`verify_workload.py`. The package is registered in the shared scalar runner
and verifier, the root catalog, and the expansion coverage ledger.

| Language | Source |
|---|---|
| C | [barycentric_lagrange_evaluation.c](../../../c/b/barycentric_lagrange_evaluation.c) |
| C3 | [barycentric_lagrange_evaluation.c3](../../../c3/b/barycentric_lagrange_evaluation.c3) |
| C++ | [barycentric_lagrange_evaluation.cpp](../../../cpp/b/barycentric_lagrange_evaluation.cpp) |
| Elisa | [barycentric_lagrange_evaluation.elisa](../../../elisa/b/barycentric_lagrange_evaluation.elisa) |
| Mojo | [barycentric_lagrange_evaluation.mojo](../../../mojo/b/barycentric_lagrange_evaluation.mojo) |
| Nim | [barycentric_lagrange_evaluation.nim](../../../nim/b/barycentric_lagrange_evaluation.nim) |
| Odin | [barycentric_lagrange_evaluation.odin](../../../odin/b/barycentric_lagrange_evaluation.odin) |
| Rust | [barycentric_lagrange_evaluation.rs](../../../rust/b/barycentric_lagrange_evaluation.rs) |
| V | [barycentric_lagrange_evaluation.v](../../../v/b/barycentric_lagrange_evaluation.v) |
| Zig | [barycentric_lagrange_evaluation.zig](../../../zig/b/barycentric_lagrange_evaluation.zig) |
