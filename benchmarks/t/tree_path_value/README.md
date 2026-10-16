# Tree path value

## Contract

This package captures the Go `Problem18(input []string, deep int)` routine from the pinned source. Each input token is parsed as an integer, then inserted breadth-first into a triangle-shaped directed acyclic graph: the values are row-major, and each node at row `r`, column `c` can reach row `r+1`, columns `c` and `c+1`. The packed ABI input is `[deep, value_0, ..., value_n]`; `[deep]` represents an empty triangle.

The source search explores `deep` edges at a time from its current pivot. It pushes right before left onto a LIFO stack, so endpoints are visited left-first; a pivot changes only when a path sum is strictly greater than the accumulated maximum. It repeats from the chosen pivot until that pivot has no left child. This source behavior is a chunked greedy path search and is distinct from Project Euler 18's maximum root-to-bottom triangle sum.

To keep the source loop finite and sums bounded, the adapter accepts `deep` in `1..=14`, up to 120 values, a root in `-1000..=1000`, and descendants in `1..=1000`. Zero or negative descendants are excluded because the source's strict-improvement pivot loop can fail to make progress for those inputs. Out-of-domain input returns `-1`.

## Workload

[`workload.json`](workload.json) includes the Go source's four-row example (23 at `deep=2`), distinct one-step and two-step greedy choices, negative-root input, the pinned 120-value dataset (1074 at `deep=2`), the maximum node/depth boundary, and invalid values.

## TheAlgorithms reference

- Go [`Problem18`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_18/problem18.go) builds a tree from integer strings and calls `MaxPathValueSearch(deep)`. See its [tree search](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_18/tree.go) and [node insertion](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/project_euler/problem_18/edge.go).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/t/tree_path_value.c](../../../c/t/tree_path_value.c) |
| C3 | [c3/t/tree_path_value.c3](../../../c3/t/tree_path_value.c3) |
| C++ | [cpp/t/tree_path_value.cpp](../../../cpp/t/tree_path_value.cpp) |
| Elisa | [elisa/t/tree_path_value.elisa](../../../elisa/t/tree_path_value.elisa) |
| Nim | [nim/t/tree_path_value.nim](../../../nim/t/tree_path_value.nim) |
| Odin | [odin/t/tree_path_value.odin](../../../odin/t/tree_path_value.odin) |
| Rust | [rust/t/tree_path_value.rs](../../../rust/t/tree_path_value.rs) |
| V | [v/t/tree_path_value.v](../../../v/t/tree_path_value.v) |
| Zig | [zig/t/tree_path_value.zig](../../../zig/t/tree_path_value.zig) |
