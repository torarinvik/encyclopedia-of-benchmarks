# Morton sort

Morton sort orders two-dimensional integer points by their Morton (Z-order) code. The code interleaves the x and y coordinate bits, starting with x in bit 0 and y in bit 1. Points with equal codes retain input order. The result is the sequence of original point indices, so duplicate points are observable and deterministic.

## Contract

The `i64_array_bytes_output` ABI packs `[n, x0, y0, ..., x(n-1), y(n-1)]`. It accepts 1 through 256 points and coordinates in `[0, 65535]`. The output contains `n` original point indices as little-endian signed 64-bit integers. Malformed input returns `-1`; a null or undersized output buffer returns `-2`; success returns `8*n`.

Each port computes the 32-bit interleaved Morton code and orders point indices by `(code, original_index)`. The bound keeps the workload small while exercising bit spreading and ordering across all coordinate bits.

## Source and attribution

This is an independent implementation of the Morton ordering workload listed by [ParGeo](https://github.com/ParAlg/ParGeo), a MIT-licensed parallel geometry library. No ParGeo implementation code is copied.

The independent oracle is [`morton_sort_oracle.py`](../../morton_sort_oracle.py).

| Language | Source |
| --- | --- |
| C | [`c/m/morton_sort.c`](../../../c/m/morton_sort.c) |
| C3 | [`c3/m/morton_sort.c3`](../../../c3/m/morton_sort.c3) |
| C++ | [`cpp/m/morton_sort.cpp`](../../../cpp/m/morton_sort.cpp) |
| Elisa | [`elisa/m/morton_sort.elisa`](../../../elisa/m/morton_sort.elisa) |
| Nim | [`nim/m/morton_sort.nim`](../../../nim/m/morton_sort.nim) |
| Odin | [`odin/m/morton_sort.odin`](../../../odin/m/morton_sort.odin) |
| Rust | [`rust/m/morton_sort.rs`](../../../rust/m/morton_sort.rs) |
| V | [`v/m/morton_sort.v`](../../../v/m/morton_sort.v) |
| Zig | [`zig/m/morton_sort.zig`](../../../zig/m/morton_sort.zig) |
