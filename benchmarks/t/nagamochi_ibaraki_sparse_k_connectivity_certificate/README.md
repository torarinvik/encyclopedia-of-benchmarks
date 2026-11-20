# Nagamochi–Ibaraki sparse k-connectivity certificate

This bounded profile implements the FOREST decomposition from Nagamochi and
Ibaraki's sparse connectivity certificate. It assigns every input edge to a
forest layer; the certificate keeps the first `k` layers and preserves each
pair's edge connectivity up to `k`. It reports the layer assigned to every
input edge, with zero for edges beyond the retained prefix.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `nagamochi_ibaraki_sparse_k_connectivity_certificate`.
- Input is `[n,m,k,(u,v)*m]`, with `3<=n<=8`, `0<=m<=28`, and `1<=k<=3`.
  The undirected graph is simple; disconnected graphs and isolated vertices
  are valid. Endpoints are zero based, normalized as `u<v`, and each edge
  record appears once.
- The deterministic profile initializes every rank to zero. It repeatedly
  selects the unscanned vertex of greatest rank, breaking ties by lowest
  vertex ID. It scans that vertex's incident unscanned edges in input-record
  order. An edge to `y` receives layer `rank[y]+1`; then the selected vertex's
  rank increases if its old rank equaled `rank[y]`, and `rank[y]` increases.
- Output is `[m,layer[0],...,layer[m-1]]` in little-endian signed i64. Layers
  greater than `k` are written as zero. Maximum input and parseable lengths
  are 59 and 60 words; maximum output is 232 bytes. Invalid input returns
  `-1`; null or insufficient output returns `-2` without writing.
- The mathematical FOREST procedure uses a bucket queue for linear time.
  These bounded ports choose each next vertex by scanning at most eight
  vertices, so the rank scan takes `O(n^2+m)` time. Their simple-graph
  duplicate check scans earlier edge records, giving `O(n^2+m^2)` total time
  and `O(n+m)` storage for this bounded profile.

The primary oracle follows the rank-and-layer scan with input-ordered
adjacency lists. The independent reference scans the full edge record list at
each selected vertex and then checks the certificate theorem by enumerating
all separating cuts for every vertex pair. The workload includes disconnected,
empty, dense, malformed, maximum-output, and output-capacity cases. The
callable static review compares both references against the fixtures and
checks pairwise edge connectivity preservation.

## Source and rights

Hiroshi Nagamochi and Toshihide Ibaraki, “A Linear-Time Algorithm for Finding
a Sparse k-Connected Spanning Subgraph of a k-Connected Graph,” *Algorithmica*
7 (1992), 583–596, [author-hosted paper, §2 and Theorem 2.1](https://gi.cebitec.uni-bielefeld.de/_media/teaching/2013summer/936nagamochi-ibaraki-1992-sparse-k-connected-subgraph.pdf).
The source is used for algorithm attribution and mathematical properties
only; no code, prose, figures, or test data are copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.c`](../../../c/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.c) |
| C3 | [`c3/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.c3`](../../../c3/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.c3) |
| C++ | [`cpp/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.cpp`](../../../cpp/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.cpp) |
| Elisa | [`elisa/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.elisa`](../../../elisa/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.elisa) |
| Mojo | [`mojo/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.mojo`](../../../mojo/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.mojo) |
| Nim | [`nim/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.nim`](../../../nim/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.nim) |
| Odin | [`odin/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.odin`](../../../odin/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.odin) |
| Rust | [`rust/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.rs`](../../../rust/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.rs) |
| V | [`v/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.v`](../../../v/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.v) |
| Zig | [`zig/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.zig`](../../../zig/t/nagamochi_ibaraki_sparse_k_connectivity_certificate.zig) |

See [workload.json](workload.json), both references, and the callable package
review [verify_workload.py](verify_workload.py).
