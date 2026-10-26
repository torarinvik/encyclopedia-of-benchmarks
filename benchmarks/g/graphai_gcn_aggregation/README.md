# GraphAIBench GCN normalized-neighbor aggregation

This is a clean-room, bounded profile of the forward aggregation in
[`gcn_aggregator.cpp::GCN_Aggregator::update_all`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/gnn/gconv/gcn_aggregator.cpp)
and its graph normalization setup in
[`graph_operations.h`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/include/gnn/graph_operations.h),
from GraphAIBench commit `17834cb29b7c542481c2e3740dc9664841b72f59`.
The source repository is MIT licensed; the full notice is in `LICENSE.txt`.
The nine implementations here were written independently and do not copy the
upstream implementation.

The ABI input is `[n,m,d, rowptr[n+1], colind[m], left[n], right[n], X[n*d]]`.
For each CSR row `u`, the kernel accumulates in edge and feature order:

```text
Y[u,k] = sum(left[u] * right[v] * X[v,k]) for v in rowptr[u]..rowptr[u+1]
```

It returns the row-major `n*d` output values. Empty rows produce zeros. The
profile bounds `n<=8`, `m<=24`, and `d<=4`, with finite normalization factors
in `[-4,4]` and features in `[-8,8]`. The passed normalization factors stand
for the source's per-vertex inverse-square-root degree data, letting the
profile isolate its sparse aggregation from graph loading and degree setup.
Arithmetic uses binary64 in this ABI profile; the source implementation uses
binary32. It excludes training, dense transforms, gradients, dropout, GPU
execution, and parallel scheduling.

Source order is preserved: CSR rows are visited in ascending vertex order,
each row's edges stay in input order, and each feature vector is accumulated
from feature zero upward. Invalid framing returns `-1`; a null output or
short capacity returns `-2`; no output is written on an error.

## Files

- `workload.json`: bounded source record, input/output contract, and fixtures.
- `../../graphai_gcn_aggregation_oracle.py`: workload oracle.
- `../../verify_float64_slice_io.py`: independent row-wise verifier oracle.
- `LICENSE.txt`: MIT notice copied from the pinned repository license.
