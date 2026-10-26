# Color-coded k-path detection

This package isolates the subset/endpoint dynamic program for finding a colorful path described in the chapter “Color Coding,” *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_76](https://doi.org/10.1007/978-1-4939-2864-4_76)). A path is colorful when all its vertices have different colors. The dynamic-programming state records whether a path with color set `S` can end at a given vertex; transitions extend across an edge to a vertex whose color is not yet in `S`.

## Contract

The `i64_array_bytes_output` frame is `[n,m,k,colors[n],edges[2*m]]`. Graphs are simple undirected graphs with `1 <= n <= 12`, `0 <= m <= 66`, `1 <= k <= min(6,n)`, vertex colors in `[0,k)`, and edges given as zero-based endpoint pairs. Duplicate edges, loops, invalid endpoints, and malformed lengths are rejected. The supplied coloring is a deterministic profile input: random color assignment, repetition over independent colorings, and derandomization are outside scope.

The output is one little-endian signed-i64 Boolean: 1 if there is a simple path containing exactly `k` vertices with pairwise distinct colors, otherwise 0. The function returns 8, `-1` for malformed input, and `-2` for null or short output. Validation precedes capacity checks and output is written only on success.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/color_coding_k_path.c`](../../../c/c/color_coding_k_path.c) |
| C3 | [`c3/c/color_coding_k_path.c3`](../../../c3/c/color_coding_k_path.c3) |
| C++ | [`cpp/c/color_coding_k_path.cpp`](../../../cpp/c/color_coding_k_path.cpp) |
| Elisa | [`elisa/c/color_coding_k_path.elisa`](../../../elisa/c/color_coding_k_path.elisa) |
| Nim | [`nim/c/color_coding_k_path.nim`](../../../nim/c/color_coding_k_path.nim) |
| Odin | [`odin/c/color_coding_k_path.odin`](../../../odin/c/color_coding_k_path.odin) |
| Rust | [`rust/c/color_coding_k_path.rs`](../../../rust/c/color_coding_k_path.rs) |
| V | [`v/c/color_coding_k_path.v`](../../../v/c/color_coding_k_path.v) |
| Zig | [`zig/c/color_coding_k_path.zig`](../../../zig/c/color_coding_k_path.zig) |

The primary oracle is [`color_coding_k_path_oracle.py`](../../color_coding_k_path_oracle.py); the verifier checks paths by bounded DFS in [`color_coding_k_path_verifier_oracle.py`](../../color_coding_k_path_verifier_oracle.py).

## Attribution and rights

The method is attributed to the “Color Coding” chapter, *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_76. The Springer chapter is used only to identify the method. No book prose, figures, or code are reproduced; all ports are independently written. This attribution does not grant rights to redistribute the book.
