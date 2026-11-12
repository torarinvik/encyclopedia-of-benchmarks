# GraphAIBench gated graph-message update

This package isolates one forward recurrent graph update from
[`GGNN_Aggregator::aggregate`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/gnn/gconv/ggnn_aggregator.cu)
and the corresponding operations in
[`graph_operations.h`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/include/gnn/graph_operations.h),
at GraphAIBench commit `17834cb29b7c542481c2e3740dc9664841b72f59` in the
[pinned source tree](https://github.com/chenxuhao/GraphAIBench/tree/17834cb29b7c542481c2e3740dc9664841b72f59). The
upstream project is MIT licensed; its notice is retained in `LICENSE.txt`.
The ports are clean-room bounded implementations.

## Operation

The input is
`[n,m,d,rowptr[n+1],colind[m],H[n*d],Wz[n*n],Wr[n*n],Wc[n*n],Uz[n*n],Ur[n*n],Uc[n*n]]`.
Rows describe directed outgoing edges; repeated destinations are allowed and
contribute repeatedly. First, each vertex's message is the componentwise sum
of its outgoing neighbors' state vectors. For each vertex `v` and feature
`f`, the update and reset gates are sigmoid transforms of `Wz*a + Uz*H` and
`Wr*a + Ur*H`; the candidate is `tanh(Wc*a + Uc*(r*H))`; the new state is
`(1-z)*H + z*candidate`. The six matrices are row-major `n` by `n`, matching
the pinned kernel's graph-vertex reduction dimension. Feature vectors are
vertex-major.

The bounds are `1<=n<=8`, `0<=m<=24`, and `1<=d<=4`; states are in `[-1,1]`
and matrix entries are in `[-0.25,0.25]`. The input length is exactly
`4+n+m+n*d+6*n*n` (at most 452 values); one additional parseable value is
reserved for a rejected trailing-data case. Arithmetic uses binary64 and CSR
edge order for message sums. Output is `n*d` binary64 state values in
vertex-major, feature-major order, with absolute and relative comparison
tolerances of `1e-12`. The maximum fixed workspace is 193 scalar elements.

This is distinct from the local GCN, GraphSAGE, and GAT aggregation packages:
the profile combines a graph-neighbor sum with recurrent update/reset gates,
learned dense vertex-axis transforms, a gated candidate, and interpolation
with the previous state. It excludes learned-weight initialization, dropout,
backpropagation, optimizer updates, graph loading, and CUDA scheduling.

Malformed input returns `-1`; a null or undersized output returns `-2` after
input validation. Errors do not modify output. The primary direct oracle is
[`../../graphai_ggnn_message_update_oracle.py`](../../graphai_ggnn_message_update_oracle.py);
the independent target-wise oracle is
[`../../graphai_ggnn_message_update_verifier_oracle.py`](../../graphai_ggnn_message_update_verifier_oracle.py).

## Ports

- [`c/g/graphai_ggnn_message_update.c`](../../../c/g/graphai_ggnn_message_update.c)
- [`c3/g/graphai_ggnn_message_update.c3`](../../../c3/g/graphai_ggnn_message_update.c3)
- [`cpp/g/graphai_ggnn_message_update.cpp`](../../../cpp/g/graphai_ggnn_message_update.cpp)
- [`elisa/g/graphai_ggnn_message_update.elisa`](../../../elisa/g/graphai_ggnn_message_update.elisa)
- [`mojo/g/graphai_ggnn_message_update.mojo`](../../../mojo/g/graphai_ggnn_message_update.mojo)
- [`nim/g/graphai_ggnn_message_update.nim`](../../../nim/g/graphai_ggnn_message_update.nim)
- [`odin/g/graphai_ggnn_message_update.odin`](../../../odin/g/graphai_ggnn_message_update.odin)
- [`rust/g/graphai_ggnn_message_update.rs`](../../../rust/g/graphai_ggnn_message_update.rs)
- [`v/g/graphai_ggnn_message_update.v`](../../../v/g/graphai_ggnn_message_update.v)
- [`zig/g/graphai_ggnn_message_update.zig`](../../../zig/g/graphai_ggnn_message_update.zig)

`workload.json` records the bounded ABI and fixtures. The package-local
`verify_graphai_ggnn_message_update_package.py` checks static inventory,
attribution, fixture framing, and both oracle results. The shared float64
suite registration is handled separately.
