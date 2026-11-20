# Package inventory

- Contract: i64_array_scalar; input [rows, cols, budget, row-major binary cells].
- Valid input: dimensions 1..6, budget 0..6, free endpoints, exact frame.
- Maximum valid/parseable lengths: 39/40 i64 words.
- Result: shortest four-neighbor move count, -1 unreachable, -2 malformed/null.
- Maximum product graph: 252 states; workspace cap: 8,192 bytes.
- Primary reference: FIFO BFS over (cell, remaining budget).
- Independent reference: repeated edge relaxation over product states.
- Complexity: primary O(S+E) time/O(S) space; independent O(S*(S+E)) time/O(S+E) space.
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: LeetCode title discovery and CP-Algorithms BFS method reference;
  clean-room code and fixtures, as recorded in RIGHTS.md.
