# Package inventory

| Artifact | Purpose |
|---|---|
| `RESERVATION.md` | Distinctness, ABI, bounds, and method reservation |
| `workload.json` | Contract metadata, provenance, and bounded fixtures |
| `primary_oracle.py` | Packed-row iterative two-pass Kosaraju reference |
| `independent_oracle.py` | Adjacency-list Tarjan reference and canonical output |
| `README.md` | Contract, algorithm, complexity, and port map |
| `RIGHTS.md` | Clean-room and source provenance notes |
| `verify_workload.py` | Static source/metadata/fixture/reference checker |

The ten exported language sources are:

| Language | Repository path |
|---|---|
| C | `c/k/kosaraju_dense_bitset_scc.c` |
| C3 | `c3/k/kosaraju_dense_bitset_scc.c3` |
| C++ | `cpp/k/kosaraju_dense_bitset_scc.cpp` |
| Elisa | `elisa/k/kosaraju_dense_bitset_scc.elisa` |
| Mojo | `mojo/k/kosaraju_dense_bitset_scc.mojo` |
| Nim | `nim/k/kosaraju_dense_bitset_scc.nim` |
| Odin | `odin/k/kosaraju_dense_bitset_scc.odin` |
| Rust | `rust/k/kosaraju_dense_bitset_scc.rs` |
| V | `v/k/kosaraju_dense_bitset_scc.v` |
| Zig | `zig/k/kosaraju_dense_bitset_scc.zig` |

The workload records Library Checker issue #1373 as the discovery index. No
popularity score is published for that proposal, so `discovery.score` is
`null` with an explanatory note. The issue-list comment count is not a score.
