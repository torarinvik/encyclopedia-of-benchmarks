# Static inventory

- ABI: `i64_array_scalar`.
- Function symbol: `konc_maxclique_dyn`.
- Input: `[n, adjacency_mask_0, ..., adjacency_mask_(n-1)]`, `0 <= n <= 24`.
- Output: maximum clique cardinality, or `-1` for malformed input.
- References: dynamic approximate-coloring primary and direct subset-enumeration independent oracle.
- Workload: `workload.json`, including maximum 24-vertex complete/path frames and malformed framing cases.
- Static inventory checker: `verify_workload.py` (not run).
- Source ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Workspace: 65,536 bytes.
- Provenance: Konc–Janežič (2007), KACTL algorithm description; clean-room source.
- Duplicate distinctions: OI Wiki ordered suffix-bound search, maximum-independent-set branch/search, and Bron–Kerbosch enumeration are separate contracts.
- Suite registration: `benchmarks/run_i64_array_scalar.py` and `benchmarks/verify_i64_array_scalar.py`.
- Verification policy: source and workload were reviewed statically; no suite, package checker, or executable was run.
