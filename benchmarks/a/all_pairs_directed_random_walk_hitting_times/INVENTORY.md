# Package inventory

- Primary reference: stationary distribution plus reduced rank-deficient
  system.
- Independent reference: one absorbing-chain system per target.
- Workload: directed cycle, complete digraph, asymmetric strongly connected
  graph, an 8-vertex/114-word complete digraph with 512-byte output, the
  115-word maximum parseable trailing-word rejection, invalid graph/frame
  cases, and byte-ABI capacity/null cases.
- Languages: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- ABI: `i64_array_bytes_output`.
- Valid input bound: 114 words; parseable bound: 115 words.
- Output bound: 512 bytes; workspace cap: 8,192 bytes.
- Provenance: OI Wiki general-graph random walk section and IOI 2019
  national-team paper; clean-room implementation.
