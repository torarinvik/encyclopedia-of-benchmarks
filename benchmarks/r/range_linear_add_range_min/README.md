# Range linear add range min

This benchmark applies `a[i] += b*i+c` to half-open ranges and reports the
minimum over queried ranges. The ports use square-root decomposition: complete
blocks keep a lazy slope/intercept pair and a lower convex hull; a minimum query
uses binary search on the block hull, while a partial update materializes and
rebuilds the affected block.

## Contract

Input is `[N, Q, a[N], operations...]`. Bounds are `1 <= N,Q <= 64`, initial
values in `[-1,000,000, 1,000,000]`, update slopes in `[-99,99]`, and update
intercepts in `[-100,000,100,000]`. An update is `[0,l,r,b,c]` and adds
`b*i+c` to every `a[i]` for `i` in `[l,r)`. A query is `[1,l,r]` and returns
the minimum in `[l,r)`. Every operation range is nonempty and within the array.
Malformed, truncated, or trailing input returns `-1`.

For a query at zero-based operation position `j` with minimum `m`, add
`(j+1)*(m+8,000,000)` to the scalar checksum. Updates contribute zero but
advance the operation position. The checksum offset keeps all valid terms
positive. The maximum valid input frame is 386 signed 64-bit values; ports
accept up to 387 values so they can reject a trailing-value frame. The largest
absolute array value is bounded by 7,799,168, and the checksum is below 33
billion.

The block hull stores points `(i,a[i])`. A whole-block update adds a line to
every point, leaving hull orientation unchanged; the lazy pair tracks that
line. For a lazy slope `b`, binary search minimizes `a[i]+b*i` on the lower
hull. Partial updates push the block line to its values, update the intersected
indices, and rebuild its hull. With block width eight, full-block operations
use logarithmic hull search and a partial update rebuilds at most two small
hulls. The independent oracle instead applies each update element by element
and scans each requested range.

## Provenance and rights

The operation semantics and official limits come from Library Checker's
[`range_linear_add_range_min` task](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_linear_add_range_min/task.md)
and [`info.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/range_linear_add_range_min/info.toml).
The ports and oracle are clean-room implementations from the mathematical
contract; no upstream implementation is copied. See [`RIGHTS.md`](RIGHTS.md).

## Workload and oracle

[`workload.json`](workload.json) lists deterministic fixtures and benchmark
metadata. The direct-list oracle is
[`benchmarks/range_linear_add_range_min_oracle.py`](../../range_linear_add_range_min_oracle.py).
The package-local checker statically checks the workload and all ten source
files: [`benchmarks/range_linear_add_range_min_verifier.py`](../../range_linear_add_range_min_verifier.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/range_linear_add_range_min.c`](../../../c/r/range_linear_add_range_min.c) |
| C3 | [`c3/r/range_linear_add_range_min.c3`](../../../c3/r/range_linear_add_range_min.c3) |
| C++ | [`cpp/r/range_linear_add_range_min.cpp`](../../../cpp/r/range_linear_add_range_min.cpp) |
| Elisa | [`elisa/r/range_linear_add_range_min.elisa`](../../../elisa/r/range_linear_add_range_min.elisa) |
| Mojo | [`mojo/r/range_linear_add_range_min.mojo`](../../../mojo/r/range_linear_add_range_min.mojo) |
| Nim | [`nim/r/range_linear_add_range_min.nim`](../../../nim/r/range_linear_add_range_min.nim) |
| Odin | [`odin/r/range_linear_add_range_min.odin`](../../../odin/r/range_linear_add_range_min.odin) |
| Rust | [`rust/r/range_linear_add_range_min.rs`](../../../rust/r/range_linear_add_range_min.rs) |
| V | [`v/r/range_linear_add_range_min.v`](../../../v/r/range_linear_add_range_min.v) |
| Zig | [`zig/r/range_linear_add_range_min.zig`](../../../zig/r/range_linear_add_range_min.zig) |
