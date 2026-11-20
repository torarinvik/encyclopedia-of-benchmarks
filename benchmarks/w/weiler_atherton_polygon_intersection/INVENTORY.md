# Package inventory

- Algorithm: `weiler_atherton_polygon_intersection`
- ABI: `i64_array_bytes_output`
- Primary: `primary_oracle.py` (interleaved boundary lists and entry/exit walk)
- Independent reference: `independent_oracle.py` (split-edge arrangement fragments)
- Workload: `workload.json` (bounded valid, malformed, and ABI cases)
- Static workload reconciliation: `verify_workload.py` (authored only; not run)
- Static inventory: `check_inventory.py` (authored only; not run)
- Rights and provenance: `RIGHTS.md`
- Shared suite/catalog status: registered with the `i64_array_bytes_output`
  runner and verifier, listed in `CATALOG.md` and the root README.

Input is at most 26 valid / 27 parseable i64 words; output is at most 1,680
bytes; workspace is capped at 65,536 bytes. Workspace covers bounded event,
node, rational-point, ring, and staged-output storage. Caller-owned buffers are
excluded. No helper or benchmark was run.

| Language | Source |
|---|---|
| C | `c/w/weiler_atherton_polygon_intersection.c` |
| C3 | `c3/w/weiler_atherton_polygon_intersection.c3` |
| C++ | `cpp/w/weiler_atherton_polygon_intersection.cpp` |
| Elisa | `elisa/w/weiler_atherton_polygon_intersection.elisa` |
| Mojo | `mojo/w/weiler_atherton_polygon_intersection.mojo` |
| Nim | `nim/w/weiler_atherton_polygon_intersection.nim` |
| Odin | `odin/w/weiler_atherton_polygon_intersection.odin` |
| Rust | `rust/w/weiler_atherton_polygon_intersection.rs` |
| V | `v/w/weiler_atherton_polygon_intersection.v` |
| Zig | `zig/w/weiler_atherton_polygon_intersection.zig` |
