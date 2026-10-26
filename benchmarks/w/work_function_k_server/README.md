# Work-function algorithm for finite-metric k-server

This clean-room profile implements the online work-function update for a small
finite metric. A configuration is a set of `k` distinct points. Its distance to
another configuration is the minimum total point distance over all bijective
server matchings.

Input is `[p,k,n, metric[p*p row-major], initial[k], requests[n]]`. The metric
has `2 <= p <= 6`, integer distances in `[0,1000]`, zero diagonal, positive
off-diagonal entries, symmetry, and the triangle inequality. The initial
configuration contains distinct point IDs. There are at most eight requests.
The implementation enumerates the at most `C(6,3)=20` configurations.

The work function starts at `w0(X)=d(C0,X)` and updates after request `r` as
`wt(X)=min_{Y: r in Y}(w(t-1)(Y)+d(Y,X))`. For a request not already occupied,
the profile moves the current server in the lowest sorted slot among candidates
minimizing `w(t-1)(C-x+r)+d(x,r)`. A request at an already occupied point is
served without moving a server. The output is
`[n,k,(sorted server point IDs after each request)...]`, encoded as little-endian
signed 64-bit integers. The maximum output is 208 bytes. Invalid input returns
`-1`; null output or insufficient capacity returns `-2` without writing.

This is a bounded, deterministic finite-metric projection of the work-function
algorithm, not a randomized workload. The configuration space and all tie rules
are explicit. No source code or book prose is copied.

Source: “Work-Function Algorithm for k-Servers,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_484`](https://doi.org/10.1007/978-1-4939-2864-4_484).

## Ports

| Language | Port |
|---|---|
| C | `c/w/work_function_k_server.c` |
| C3 | `c3/w/work_function_k_server.c3` |
| C++ | `cpp/w/work_function_k_server.cpp` |
| Elisa | `elisa/w/work_function_k_server.elisa` |
| Nim | `nim/w/work_function_k_server.nim` |
| Odin | `odin/w/work_function_k_server.odin` |
| Rust | `rust/w/work_function_k_server.rs` |
| V | `v/w/work_function_k_server.v` |
| Zig | `zig/w/work_function_k_server.zig` |

The primary exact-output oracle is `benchmarks/work_function_k_server_oracle.py`;
the independent verifier oracle is `benchmarks/work_function_k_server_verifier_oracle.py`.
