# GraphAIBench GraphSAGE mean-neighbor aggregation

This package isolates `SAGE_Aggregator::aggregate` from the pinned
[`sage_aggregator.cpp`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/gnn/gconv/sage_aggregator.cpp)
in GraphAIBench commit `17834cb29b7c542481c2e3740dc9664841b72f59`.
GraphAIBench's MIT license and copyright notice are retained in `LICENSE.txt`.
All nine implementations are clean-room ports of the bounded operation.

Input is `[n,m,d,rowptr[n+1],colind[m],X[n*d]]`. Each CSR row `u` emits the
mean of the feature vectors at its outgoing neighbors, in source edge order:

```text
Y[u,k] = (sum X[v,k] for v in rowptr[u]..rowptr[u+1]) / degree(u)
```

The result is flattened vertex-major. Isolated vertices emit zero features.
The bound is `n<=8`, `m<=24`, `d<=4`, with finite features in `[-8,8]`.
Arithmetic uses binary64 in this ABI projection; GraphAIBench stores float
features and uses a binary32 neighbor scale. Graph loading, training,
backpropagation, and parallel scheduling are excluded.

Malformed input returns `-1`; null output and insufficient capacity return
`-2` without writes. The input CSR and feature order are explicit.

See `workload.json` for bounded fixtures and `../../graphai_sage_aggregation_oracle.py`
for the package oracle. The float64 suite uses a separate independent verifier.
