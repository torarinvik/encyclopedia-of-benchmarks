# Static package inventory

Algorithm package: `schieber_vishkin_lca`  
ABI: `i64_array_bytes_output`  
Discovery lead: RosettaCodeData `popular-tasks`, pinned commit
`1d475861d7141ef2fafff293d9339f56e4b0f5db`, title score 21.  
Primary method reference: Schieber and Vishkin (1988), DOI
[10.1137/0217079](https://doi.org/10.1137/0217079).  
Operational derivation: Heun, section 4.2, [lecture notes PDF](https://www.bio.ifi.lmu.de/mitarbeiter/volker-heun/notes/as9.pdf).

| Artifact | Status |
|---|---|
| C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig ports | Present; source only, not compiled or run |
| `workload.json` | Present; bounded valid and error cases |
| `../../schieber_vishkin_lca_oracle.py` | Present; source-shaped S–V reference |
| `../../schieber_vishkin_lca_independent_oracle.py` | Present; independent BFS plus binary lifting |
| `verify_workload.py` | Present; static schema, framing, oracle, port, and provenance checks |
| `INVENTORY.json` | Present; machine-readable source and contract inventory |
| `check_inventory.py` | Present; source-path and metadata check only, with no port execution |
| Suite runner, shared verifier, root README/CATALOG integration | Integrated; execution remains intentionally unrun |

Maximum valid input: 2,562 i64 words. Maximum output: 1,024 bytes. Logical
scratch cap: 32,768 bytes including staged answers and excluding caller
buffers. No programs, scripts, checks, tests, compilers, or benchmarks have
been run for this package.
