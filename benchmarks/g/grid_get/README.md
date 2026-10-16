# Grid Get

This benchmark ports the two exports in the pinned JavaScript
[`Maths/GridGet.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/GridGet.js):
`gridGetX(columns, index)` and `gridGetY(columns, index)`. They convert a
zero-based linear index into one-based column and row coordinates.

## Contract

- Input uses the signed i64 array-to-scalar ABI as `[operation, columns, index]`.
  Operation `0` selects `gridGetX`; operation `1` selects `gridGetY`.
- `columns` is in `[1, 1,000]` and `index` is in `[0, 10,000]`. The limits
  keep the source's repeated-subtraction X loop bounded to at most 10,000
  iterations. The parser accepts four packed values so an extra-value fixture
  can reach the algorithm; valid input is exactly three values.
- X preserves the source loop: while `index + 1 > columns`, subtract `columns`,
  then return `index + 1` from the reduced value. This is mathematically
  equivalent to `index % columns + 1` on the bounded domain, but the ports keep
  the repeated-subtraction work. The maximum-index, one-column fixture exercises
  its 10,000-iteration bound. It gives 1 at index 0 and at index `columns`, and
  2 at index `columns + 1`. Y is one-based: `floor(index / columns) + 1`.
- Invalid operations, columns, indices, lengths, and null input return `-1`.

This is distinct from `index_2d_array_in_1d`, which converts row/column
coordinates in the opposite direction.

## Pinned source

JavaScript [`Maths/GridGet.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/GridGet.js)
at commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/grid_get.c`](../../../c/g/grid_get.c) |
| C3 | [`c3/g/grid_get.c3`](../../../c3/g/grid_get.c3) |
| C++ | [`cpp/g/grid_get.cpp`](../../../cpp/g/grid_get.cpp) |
| Elisa | [`elisa/g/grid_get.elisa`](../../../elisa/g/grid_get.elisa) |
| Nim | [`nim/g/grid_get.nim`](../../../nim/g/grid_get.nim) |
| Odin | [`odin/g/grid_get.odin`](../../../odin/g/grid_get.odin) |
| Rust | [`rust/g/grid_get.rs`](../../../rust/g/grid_get.rs) |
| V | [`v/g/grid_get.v`](../../../v/g/grid_get.v) |
| Zig | [`zig/g/grid_get.zig`](../../../zig/g/grid_get.zig) |

The workload is [`workload.json`](workload.json), and the independent oracle is
[`grid_get_oracle.py`](../../grid_get_oracle.py).
