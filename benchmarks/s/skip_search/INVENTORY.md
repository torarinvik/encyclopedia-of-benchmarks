# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `skip_search`.
- Input: `[n,m,text...,pattern...]`, `n=0..4096`, `m=1..128`, alphabet
  `0..3`; malformed input returns `-1`.
- Result: packed count, sum, and xor of all overlapping match offsets.
- Primary reference: pattern-position buckets sampled at every `m` text symbols.
- Independent reference: direct comparison at every legal alignment.
- Workload: `workload.json`; includes repeated bucket positions, overlapping
  hits, sampled candidates that fail verification, empty/no-hit cases, and
  malformed inputs.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Provenance: `RIGHTS.md`; source URL and bounds also appear in workload.
- Static source/workload inventory: `verify_workload.py`.

This package is distinct from Alpha Skip's fixed-length factor buckets and
KmpSkip's MP/KMP border-shift processing.
