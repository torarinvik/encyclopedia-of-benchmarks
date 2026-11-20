# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `reverse_factor_search`.
- Input: `[n,m,text...,pattern...]`, n `0..4096`, m `1..128`, alphabet
  `0..3`; malformed input returns `-1`.
- Output: packed count, sum, and xor of every overlapping match offset.
- Primary reference: suffix automaton of the reversed pattern, terminal-state
  shifts, and period shift after a full match.
- Independent reference: direct comparison at each legal alignment.
- Workload: `workload.json`; covers matches, overlaps, terminal shifts,
  misses, boundaries, and malformed input.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: `RIGHTS.md`; source details appear in `README.md` and workload
  metadata.
- Static source/workload inventory: `verify_workload.py`.

The automaton and scan differ from local Two-Way, BNDM, Backward Oracle
Matching, Reverse Colussi, and Turbo Reverse Factor packages.
