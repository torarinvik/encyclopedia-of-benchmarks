# Dirichlet inverse prefix sums on quotient values

This draft recovers the prefix sums of the Dirichlet inverse of a function
from its own prefix sums at the distinct values `floor(N/i)`. It differs from
[`dirichlet_convolution_and_prefix_sums`](../dirichlet_convolution_and_prefix_sums/README.md),
which combines two supplied functions rather than inverting one.

For `1 <= N <= 64`, list the distinct positive `floor(N/i)` values in
ascending order as `q[0..K)`. The `i64_array_bytes_output` input is
`[N,F(q[0]),...,F(q[K-1])]`, where `F` is a prefix sum modulo 998244353.
Residues are in `[0,998244352]` and `F(1)` must be nonzero. Emit the inverse
prefix sums at those quotient values in the same order as little-endian i64
residues. Invalid or null input returns `-1`; null or short output returns
`-2` without writes. The maximum valid input is 16 i64 words, with 120 output
bytes.

The primary recurrence groups factors by equal floor quotient and solves each
inverse prefix in ascending quotient order, using the modular inverse of the
first coefficient. Binary searches locate group endpoints in the sorted
quotient list. It takes O(N + K² log K + log P) time and O(K) space in this
bounded profile. The independent reference expands a representative sequence
consistent with the supplied prefixes and uses coefficient-level divisor
recurrence; this produces the same queried prefix sums without assuming values
at unrepresented indices.

The [Library Checker task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/number_theory/dirichlet_inverse_and_prefix_sums/task.md)
provides the operation idea; its repository declares Apache-2.0. The local
contract, code, and reference are independently written. No upstream task prose,
source code, or fixtures are copied.

Status: all ten language drafts, an independent reference, a workload, and
byte-output suite registration are present. Verifier source specifies all
bounded N values, maximum framing, malformed inputs, and buffer boundaries.
Nothing has been compiled or run.
