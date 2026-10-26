# GraphAIBench GAT attention aggregation

This package isolates the forward aggregation in `GAT_Aggregator::aggregate`
and `update_all` from the pinned
[`gat_aggregator.cpp`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/gnn/gconv/gat_aggregator.cpp)
at GraphAIBench commit `17834cb29b7c542481c2e3740dc9664841b72f59`. The
repository's MIT notice is retained in `LICENSE.txt`; the nine ports are
clean-room implementations of the bounded contract.

Input is `[n,m,d,rowptr[n+1],colind[m],alpha_l[d],alpha_r[d],X[n*d]]`.
For each edge `u -> v`, it computes
`s(u,v)=LeakyReLU(dot(alpha_l,X[u])+dot(alpha_r,X[v]), 0.2)`, normalizes
scores within row `u` with softmax, and emits the attention-weighted sum of
the neighbor feature vectors. CSR edge order is preserved for dot products,
normalization, and accumulation. Empty rows emit zero vectors. The bounds are
`n<=8`, `m<=24`, `d<=4`; coefficients and features are finite in `[-8,8]`.

This is a binary64 slice projection of GraphAIBench's float32 forward
aggregator. It excludes learned-weight initialization and updates, dropout,
backpropagation, multi-head setup, graph loading, and parallel scheduling.
Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writes. See `workload.json` and
`../../graphai_gat_aggregation_oracle.py`; the suite uses a separate verifier
oracle.
