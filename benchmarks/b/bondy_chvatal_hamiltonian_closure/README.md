# Bondy–Chvátal Hamiltonian closure

This bounded benchmark computes the Bondy–Chvátal closure of a simple
undirected graph. It repeatedly adds a missing edge whose current endpoint
degrees sum to at least the vertex count.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `bondy_chvatal_hamiltonian_closure`.
- Input is `[n,m,(u,v)*m]`, with `3<=n<=8`, `0<=m<=28`, and zero-based
  vertices. Edges are undirected and simple; loops and duplicate unordered
  pairs are invalid.
- Recompute degrees after every addition. Choose the lexicographically least
  eligible nonedge `(u,v)` with `u<v` and `degree(u)+degree(v)>=n`. This is a
  deterministic profile convention; the final closure is independent of the
  eligible-pair order.
- Output is `[complete_flag,added_edge_count,row_mask_0,...,row_mask_(n-1)]`
  as little-endian signed i64 words. Bit `v` in row `u` means that edge `{u,v}`
  is present in the final closure. The flag is 1 exactly when the closure is
  complete (`K_n`), and 0 otherwise. It reports no Hamiltonian cycle.
- By the Bondy–Chvátal theorem, a complete closure is a sufficient certificate
  that the input graph is Hamiltonian. An incomplete closure is inconclusive;
  it does not mean the input lacks a Hamiltonian cycle.
- Invalid input returns `-1`. Null or short output returns `-2` without writes,
  after input validation. Maximum valid/parseable input lengths are 58/59
  words; maximum output is 80 bytes. Workspace is capped at 1,024 bytes,
  excluding caller-owned input and output buffers.

The primary reference repeatedly selects the first eligible pair. The
independent reference adds every pair eligible under the same round-start
degree snapshot, repeating until stable. Both compute the unique closure but
use different update schedules.

The local [`hamiltonian_cycle_exists`](../../h/hamiltonian_cycle_exists/README.md)
uses backtracking to search for a cycle. This package computes the degree-sum
closure transformation and its sufficient certificate; it does not search for
or return a cycle.

Primary method source: Bondy and Chvátal, “A method in graph theory,”
*Discrete Mathematics* 15(2), 1976, [DOI 10.1016/0012-365X(76)90078-9](https://doi.org/10.1016/0012-365X(76)90078-9).
The pinned RosettaCodeData [popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
supplies discovery only. See [RIGHTS.md](RIGHTS.md).

The [hand-pinned workload](workload.json) includes empty, stable incomplete,
complete-certificate, incomplete-after-addition, maximum-frame, malformed,
null, and short-output cases. All ten ports and static helpers are listed in
[INVENTORY.md](INVENTORY.md). Helpers are authored but have not been run.

| Language | Source |
|---|---|
| C | [c/b/bondy_chvatal_hamiltonian_closure.c](../../../c/b/bondy_chvatal_hamiltonian_closure.c) |
| C3 | [c3/b/bondy_chvatal_hamiltonian_closure.c3](../../../c3/b/bondy_chvatal_hamiltonian_closure.c3) |
| C++ | [cpp/b/bondy_chvatal_hamiltonian_closure.cpp](../../../cpp/b/bondy_chvatal_hamiltonian_closure.cpp) |
| Elisa | [elisa/b/bondy_chvatal_hamiltonian_closure.elisa](../../../elisa/b/bondy_chvatal_hamiltonian_closure.elisa) |
| Mojo | [mojo/b/bondy_chvatal_hamiltonian_closure.mojo](../../../mojo/b/bondy_chvatal_hamiltonian_closure.mojo) |
| Nim | [nim/b/bondy_chvatal_hamiltonian_closure.nim](../../../nim/b/bondy_chvatal_hamiltonian_closure.nim) |
| Odin | [odin/b/bondy_chvatal_hamiltonian_closure.odin](../../../odin/b/bondy_chvatal_hamiltonian_closure.odin) |
| Rust | [rust/b/bondy_chvatal_hamiltonian_closure.rs](../../../rust/b/bondy_chvatal_hamiltonian_closure.rs) |
| V | [v/b/bondy_chvatal_hamiltonian_closure.v](../../../v/b/bondy_chvatal_hamiltonian_closure.v) |
| Zig | [zig/b/bondy_chvatal_hamiltonian_closure.zig](../../../zig/b/bondy_chvatal_hamiltonian_closure.zig) |
