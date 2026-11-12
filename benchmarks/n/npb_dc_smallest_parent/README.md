# NPB DC smallest-parent profile

This package is a bounded profile of the smallest-parent view construction used by the NAS arithmetic data cube (DC) algorithm. It builds the full-dimensional view from the input rows, then constructs each lower-dimensional view from an immediate superset with the fewest groups. Ties choose the lowest added dimension. The empty view is included.

## Contract

The scalar ABI is `int64_t npb_dc_smallest_parent(const int64_t *input, size_t length)`. Input is packed as `[dimension_count, row_count, row_0_attribute_0, ..., row_0_attribute_(d-1), row_0_measure, ...]`. Dimensions are limited to 1 through 5, rows to 1 through 16, attributes to 0 through 7, and measures to 0 through 1000. The exact input length is `2 + row_count * (dimension_count + 1)`. Null, malformed, or out-of-range input returns `-1`.

The full mask is grouped directly from rows. Every other mask is visited in descending popcount order. For a mask, the candidate parents are exactly `mask | (1 << j)` for dimensions `j` not already selected. The parent with the fewest groups is selected; scanning dimensions in ascending order implements the lowest-dimension tie break. Its grouped rows are projected to the target mask and equal keys are merged by summing their measures. The empty mask therefore contains one group for every valid nonempty input.

Groups are lexicographically ordered by selected attribute values, in ascending dimension order. The signed 64-bit checksum visits masks in ascending numeric order and adds, per mask, `(mask+1)*1,000,000 + (parent_mask+2)*10,000 + group_count*1,000`. The full view uses parent sentinel `-1`. For each sorted group at zero-based index `g`, it adds `(g+1)*(measure_sum+1)`, then for every selected dimension `j` adds `(g+1)*(j+1)*(key_j+1)`. All intermediates fit signed 64-bit under the stated bounds. Including the parent code makes the choice visible in the result.

This is distinct from [`npb_serial_dc`](../npb_serial_dc/README.md), which independently groups each nonempty projection from the raw rows. This profile reproduces the smallest-parent dependency between views and includes the empty view. The bounded contract omits the original benchmark's generated input, external parameter file, file-backed view storage, class-specific view schedule, and large problem sizes.

## Complexity

For `d` dimensions and `r` rows, the bounded direct-search implementation takes `O(2^d * r^2 * d)` time: each view groups at most `r` parent groups with linear search and sorts up to `r` projected keys. It stores `O(2^d * r * d)` key data and aggregate sums, plus the input rows and parent metadata.

## Workload and oracles

[`workload.json`](workload.json) covers parent selection where a smaller parent wins, tie-breaking, the empty and full views, maximum dimensions and row count, and invalid input. [`primary_oracle.py`](primary_oracle.py) constructs each child from its selected parent. [`independent_oracle.py`](independent_oracle.py) directly groups raw rows for each mask and independently derives each parent choice from the group counts.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/n/npb_dc_smallest_parent.c`](../../../c/n/npb_dc_smallest_parent.c) |
| C3 | [`c3/n/npb_dc_smallest_parent.c3`](../../../c3/n/npb_dc_smallest_parent.c3) |
| C++ | [`cpp/n/npb_dc_smallest_parent.cpp`](../../../cpp/n/npb_dc_smallest_parent.cpp) |
| Elisa | [`elisa/n/npb_dc_smallest_parent.elisa`](../../../elisa/n/npb_dc_smallest_parent.elisa) |
| Mojo | [`mojo/n/npb_dc_smallest_parent.mojo`](../../../mojo/n/npb_dc_smallest_parent.mojo) |
| Nim | [`nim/n/npb_dc_smallest_parent.nim`](../../../nim/n/npb_dc_smallest_parent.nim) |
| Odin | [`odin/n/npb_dc_smallest_parent.odin`](../../../odin/n/npb_dc_smallest_parent.odin) |
| Rust | [`rust/n/npb_dc_smallest_parent.rs`](../../../rust/n/npb_dc_smallest_parent.rs) |
| V | [`v/n/npb_dc_smallest_parent.v`](../../../v/n/npb_dc_smallest_parent.v) |
| Zig | [`zig/n/npb_dc_smallest_parent.zig`](../../../zig/n/npb_dc_smallest_parent.zig) |

## References

The NASA report describes the arithmetic data cube benchmark and its smallest-parent view computation: [NAS-03-005, *Arithmetic Data Cube as a Data Intensive Benchmark*](https://www.nas.nasa.gov/assets/nas/pdf/techreports/2003/nas-03-005.pdf). The view-lattice algorithmic context is described in Harinarayan, Rajaraman, and Ullman, [*Implementing Data Cubes Efficiently*](https://dsf.berkeley.edu/cs286/papers/datacube-sigmod1996.pdf), SIGMOD 1996. These ports are clean-room bounded implementations and do not copy source code from either publication.

The NAS Parallel Benchmarks are developed by the NASA Advanced Supercomputing Division. The package uses the DC algorithm as a reference and makes no claim that the bounded scalar checksum is the official NPB DC executable or its score.
