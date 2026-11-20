# Chebyshev Clenshaw evaluation

This package evaluates a polynomial from coefficients in the Chebyshev basis
using the backward Clenshaw recurrence. It is distinct from
[`polynomial_evaluation`](../../p/polynomial_evaluation/README.md), which
evaluates monomial coefficients with Horner's rule, and from
[`chebyshev_iteration`](../chebyshev_iteration/README.md), which iteratively
solves a symmetric positive-definite linear system.

## Contract

- ABI: `i64_array_scalar`; symbol: `chebyshev_clenshaw_evaluation`.
- Input: `[degree,x,a0,...,a_degree]`, where `0<=degree<=16` and every field
  element is a canonical residue in `0..998244352` modulo `998244353`.
  The exact frame length is `degree+3`; maximum valid/parseable lengths are
  19/21 words.
- The represented polynomial is the ordinary, unprimed sum
  `a0*T0(x) + a1*T1(x) + ... + a_degree*T_degree(x)`. In particular `a0` is
  the full constant-basis coefficient. `T0=1`, `T1=x`, and
  `T_(k+1)=2*x*T_k-T_(k-1)` in the field.
- Return the canonical residue in `0..998244352`. Degree zero returns `a0`;
  at `x=1` the result is the coefficient sum, while at `x=-1 mod p` it is
  the alternating coefficient sum. Null, malformed, or noncanonical input
  returns `-1`.
- The recurrence uses only field additions, subtractions, and multiplications;
  it requires no modular division or inversion.
- After reducing `2*x` modulo `p`, every product is below `p^2`, and every
  unreduced recurrence expression has magnitude below `p^2+p < 10^18`, within
  signed 64-bit range in all ports.

## Algorithm and independent reference

The primary sets `b_(degree+1)=b_(degree+2)=0` and sweeps coefficients down
from the highest degree to one:

```text
b_k = a_k + 2*x*b_(k+1) - b_(k+2)
result = a_0 + x*b_1 - b_2
```

All values are reduced modulo `998244353`. The algorithm takes `O(degree)`
time and `O(1)` auxiliary space. The independent reference instead generates
`T_0,T_1,...` in increasing order from the Chebyshev basis recurrence and
accumulates `a_k*T_k`; it also takes `O(degree)` time and `O(1)` space. Their
opposite traversal directions make the reference structurally independent
from the primary's backward recurrence.

NIST's [DLMF §3.11(ii)](https://dlmf.nist.gov/3.11) gives the Chebyshev
recurrence and Clenshaw summation rule. DLMF writes its series with a halved
zeroth term; this benchmark uses full `a0*T0` coefficients and the equivalent
terminal formula above, so it performs no division by two in the finite
field.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py),
[`independent_oracle.py`](independent_oracle.py), and
[`check_inventory.py`](check_inventory.py). The bounded workload includes
degree and field endpoints, modular wraparound, the maximum degree, and
malformed frames. All code and fixtures are clean-room.

## Rights and provenance

The algorithm reference is the NIST Digital Library of Mathematical Functions,
[§3.11(ii), “Summation of Chebyshev Series: Clenshaw’s Algorithm”](https://dlmf.nist.gov/3.11).
Only mathematical algorithm ideas are used. No DLMF wording, code, examples,
or test data are copied; the ports, workload, and explanatory text were
written for this repository. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [chebyshev_clenshaw_evaluation.c](../../../c/c/chebyshev_clenshaw_evaluation.c) |
| C3 | [chebyshev_clenshaw_evaluation.c3](../../../c3/c/chebyshev_clenshaw_evaluation.c3) |
| C++ | [chebyshev_clenshaw_evaluation.cpp](../../../cpp/c/chebyshev_clenshaw_evaluation.cpp) |
| Elisa | [chebyshev_clenshaw_evaluation.elisa](../../../elisa/c/chebyshev_clenshaw_evaluation.elisa) |
| Mojo | [chebyshev_clenshaw_evaluation.mojo](../../../mojo/c/chebyshev_clenshaw_evaluation.mojo) |
| Nim | [chebyshev_clenshaw_evaluation.nim](../../../nim/c/chebyshev_clenshaw_evaluation.nim) |
| Odin | [chebyshev_clenshaw_evaluation.odin](../../../odin/c/chebyshev_clenshaw_evaluation.odin) |
| Rust | [chebyshev_clenshaw_evaluation.rs](../../../rust/c/chebyshev_clenshaw_evaluation.rs) |
| V | [chebyshev_clenshaw_evaluation.v](../../../v/c/chebyshev_clenshaw_evaluation.v) |
| Zig | [chebyshev_clenshaw_evaluation.zig](../../../zig/c/chebyshev_clenshaw_evaluation.zig) |
