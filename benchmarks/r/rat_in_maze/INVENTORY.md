# Static inventory

- Contract, source pins, complexity, and language links: `README.md`.
- License review and clean-room scope: `RIGHTS.md`.
- Bounded fixtures and suite metadata: `workload.json`.
- Maximum fixed-array workspace: 1,024 bytes; recursive control frames have
  an `O(V)` depth bound and are described separately in the contract.
- Python/Rust variant oracle: `benchmarks/rat_in_maze_oracle.py`.
- Byte-output runner and verifier registration: `benchmarks/run_i64_array_bytes_output.py` and `benchmarks/verify_i64_array_bytes_output.py`.
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.

The package intentionally combines two source variants of the same DFS
backtracking method. Their move ordering, cell encoding, destination rules,
and output conventions are retained as input-selected variants of one
benchmark rather than duplicated as separate algorithm entries.

No programs, tests, checkers, builds, compilers, profilers, or benchmarks were
run for this inventory update.
