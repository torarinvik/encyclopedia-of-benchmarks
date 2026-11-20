# Package inventory

- `README.md` — bounded contract, source discussion, distinction, and port links.
- `RIGHTS.md` — algorithm attribution and clean-room provenance.
- `workload.json` — pinned valid, malformed, null, and capacity cases.
- `primary_oracle.py` — SvS shortest-first filtering with monotone binary-search lower bounds.
- `independent_oracle.py` — set-membership filtering of the shortest input list.
- `verify_workload.py` — static workload/reference and bound reconciliation helper.
- `check_inventory.py` — static package and ten-port inventory helper.

Ports:

| Language | File |
| --- | --- |
| C | `c/i/inverted_list_svs_binary_search.c` |
| C3 | `c3/i/inverted_list_svs_binary_search.c3` |
| C++ | `cpp/i/inverted_list_svs_binary_search.cpp` |
| Elisa | `elisa/i/inverted_list_svs_binary_search.elisa` |
| Mojo | `mojo/i/inverted_list_svs_binary_search.mojo` |
| Nim | `nim/i/inverted_list_svs_binary_search.nim` |
| Odin | `odin/i/inverted_list_svs_binary_search.odin` |
| Rust | `rust/i/inverted_list_svs_binary_search.rs` |
| V | `v/i/inverted_list_svs_binary_search.v` |
| Zig | `zig/i/inverted_list_svs_binary_search.zig` |
