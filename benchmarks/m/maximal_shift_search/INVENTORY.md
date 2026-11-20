# Static package inventory

- ABI: `i64_array_scalar`; symbol: `maximal_shift_search`.
- Input: `[n,m,text...,pattern...]`, `0<=n<=4096`, `1<=m<=128`, alphabet
  `0..3`; invalid input returns `-1`.
- Output: packed count, sum, and xor of every overlapping match offset.
- Primary reference: leading-shift pattern order, adapted good-suffix table,
  and Quick Search lookahead table.
- Independent reference: direct comparison at each legal alignment.
- Workload: `workload.json`; covers overlap, order/shift behavior, misses,
  bounds, and malformed input.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: `RIGHTS.md`; sources and the distinction from Optimal Mismatch
  are documented in `README.md`.
- Static source/workload checker: `check_inventory.py`.
