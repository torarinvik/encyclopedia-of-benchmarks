# GARDENIA matrix-factorization SGD

This package isolates the sequential verifier recurrence in GARDENIA's
`src/sgd/verifier.cc` at pinned
[`chenxuhao/gardenia`](https://github.com/chenxuhao/gardenia) commit
[`5894df11cf47f8839945edadff43dc79e260216d`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d).
For each user in ascending ID and each rating in CSR row order, it evaluates
the current user/item dot product, forms the residual, then immediately
updates both latent vectors using the pre-update values for each factor. The
following rating observes those changed factors. The source defaults are
`lambda=0.001`, `step=3.5e-7`, convergence RMSE `<0.1`, and at most three
iterations.

## Contract

Input is `[users, items, ratings, factors, rowptr[users+1], item_id[ratings], rating[ratings], latent[(users+items)*factors]]`.
Bounds are at most 7 users, 7 items, 8 total vertices, 24 ratings, and 4
factors. Item IDs are local to the item partition; the latent vector stores
user factors first and item factors second. The explicit initial factors are
bounded to `[0,0.1]`, reflecting the pinned host initializer; ratings are
bounded to `[-4,4]`. Empty rating sets and malformed CSR are invalid.

The source defaults to binary32 `ScoreT` and `LatentT`; this portable profile
uses binary64 but preserves the sequential per-rating update and convergence
order. Explicit initial factors replace the host's seeded initializer. It
returns the concatenated updated latent vector. Invalid input returns `-1`;
null or short output returns `-2` without writes. The independent oracle is
[`gardenia_sgd_oracle.py`](../../gardenia_sgd_oracle.py), and fixed cases are
in [`workload.json`](workload.json).

This is a distinct recurrence from local
[`graphai_cf_sgd_sweep`](../graphai_cf_sgd_sweep/README.md): GraphAIBench
accumulates errors from the pre-sweep factors then applies one synchronous
factor sweep. GARDENIA updates each rating immediately, so later ratings use
the factors already changed by earlier ratings.

The MIT notice is retained in [`LICENSE.txt`](LICENSE.txt). The nine ports
are in the corresponding language directories as `gardenia_sgd`.

| Language | Source |
| --- | --- |
| C | [`c/g/gardenia_sgd.c`](../../../c/g/gardenia_sgd.c) |
| C3 | [`c3/g/gardenia_sgd.c3`](../../../c3/g/gardenia_sgd.c3) |
| C++ | [`cpp/g/gardenia_sgd.cpp`](../../../cpp/g/gardenia_sgd.cpp) |
| Elisa | [`elisa/g/gardenia_sgd.elisa`](../../../elisa/g/gardenia_sgd.elisa) |
| Nim | [`nim/g/gardenia_sgd.nim`](../../../nim/g/gardenia_sgd.nim) |
| Odin | [`odin/g/gardenia_sgd.odin`](../../../odin/g/gardenia_sgd.odin) |
| Rust | [`rust/g/gardenia_sgd.rs`](../../../rust/g/gardenia_sgd.rs) |
| V | [`v/g/gardenia_sgd.v`](../../../v/g/gardenia_sgd.v) |
| Zig | [`zig/g/gardenia_sgd.zig`](../../../zig/g/gardenia_sgd.zig) |
