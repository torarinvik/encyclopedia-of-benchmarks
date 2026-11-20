# All-pairs directed random-walk hitting times

For each ordered pair `(s,t)` in a finite strongly connected directed graph,
the benchmark returns the expected number of steps for a walk starting at
`s` to first reach `t`. At every step, one outgoing arc is chosen uniformly.
The diagonal is zero. Results are residues modulo `1,000,000,007`.

Input is `[n,m,(u,v)*m]`, with zero-based vertices, `3 <= n <= 8`, and
`0 <= m <= n*(n-1)`. Arcs are directed; loops and repeated ordered pairs are
invalid. The graph must be strongly connected. Its exact frame is `2+2*m`
signed-i64 words, with at most 114 valid words and 115 parseable words. The
output is an `n*n` row-major matrix of little-endian signed-i64 residues, so
the maximum output is 512 bytes. Invalid or null input returns `-1` without
writes. A valid input with null output or insufficient capacity returns `-2`
without writes. Successful calls return the number of bytes written.

The primary follows the general-graph method in the source. It solves
`pi*P=pi`, normalizes `sum(pi)=1`, and uses `g_i=1/pi_i`. It then solves
`(I-P)Y=J-diag(g)` with the last coordinate fixed to zero, and returns
`H[i,j]=Y[i,j]-Y[j,j]`. The reduced coefficient matrix is the principal
cofactor of the directed outdegree Laplacian, scaled by nonzero outdegrees.
The independent reference instead fixes each target in turn and solves the
absorbing first-step equations
`d_i*h_i - sum(h_j for i->j, j!=t) = d_i` for all `i!=t`.

The field inverses are defined for this bounded profile. Every outdegree is
between 1 and 7. By the directed Matrix Tree theorem, each root cofactor is a
positive count of in-arborescences and is at most `8^(8-2)=262144`; strong
connectivity makes it nonzero. The stationary weights are proportional to
`d_i*tau_i`, so their normalizer is positive and at most
`8*7*262144=14680064`, below the prime modulus. The reduced and absorbing
systems have determinants equal to a nonzero tree cofactor divided by a
product of nonzero outdegrees. Those determinants therefore remain nonzero
modulo the field prime.

Both references use modular Gauss-Jordan elimination. The primary time and
space bounds are `O(n^3+m)` and `O(n^2)`; the independent reference uses
`O(n^4+m)` time across all targets and `O(n^2)` working storage. The declared
8,192-byte workspace cap covers fixed graph, matrix, vector, and parser state;
the caller-owned output buffer is excluded.

This is method-distinct from
[`tree_random_walk_edge_hitting_cost`](../../t/tree_random_walk_edge_hitting_cost/README.md):
that package is restricted to undirected trees, uses a tree rerooting
recurrence, and returns weighted edge-direction costs. This package accepts
general directed strongly connected graphs and returns every ordered-pair
first-hit expectation using stationary probabilities and linear systems.

The algorithm description is in [OI Wiki — Random Walk on Graphs](https://oi-wiki.org/graph/graph-random-walk/),
“General graph,” with the full method also presented in the IOI 2019 national
team paper [A discussion of random walks on graph models](https://rusunoi.github.io/books/National-Team-Thesis/2019.pdf).
Those sources are cited for mathematical provenance only; this profile,
workload, references, and ports are clean-room work. See [RIGHTS.md](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/all_pairs_directed_random_walk_hitting_times.c`](../../../c/a/all_pairs_directed_random_walk_hitting_times.c) |
| C3 | [`c3/a/all_pairs_directed_random_walk_hitting_times.c3`](../../../c3/a/all_pairs_directed_random_walk_hitting_times.c3) |
| C++ | [`cpp/a/all_pairs_directed_random_walk_hitting_times.cpp`](../../../cpp/a/all_pairs_directed_random_walk_hitting_times.cpp) |
| Elisa | [`elisa/a/all_pairs_directed_random_walk_hitting_times.elisa`](../../../elisa/a/all_pairs_directed_random_walk_hitting_times.elisa) |
| Mojo | [`mojo/a/all_pairs_directed_random_walk_hitting_times.mojo`](../../../mojo/a/all_pairs_directed_random_walk_hitting_times.mojo) |
| Nim | [`nim/a/all_pairs_directed_random_walk_hitting_times.nim`](../../../nim/a/all_pairs_directed_random_walk_hitting_times.nim) |
| Odin | [`odin/a/all_pairs_directed_random_walk_hitting_times.odin`](../../../odin/a/all_pairs_directed_random_walk_hitting_times.odin) |
| Rust | [`rust/a/all_pairs_directed_random_walk_hitting_times.rs`](../../../rust/a/all_pairs_directed_random_walk_hitting_times.rs) |
| V | [`v/a/all_pairs_directed_random_walk_hitting_times.v`](../../../v/a/all_pairs_directed_random_walk_hitting_times.v) |
| Zig | [`zig/a/all_pairs_directed_random_walk_hitting_times.zig`](../../../zig/a/all_pairs_directed_random_walk_hitting_times.zig) |

The workload includes an 8-vertex complete directed graph at the 114-word
valid-input bound. Its 512-byte output has zero diagonal entries and seven in
every off-diagonal position; a companion case supplies 511 bytes and expects
the no-write capacity error. The 115-word maximum parseable frame appends one
trailing word to that complete graph and is rejected without output.

`primary_oracle.py`, `independent_oracle.py`, the bounded workload, and static
inventory helpers accompany the ports. No executable checks have been run.
