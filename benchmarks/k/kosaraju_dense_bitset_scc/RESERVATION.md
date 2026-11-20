# Reservation: dense bit-parallel Kosaraju SCC

**Status:** Ten language ports, packed-Kosaraju and independent Tarjan references, bounded fixtures, documentation, and byte-output runner/verifier registration are present. Ports remain uncompiled and unexecuted by design.

- Owner: `/root/roscode_title_audit` (package implementation); `/root` (suite and root-catalog integration).
- Candidate: `kosaraju_dense_bitset_scc`, discovered from Library Checker proposal #1373.
- Distinctness: this retains Kosaraju's two-pass SCC decomposition, but targets packed dense adjacency rows and discovers neighbors from `unvisited & row` a machine word at a time. The local `kosaraju` package stores rows in bitmasks but scans every possible neighbor index in each DFS, and accepts an edge-list input. This reservation is for that representation-specific traversal workload, not a second generic SCC method.
- Contract: `i64_array_bytes_output`; input `[n, row_words...]`, `1 <= n <= 256`, each row has `ceil(n/64)` signed i64 words in row-major order, bits are interpreted unsigned, and unused high bits must be zero. Self-loops are allowed. Output is a little-endian u16 component count followed by one little-endian u16 component ID per vertex; IDs are canonicalized by ascending minimum vertex. Malformed/null input returns `-1`; null/short output returns `-2`.
- Bounds: maximum valid input length 1025 words, one-extra-word parse bound 1026, maximum output 514 bytes, 32768 bytes of scratch storage. The packed primary constructs a transpose by set-bit enumeration and performs iterative two-pass DFS by intersecting row words with the unvisited mask. State the honest total complexity as `O(V*ceil(V/64) + E)` time and `O(V*ceil(V/64))` bit storage.
- Independent reference: Tarjan SCC using adjacency lists, then canonicalize labels by component minimum. Cited community code is an idea index only.
- No source code, problem statement, tests, or fixtures are reused. No project execution is permitted while compiler profiling is underway.
