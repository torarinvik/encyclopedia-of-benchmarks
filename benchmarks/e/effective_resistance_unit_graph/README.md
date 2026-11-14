# Exact effective resistance of a unit graph

For a connected, simple, undirected graph whose edges have unit resistance,
compute the exact effective resistance between two distinct terminals. The
implementation builds the graph Laplacian and evaluates two integer
determinants: the cofactor with one row and column removed counts spanning
trees, while the minor with both terminal rows and columns removed counts
two-component spanning forests that separate the terminals. Their quotient is
the resistance; reduce it by the greatest common divisor.

Input is `[n,m,s,t,(u,v)*m]`, with zero-based vertices, `2 <= n <= 6`,
`0 <= m <= 15`, `0 <= s,t < n`, and `s != t`. Edges must be distinct,
undirected, and non-looping. The frame must contain exactly `4+2*m` words.
Disconnected graphs and malformed or null inputs return `-1`. On success,
return `numerator*65536+denominator`, where the numerator and denominator are
the positive, reduced integer resistance fraction. Each count is at most
`2^15`, so both terms fit below 65536. The maximum parseable length is 35.

Fraction-free elimination on matrices of dimension at most five gives
O(n³+m) time and O(n²) space. The independent reference enumerates edge
subsets to count trees and separating two-forests.
The minors are symmetric positive semidefinite. For a connected graph they
are positive definite, so their leading pivots are positive; for a
disconnected graph a zero leading pivot implies a zero tree determinant.
This permits the bounded elimination drafts to return zero without a row swap.

The [CP-Algorithms matrix-tree discussion](https://cp-algorithms.com/graph/kirchhoff-theorem.html)
describes the cofactor relationship. Its CC BY-SA article is used for the
mathematical idea only; this contract, reference, and code are independently
written. This is distinct from the existing spanning-tree count, which does
not evaluate the terminal-pair forest minor. Draft work remains unverified;
no code has been run. See [RIGHTS.md](RIGHTS.md) for the provenance note.

Drafts exist in C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig. The
Elisa draft converts its ABI input to a bounded view after the null and length
checks, then validates the complete frame before reading edges. The
scalar runner and verifier are registered in source; the verifier specifies
all simple graphs through four vertices, terminal orderings, a complete
six-vertex graph, and malformed and null inputs. The measured workload also
includes a six-vertex complete graph and a five-edge path to exercise the
largest determinant dimension and contrasting graph densities. Verifier cases
include extreme counts and endpoints to catch narrowing before validation, and
five- and six-vertex cases that reverse edge order, reverse endpoints, swap
terminals, and relabel vertices. These checks remain unrun.
