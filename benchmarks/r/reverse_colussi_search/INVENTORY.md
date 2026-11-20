# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `reverse_colussi_search`.
- Input: `[n,m,text...,pattern...]`, n `0..4096`, m `1..128`, alphabet
  `0..3`; malformed input returns `-1`.
- Output: packed count, sum, and xor of all overlapping match offsets.
- Primary reference: Reverse Colussi's `h` comparison order, `rcGs`
  good-suffix shifts, and alphabet-by-shift bad-character shifts.
- Independent reference: direct comparison at every legal alignment.
- Workload: `workload.json`; includes matches, dense overlap, periodic
  borders, bad-character shifts, misses, and malformed input.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: `RIGHTS.md`; the algorithm source is listed in `README.md` and
  workload metadata.
- Static source/workload inventory: `verify_workload.py`.

The comparison schedule and table construction distinguish this profile from
the local Boyer–Moore, Colussi, KmpSkip, and Alpha Skip Search packages.
