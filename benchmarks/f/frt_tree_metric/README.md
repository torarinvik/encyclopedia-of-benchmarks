# FRT tree metric sample

This package implements one bounded realization of the FRT/CKR hierarchical
partition construction summarized in Chapter 25, “Approximating Metric Spaces
by Tree Metrics.” It accepts the sample's permutation and scale offset as
input, refines clusters from coarse to fine, and returns the induced 2-HST
leaf-distance matrix. It does not estimate or assert the expected-stretch
guarantee: that guarantee is over the randomized distribution of samples.

## Contract

The ABI is `i64_array_bytes_output`, symbol `frt_tree_metric`. Input is
`[n, beta_q, permutation[0..n), distance_matrix[n*n]]`, with row-major matrix
entries. `n` is 2..8; `beta_q` is 1024..2047 and represents
`beta_q / 1024`; the permutation contains every vertex ID once. The matrix
must be a symmetric integer metric with zero diagonal, positive off-diagonal
distances, entries at most 255, and the triangle inequality.

Start with the whole vertex set. Let `H=ceil(log2(max_distance))`. At each
integer level `ell=H,H-1,...,-10`, refine each current cluster independently:
scan centers in the supplied permutation, and for each still-unassigned
center form a child from the still-unassigned vertices within radius
`(beta_q/1024)*2^ell`. Children are emitted in permutation order. Two leaves
that first separate at level `ell` receive tree distance `2^(ell+3)`. The
output is the symmetric row-major `n*n` matrix of these distances scaled by
1024, so all output values are integers. The fixed-point beta sampling and
finite level range are bounded benchmark choices; a single supplied sample
does not establish the chapter's randomized expected-stretch result.

Malformed input returns `-1` before output checks. Null output or capacity
below `8*n*n` bytes returns `-2` without writes. A successful call returns
`8*n*n`; the maximum input length is 74 signed 64-bit words and maximum output
is 512 bytes. The output is staged until validation and capacity checks pass.

## Source

Based on Jittat Fakcharoenphol, Satish Rao, and Kunal Talwar, “Approximating
Metric Spaces by Tree Metrics,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_25`](https://doi.org/10.1007/978-1-4939-2864-4_25).
The chapter identifies the FRT construction using CKR randomized rounding and
its 2-HST output. This package is an independent implementation of that
construction profile and does not copy book text or code. See
[`RIGHTS.md`](RIGHTS.md) for attribution and scope.

Fixtures and bounds are in [`workload.json`](workload.json). The primary
oracle is [`frt_tree_metric_oracle.py`](../../frt_tree_metric_oracle.py), and
the independent verifier oracle is
[`frt_tree_metric_verifier_oracle.py`](../../frt_tree_metric_verifier_oracle.py).
