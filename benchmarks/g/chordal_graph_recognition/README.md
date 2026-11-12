# Chordal graph recognition with MCS

This package recognizes chordal simple undirected graphs with maximum cardinality search (MCS). For a chordal graph it returns a perfect elimination ordering (PEO); for a nonchordal graph it returns an induced cycle of length at least four. The original task defines chordality by the absence of induced cycles of length four or more and permits any valid certificate.

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,m,u0,v0,...]` with zero-based vertex IDs.
- The bounded profile accepts `1 <= n <= 6`, `0 <= m <= 15`, no loops, and no repeated undirected edges. `M=0` is supported. This is a small certificate-producing benchmark, not the official 200,000-vertex limit.
- MCS chooses the unnumbered vertex with the greatest number of already numbered neighbors; ties choose the smallest vertex ID. Reversing its selection order gives the candidate PEO, which is checked directly.
- Output is little-endian unsigned 64-bit words. A chordal input returns `[1, v0,...,v(n-1)]`. A nonchordal input returns `[0,k,c0,...,c(k-1)]`, where the cycle vertices are in cyclic order and occur once. The package finds a witness by scanning induced vertex subsets and testing their induced degree/connectivity.
- Maximum input length is 32 signed 64-bit values. Maximum output is 8 words / 64 bytes. Invalid input returns `-1`; null or short output returns `-2`; errors write no bytes.

## Distinction from local elimination packages

The local minimum-degree and minimum-fill treewidth packages compute heuristic elimination orders and fill edges. The exact treewidth package minimizes elimination width by exhaustive enumeration. None decides chordality and returns either a PEO or an induced-hole certificate. MCS recognition and certificate production are therefore a distinct operation.

## Source

The contract is based on [Library Checker: Chordal Graph Recognition](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/chordal_graph_recognition/task.md), its [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/chordal_graph_recognition/info.toml), and its [checker](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/chordal_graph_recognition/checker.cpp). The local bounded profile is a clean-room implementation of the mathematical certificate contract.

## Files

- [`workload.json`](workload.json)
- [oracle](../../chordal_graph_recognition_oracle.py)

| Language | Port |
|---|---|
| C | [`c/g/chordal_graph_recognition.c`](../../../c/g/chordal_graph_recognition.c) |
| C3 | [`c3/g/chordal_graph_recognition.c3`](../../../c3/g/chordal_graph_recognition.c3) |
| C++ | [`cpp/g/chordal_graph_recognition.cpp`](../../../cpp/g/chordal_graph_recognition.cpp) |
| Elisa | [`elisa/g/chordal_graph_recognition.elisa`](../../../elisa/g/chordal_graph_recognition.elisa) |
| Nim | [`nim/g/chordal_graph_recognition.nim`](../../../nim/g/chordal_graph_recognition.nim) |
| Odin | [`odin/g/chordal_graph_recognition.odin`](../../../odin/g/chordal_graph_recognition.odin) |
| Rust | [`rust/g/chordal_graph_recognition.rs`](../../../rust/g/chordal_graph_recognition.rs) |
| V | [`v/g/chordal_graph_recognition.v`](../../../v/g/chordal_graph_recognition.v) |
| Zig | [`zig/g/chordal_graph_recognition.zig`](../../../zig/g/chordal_graph_recognition.zig) |
| Mojo | [`mojo/g/chordal_graph_recognition.mojo`](../../../mojo/g/chordal_graph_recognition.mojo) |
