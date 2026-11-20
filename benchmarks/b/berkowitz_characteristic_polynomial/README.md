# Samuelson–Berkowitz characteristic polynomial

Compute the descending coefficients of `det(xI-A)` over the modular ring
`Z/modulus Z`. Input is `[N,modulus,row-major matrix]`, with
`1<=N<=7`, `2<=modulus<=1,000,000,000`, and matrix entries in
`[-1,000,000,1,000,000]`. The result is `[1,c1,...,cN]`, with every
coefficient represented by its least nonnegative residue in a little-endian
i64 byte vector. The maximum output is 64 bytes.

The implementation is the sequential Samuelson–Berkowitz recurrence. For a
trailing principal block `A=[[a,R],[S,M]]`, first compute the characteristic
polynomial of `M`. Build a lower-triangular Toeplitz transform with first
column `1,-a,-R*S,-R*M*S,...`, then multiply it by the child coefficient
vector. Blocks are added from bottom-right to top-left. The method uses only
addition, subtraction, and multiplication, so the supplied modulus may be
composite and no inverse is required. Entries and products are reduced
modulo the supplied modulus after each operation. The bounded primary
performs O(N^4) modular operations and uses O(N^2) workspace.

This is distinct from the local [`characteristic_polynomial`](../characteristic_polynomial/README.md),
which uses similarity transformations to Hessenberg form and a recurrence
over the prime field `998244353`. Here the method is division-free and the
modulus is an input, including composite values. The independent reference
forms `det(xI-A)` directly by the Leibniz permutation expansion, providing a
different method for this small domain.

The method is based on Stuart J. Berkowitz, “On computing the determinant in
small parallel time using a small number of processors,” *Information
Processing Letters* 18(3), 147–150 (1984), DOI
[10.1016/0020-0190(84)90018-8](https://doi.org/10.1016/0020-0190(84)90018-8).
See [RIGHTS.md](RIGHTS.md) for provenance. All ports, contract details, and
fixtures are clean-room benchmark material.

Malformed or null input returns `-1`. After complete input validation, null
or undersized output returns `-2` without writes. No source code, prose, or
fixtures are reused. The shared `i64_array_bytes_output` runner and verifier
register both references, workload fixtures, bounds, and package inventory.
