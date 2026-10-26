# GraphAIBench collaborative-filtering SGD sweep

This package isolates one synchronous factor-update sweep from
`SGDSolver` in the pinned
[`src/embedding/omp_base.cc`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/embedding/omp_base.cc)
and its parameter defaults in
[`src/embedding/main.cc`](https://github.com/chenxuhao/GraphAIBench/blob/17834cb29b7c542481c2e3740dc9664841b72f59/src/embedding/main.cc)
at commit `17834cb29b7c542481c2e3740dc9664841b72f59`. GraphAIBench's MIT
license and copyright notice are retained in `LICENSE.txt`; the nine ports
are clean-room implementations.

Input is `[users,items,m,k,lambda,step,rowptr[users+items+1],colind[m],rating[m],latent[(users+items)*k]]`.
The graph is directed user-to-item CSR. For each rating edge, the profile
computes the source dot product in factor order, forms `delta = rating -
estimate`, and accumulates `item_latent * delta` into the user's error vector
in CSR order. It then updates every vertex factor once with
`latent += step * (-lambda*latent + error)` using the original latent matrix.
As in the pinned source sweep, item vertices have no outgoing rows, so their
error is zero and they receive the regularization-only update. Bounds are at
most 8 total vertices, 24 ratings, and 4 factors; latent values are in
`[-2,2]`, ratings in `[-4,4]`, `lambda` in `[0,1]`, and `step` in `[0,0.01]`.

This is a binary64 projection of the source's float-oriented arithmetic. It
reduces source `K=20` to a bounded `k<=4` and runs exactly one sweep instead of
the default five training iterations. Caller-supplied initial factors replace
random initialization; graph parsing, user-ordering, RMSE convergence checks,
training orchestration, and OpenMP scheduling are excluded. Malformed input
returns `-1`; null output or insufficient capacity returns `-2` without
writes. See `workload.json` and `../../graphai_cf_sgd_sweep_oracle.py`; the
float64 suite uses an independent verifier oracle.
