# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `kmp_skip_search`.
- Input profile: `[n,m,text...,pattern...]`, `n=0..4096`, `m=1..128`,
  alphabet `0..3`; malformed input returns `-1`.
- Result: packed overlapping match count, offset sum, and offset xor.
- Primary reference: KmpSkip bucket search reconciled with MP/KMP shifts.
- Independent reference: exhaustive alignment-by-alignment comparison.
- Workload: `workload.json`; fixtures include overlap, periodic border
  fallback, bucket advances, misses, and malformed shapes/symbols.
- Language ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: `RIGHTS.md`; source links are recorded in `README.md` and the
  workload metadata.
- Static source/workload inventory: `verify_workload.py`.

The benchmark is distinct from `alpha_skip_search`: that package samples
fixed-length factors and verifies candidates, while KmpSkip merges
character-position buckets with linear MP/KMP window shifts.
