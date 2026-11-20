# Randomized Tutte-matrix perfect matching

This bounded profile implements the simple cubic general-graph procedure in
Mucha and Sankowski's Algorithm 2. Each undirected edge is assigned a supplied
nonzero value in the finite field `F_65521`. The port constructs the
skew-symmetric Tutte matrix, inverts it by modular Gauss–Jordan elimination,
then scans remaining vertices in ascending ID order. For the current vertex
`c`, it chooses the lowest remaining `r` for which both the graph-matrix entry
`A[c,r]` and inverse entry `B[r,c]` are nonzero. It eliminates row `r` with
column `c`, then row `c` with column `r`, and continues. This is the paper's
paired row/column elimination for the general graph case.

Input is `[n,m,(u,v,x)*m]`, where `n` is even and in `2..8`; edges are simple,
normalized `u<v`, and strictly lexicographically ordered. Each supplied
substitution `x` is in `[1,65520]`. The frame length is exactly `2+3m`; the
maximum valid/parseable lengths are 86/87 signed-i64 words. The supplied edge
values replay the randomized substitution deterministically. The package does
not generate random values or measure a probability guarantee.

The output bytes encode `[status,pair_count,u0,v0,...]` as little-endian
signed-i64 words. `status=1` carries a perfect matching, with pairs in the
algorithm's ascending scan order. If the sampled Tutte matrix is singular,
the result is `[0,0]`. This occurs for every substitution when the graph has
no perfect matching, but can also occur for an unlucky supplied substitution
on a graph that does have one; status zero is therefore not a certificate of
nonexistence. A nonsingular matrix permits the algorithm to return a perfect
matching. The maximum successful output has ten words (80 bytes). Malformed
input returns `-1`; null or insufficient output returns `-2` without writing.

The primary reference performs modular matrix inversion and the paper's two
eliminations per matched pair in `O(n^3)` time with `O(n^2)` bounded storage.
The independent reference recomputes residual determinants and inverse-entry
cofactors by recursive determinant expansion, then selects the same first
eligible partner. It does not update an inverse matrix. Its factorial
determinant work is limited to `n<=8`. The declared workspace cap is 8,192
bytes, including fixed augmented/inverse matrices, elimination scratch, and
staged output; caller buffers are excluded.

## Duplicate decision and source scope

The local [`edmonds_blossom_algorithm`](../../e/edmonds_blossom_algorithm/README.md)
computes unweighted maximum cardinality by blossom contraction. This package
uses randomized algebraic Tutte-matrix inversion to construct a perfect
matching; it does not duplicate that combinatorial kernel. The local
[`general_weighted_matching`](../../g/general_weighted_matching/README.md)
uses subset DP for maximum total weight and is also distinct. This package
profiles the perfect-matching construction only; it does not implement
Mucha–Sankowski's recursive maximum-matching reduction or the paper's
fast-matrix-multiplication optimizations.

Mucha's Chapter 225, “Maximum Matching,” identifies Mucha and Sankowski's
2004 work. The operational method is “Maximum Matchings via Gaussian
Elimination,” §3, Algorithm 2, DOI
[`10.1109/FOCS.2004.40`](https://doi.org/10.1109/FOCS.2004.40). Chapter 225 is
DOI [`10.1007/978-1-4939-2864-4_225`](https://doi.org/10.1007/978-1-4939-2864-4_225).
The references, ports, contract, and fixtures are clean-room and reproduce no
source code, examples, tests, figures, or prose. See [`RIGHTS.md`](RIGHTS.md).

## Workload and source inventory

[`workload.json`](workload.json) covers a unique perfect matching, alternative
perfect matchings, no perfect matching, a singular substitution on a positive
instance, the maximum graph/frame/output, field and edge validation, null
buffers, and output-capacity errors. The static inventory and fixture
reconciler are listed in [`INVENTORY.md`](INVENTORY.md).

| Language | Port |
|---|---|
| C | [tutte_matrix_randomized_perfect_matching.c](../../../c/t/tutte_matrix_randomized_perfect_matching.c) |
| C3 | [tutte_matrix_randomized_perfect_matching.c3](../../../c3/t/tutte_matrix_randomized_perfect_matching.c3) |
| C++ | [tutte_matrix_randomized_perfect_matching.cpp](../../../cpp/t/tutte_matrix_randomized_perfect_matching.cpp) |
| Elisa | [tutte_matrix_randomized_perfect_matching.elisa](../../../elisa/t/tutte_matrix_randomized_perfect_matching.elisa) |
| Mojo | [tutte_matrix_randomized_perfect_matching.mojo](../../../mojo/t/tutte_matrix_randomized_perfect_matching.mojo) |
| Nim | [tutte_matrix_randomized_perfect_matching.nim](../../../nim/t/tutte_matrix_randomized_perfect_matching.nim) |
| Odin | [tutte_matrix_randomized_perfect_matching.odin](../../../odin/t/tutte_matrix_randomized_perfect_matching.odin) |
| Rust | [tutte_matrix_randomized_perfect_matching.rs](../../../rust/t/tutte_matrix_randomized_perfect_matching.rs) |
| V | [tutte_matrix_randomized_perfect_matching.v](../../../v/t/tutte_matrix_randomized_perfect_matching.v) |
| Zig | [tutte_matrix_randomized_perfect_matching.zig](../../../zig/t/tutte_matrix_randomized_perfect_matching.zig) |

All ports expose `tutte_matrix_randomized_perfect_matching` with the
`i64_array_bytes_output` ABI. Shared suite and catalog integration remain with
root.
