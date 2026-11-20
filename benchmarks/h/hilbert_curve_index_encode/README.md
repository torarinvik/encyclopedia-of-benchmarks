# Hilbert curve coordinate-to-index mapping

This benchmark maps one point in a bounded integer grid to its position on a
discrete Hilbert traversal. It follows the iterative coordinate-to-distance
algorithm introduced by A. R. Butz. The existing
[`hilbert_curve`](../hilbert_curve/README.md) emits every point in a rotated
recursive curve; this package returns one point's scalar index. It is also
distinct from [`morton_sort`](../morton_sort/README.md), which uses bit
interleaving to order point sets by Z-order.

## Contract

The `i64_array_bytes_output` input is `[order,x,y]`, with `1<=order<=8` and
`0<=x,y<2^order`. The canonical order-one traversal is
`(0,0),(0,1),(1,1),(1,0)`. Success writes one little-endian signed-i64 word
containing the Hilbert index and returns 8. Malformed input returns `-1`; a
null or short output buffer returns `-2` without writing.

The primary walks coordinate bits from most significant to least significant.
Each bit pair selects a quadrant digit and transforms the remaining lower bits
to match that quadrant's orientation. It runs in `O(order)` time and uses
`O(1)` scratch. The independent reference recursively selects a quadrant,
transforms its child coordinates, and adds the preceding quadrant blocks; it
uses `O(order)` stack space.

The algorithm description is from Butz, [“Alternative Algorithm for
Hilbert's Space-Filling Curve”](https://doi.org/10.1109/T-C.1971.223258),
*IEEE Transactions on Computers* 20(4), 1971, pp. 424–426. Only the
mathematical method is used; code, text, examples, and tests were written
independently. See [RIGHTS.md](RIGHTS.md).

| Language | Source |
|---|---|
| C | [hilbert_curve_index_encode.c](../../../c/h/hilbert_curve_index_encode.c) |
| C3 | [hilbert_curve_index_encode.c3](../../../c3/h/hilbert_curve_index_encode.c3) |
| C++ | [hilbert_curve_index_encode.cpp](../../../cpp/h/hilbert_curve_index_encode.cpp) |
| Elisa | [hilbert_curve_index_encode.elisa](../../../elisa/h/hilbert_curve_index_encode.elisa) |
| Mojo | [hilbert_curve_index_encode.mojo](../../../mojo/h/hilbert_curve_index_encode.mojo) |
| Nim | [hilbert_curve_index_encode.nim](../../../nim/h/hilbert_curve_index_encode.nim) |
| Odin | [hilbert_curve_index_encode.odin](../../../odin/h/hilbert_curve_index_encode.odin) |
| Rust | [hilbert_curve_index_encode.rs](../../../rust/h/hilbert_curve_index_encode.rs) |
| V | [hilbert_curve_index_encode.v](../../../v/h/hilbert_curve_index_encode.v) |
| Zig | [hilbert_curve_index_encode.zig](../../../zig/h/hilbert_curve_index_encode.zig) |

The workload, references, package inventory, and byte-output suite registration
are maintained with this package.
