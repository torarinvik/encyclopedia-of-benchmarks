# Static package inventory

- ABI: `i64_array_scalar`; exported symbol: `string_matching_ordered_alphabets`.
- Input: `[n,m,text...,pattern...]`, `n=0..4096`, `m=1..128`, ordered
  alphabet `0..3`; malformed input returns `-1`.
- Result: packed count, sum, and xor of all overlapping match offsets.
- Primary reference: online maximal-suffix and period updates over matched text.
- Independent reference: direct comparison at every legal alignment.
- Workload: `workload.json`; includes periodic overlaps, ordered-symbol
  mismatches, a terminal full match, empty/no-match inputs, and malformed data.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Provenance: `RIGHTS.md`; references and bounds are in `README.md` and workload.
- Static source/workload inventory: `verify_workload.py`.

This is distinct from Two-Way matching's pattern preprocessing: the search
updates maximal-suffix state online from the text and uses constant extra space.
