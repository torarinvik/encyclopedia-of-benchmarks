# Graph m-Coloring by Backtracking

This benchmark follows TheAlgorithms/Python's `color()` routine: visit vertices in order, try colors from zero upward, and return the first complete assignment found by depth-first backtracking. It measures the bounded decision-and-first-solution search, not enumeration of every valid coloring.

## Contract

- Input is `[vertex_count, max_colors, adjacency_matrix...]`; the matrix is row-major and has exactly `vertex_count * vertex_count` entries.
- `vertex_count` and `max_colors` are each in `0..=12`. Matrix entries are 0 or 1, the matrix is symmetric, and its diagonal is zero.
- A successful call returns `vertex_count` signed 64-bit colors in ascending vertex order, with colors numbered from zero. If no assignment exists, the source returns an empty list and the benchmark returns zero bytes. The empty graph also returns zero bytes, matching the source's empty list.
- Invalid input returns `-1`; a successful nonempty result with insufficient output capacity returns `-2`. No architecture-specific instructions are used.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm graph_m_coloring_backtracking --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/g/graph_m_coloring_backtracking/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/graph_m_coloring_backtracking.c`](../../../c/g/graph_m_coloring_backtracking.c) |
| C3 | [`c3/g/graph_m_coloring_backtracking.c3`](../../../c3/g/graph_m_coloring_backtracking.c3) |
| C++ | [`cpp/g/graph_m_coloring_backtracking.cpp`](../../../cpp/g/graph_m_coloring_backtracking.cpp) |
| Elisa | [`elisa/g/graph_m_coloring_backtracking.elisa`](../../../elisa/g/graph_m_coloring_backtracking.elisa) |
| Nim | [`nim/g/graph_m_coloring_backtracking.nim`](../../../nim/g/graph_m_coloring_backtracking.nim) |
| Odin | [`odin/g/graph_m_coloring_backtracking.odin`](../../../odin/g/graph_m_coloring_backtracking.odin) |
| Rust | [`rust/g/graph_m_coloring_backtracking.rs`](../../../rust/g/graph_m_coloring_backtracking.rs) |
| V | [`v/g/graph_m_coloring_backtracking.v`](../../../v/g/graph_m_coloring_backtracking.v) |
| Zig | [`zig/g/graph_m_coloring_backtracking.zig`](../../../zig/g/graph_m_coloring_backtracking.zig) |

## Pinned source

- Python [`coloring.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/coloring.py)
