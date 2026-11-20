# Static package inventory

- Algorithm: `suffix_array_blind_trie`.
- ABI: `i64_array_bytes_output`.
- Contract: byte text length 0–32; one suffix start per output i64; capacity
  `8*n`; invalid input `-1`; null or short output `-2`.
- Fixed algorithm workspace: at most 2,304 bytes, including traversal and
  child scratch arrays plus bounded call-frame state; input/output excluded.
- Kernel: ordered blind trie, descent over common-prefix branch positions, leaf LCP repair,
  insertion at the true mismatch depth, ordered-child traversal.
- References: `primary_oracle.py` uses the trie; `independent_oracle.py` sorts
  suffix slices directly.
- Workload: `workload.json`; fixtures are statically reviewed by
  `verify_workload.py`.
- Provenance: NIST DADS blind sort and Manzini–Ferragina Section 3.1; see
  `RIGHTS.md`.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Shared byte-output runner/verifier integration is present; no suite checks
  have been run.
