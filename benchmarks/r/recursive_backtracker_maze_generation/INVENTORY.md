# Package inventory

- Contract: `i64_array_bytes_output`; input `[rows, cols, start_cell, draw_count, neighbor ordinals...]`.
- Valid bounds: 1..64 rows/columns, at most 64 cells, exactly cells-1 choices.
- Neighbor order: north, east, south, west; choices are validated against the live unvisited-neighbor list.
- Maximum valid/parseable input lengths: 67/68 i64 words.
- Output: one row-major wall nibble per cell; maximum output 64 bytes.
- Errors: -1 malformed input or dynamic choice; -2 null/short output, without writes.
- Primary reference: iterative DFS stack writing reciprocal wall masks.
- Independent reference: recursive DFS recording passages, followed by a separate wall-mask construction pass.
- Complexity: both O(rows*columns) time and space under the supplied tape.
- Fixed arrays use 704 bytes on a 64-bit target; the workspace cap is 1,024 bytes with allowance for scalar/index state and alignment, excluding caller input/output.
- Native ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Provenance: RosettaGit discovery page and independent algorithm references; no task code or fixture text copied.
