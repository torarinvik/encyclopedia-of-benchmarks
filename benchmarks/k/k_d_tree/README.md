# K-d tree nearest neighbor (Lua)

This benchmark preserves the pinned Lua k-d tree's default median-of-medians build and nearest-neighbor query. It takes a point cloud and query, builds a new tree for each call, and returns the Euclidean distance followed by the nearest point coordinates. The separate insertion method is excluded because it randomly chooses a side when a point ties a split coordinate.

## Contract

The `float64_slice_io` input is `[dimension, point_count, query[dimension], point_0[dimension], ...]`. Dimension is 2 or 3, point count is 1 through 15, and the exact input length is `2 + dimension * (point_count + 1)`. Every input must be finite; dimension and count must be exact integers, and every coordinate must be an integer in `[-1000, 1000]`.

To make the pinned strict coordinate comparator deterministic, each point must have a distinct coordinate on each axis. The nearest point must also be unique by Euclidean distance. Invalid inputs return `-1`; a null or undersized output buffer returns `-2`. Input validation, including the unique-nearest check, happens before output-buffer checks. Neither error changes any output element.

The default constructor uses the pinned median-of-medians quickselect to select the one-based rank `ceil(subtree_size / 2)` on the current axis. The selection groups values in fives, selects a median-of-medians pivot recursively, and partitions the active slice into values below, equal to, and above the pivot. Smaller coordinate values form the left subtree and larger values form the right subtree. Axes cycle from the first coordinate. During search, the query follows the left child when its coordinate is less than or equal to the pivot coordinate; the near child is searched first; a strictly shorter Euclidean distance replaces the current result; and the far child is searched when the current best distance is greater than or equal to the absolute distance to the split plane.

Successful output is `[distance, nearest_coordinate_0, ...]`, with `dimension + 1` binary64 values. The shared output workspace is four values. The workload includes output-buffer precedence cases for invalid input with a null output, valid input with a null output, and a short output capacity.

## Workload and build

[`workload.json`](workload.json) and the independent oracle [`k_d_tree_oracle.py`](../../k_d_tree_oracle.py) define the fixtures and tolerances. Build and record with `float64_slice_io`:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm k_d_tree --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm k_d_tree
python3 benchmarks/verify_float64_slice_io.py --algorithm k_d_tree
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/k/k_d_tree.c`](../../../c/k/k_d_tree.c) |
| C3 | [`c3/k/k_d_tree.c3`](../../../c3/k/k_d_tree.c3) |
| C++ | [`cpp/k/k_d_tree.cpp`](../../../cpp/k/k_d_tree.cpp) |
| Elisa | [`elisa/k/k_d_tree.elisa`](../../../elisa/k/k_d_tree.elisa) |
| Nim | [`nim/k/k_d_tree.nim`](../../../nim/k/k_d_tree.nim) |
| Odin | [`odin/k/k_d_tree.odin`](../../../odin/k/k_d_tree.odin) |
| Rust | [`rust/k/k_d_tree.rs`](../../../rust/k/k_d_tree.rs) |
| V | [`v/k/k_d_tree.v`](../../../v/k/k_d_tree.v) |
| Zig | [`zig/k/k_d_tree.zig`](../../../zig/k/k_d_tree.zig) |

## Pinned source

- [TheAlgorithms/Lua `k_d_tree.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/k_d_tree.lua), commit `cedc141018ad48884318fe08a6db278664b17128`.
- Supporting selection code: [`quickselect_median_of_medians.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/quickselect_median_of_medians.lua), [`quickselect.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/quickselect.lua), and [`three_way_partition.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/three_way_partition.lua).
