# Baswana–Sen weighted spanner

This package profiles the randomized local-clustering Algorithm II described
by Baswana and Sen for a general undirected weighted graph. It is distinct
from [`weighted_greedy_spanner`](../weighted_greedy_spanner/README.md), which
implements the chapter's increasing-weight greedy Algorithm I. The local
clustering and stream-clustering packages do not construct weighted graph
spanners, and [`euclidean_t_spanner`](../../e/euclidean_t_spanner/README.md)
uses a geometric input and guarantee.

## Bounded replay contract

The ABI is `i64_array_bytes_output`, exported symbol
`baswana_sen_weighted_spanner`. Input is
`[n, m, k, sample_mask_1, ..., sample_mask_(k-1), (u,v,w)...]` with
`2 <= n <= 8`, `0 <= m <= 28`, `2 <= k <= 3`, `1 <= w <= 32`, normalized
simple edges `0 <= u < v < n`, and one mask per clustering round. Bit `c` in a
round's mask says that the currently existing cluster centered at vertex `c`
is sampled. Bits for centers that are not currently present are ignored. The
mask is a caller-supplied realization of the source's independent cluster
sampling; the package does not generate random numbers or assert that a tape
has the source distribution.

The profile starts with singleton clusters, executes `k-1` forming rounds,
then performs vertex-to-cluster joining. It chooses minimum-weight edges;
equal-weight minima use `(u,v)` order, while the source's “strictly lighter”
comparison remains a strict numeric-weight comparison. Each round computes
local choices against the round-start residual-edge snapshot and applies the
selected-edge and removal sets together. This fixes the source's arbitrary
tie and vertex scheduling choices. The source's size-threshold resampling is
omitted: every supplied tape yields a bounded trace, and no expected-size or
expected-time claim is made. The `(2k-1)` stretch guarantee follows from the
source algorithm's cluster-radius argument for any supplied sample outcomes.

Output is one byte per input edge, in input order (`1` means selected). Exact
input length is `3 + (k-1) + 3*m`; the largest valid input is 89 signed
64-bit words and the parser accepts at most 90 words. Success returns `m`,
including zero for an empty edge list. Invalid input returns `-1`; null output
or insufficient capacity returns `-2` without writes. Maximum output is 28
bytes.

The primary [oracle](../../baswana_sen_weighted_spanner_oracle.py) replays
the round-by-round local decisions from edge arrays. The independent
[verifier oracle](../../baswana_sen_weighted_spanner_verifier_oracle.py) uses
per-vertex adjacency lists and groups active incident edges by current cluster
before applying the same specified trace. The [workload](workload.json)
includes no-sample, sampled-merge, two-round, tie, disconnected, malformed,
null-output, and capacity cases. The package-local [static
checker](verify_baswana_sen_weighted_spanner_package.py) checks metadata,
fixtures, both oracles, and port presence when explicitly invoked.

## Sources and ports

The chapter identifies Algorithm II as the local-clustering construction and
cites Baswana and Sen (2007). The complete sequential procedure is in the
primary paper, Section 4.2, with the alternate cluster-cluster phase in
Section 4.3; the profile uses the vertex-cluster version. See the [Springer
chapter](https://doi.org/10.1007/978-1-4939-2864-4_10), the [primary
paper](https://doi.org/10.1002/rsa.20130), and the [author-hosted paper
manuscript](https://www.cse.iitd.ac.in/~ssen/journals/randstruc.pdf).

| Language | Port |
| --- | --- |
| C | [`c/s/baswana_sen_weighted_spanner.c`](../../../c/s/baswana_sen_weighted_spanner.c) |
| C3 | [`c3/s/baswana_sen_weighted_spanner.c3`](../../../c3/s/baswana_sen_weighted_spanner.c3) |
| C++ | [`cpp/s/baswana_sen_weighted_spanner.cpp`](../../../cpp/s/baswana_sen_weighted_spanner.cpp) |
| Elisa | [`elisa/s/baswana_sen_weighted_spanner.elisa`](../../../elisa/s/baswana_sen_weighted_spanner.elisa) |
| Mojo | [`mojo/s/baswana_sen_weighted_spanner.mojo`](../../../mojo/s/baswana_sen_weighted_spanner.mojo) |
| Nim | [`nim/s/baswana_sen_weighted_spanner.nim`](../../../nim/s/baswana_sen_weighted_spanner.nim) |
| Odin | [`odin/s/baswana_sen_weighted_spanner.odin`](../../../odin/s/baswana_sen_weighted_spanner.odin) |
| Rust | [`rust/s/baswana_sen_weighted_spanner.rs`](../../../rust/s/baswana_sen_weighted_spanner.rs) |
| V | [`v/s/baswana_sen_weighted_spanner.v`](../../../v/s/baswana_sen_weighted_spanner.v) |
| Zig | [`zig/s/baswana_sen_weighted_spanner.zig`](../../../zig/s/baswana_sen_weighted_spanner.zig) |

No book or paper code, prose, figures, or pseudocode have been copied. See
[`RIGHTS.md`](RIGHTS.md) for provenance.
