# Go topological traversal

This benchmark preserves the behavior of TheAlgorithms/Go's Topological
function and its DepthFirstSearchHelper. The source describes its input as a
directed acyclic graph, but its stack traversal is not a correct topological
sort for every DAG and it has no cycle detection. It can return an order that
violates an edge, omit a cycle-only component, or repeat a vertex reached
through a self-loop. Those outputs are part of this source-specific contract.

## Contract

- Input is a signed 64-bit array encoded as [vertex_count, source_0, destination_0, ...].
- The benchmark accepts 0–64 vertices and at most 32 edge entries, matching the shared 66-value array-output ABI. Every endpoint must be in 0..vertex_count-1.
- The source increments a destination's dependency count for every edge entry, including duplicates, while its boolean adjacency matrix coalesces duplicate edges.
- Root vertices are processed in ascending ID order when their dependency count is zero. For each root, the helper starts a LIFO stack. It appends each popped vertex to that root's route, scans destinations in ascending order, pushes an outgoing neighbor only if it is not already pending, then clears both matrix directions for that pair.
- The helper is called with end == vertex_count, which is outside the valid vertex IDs. It therefore drains the stack and returns the full route. Routes from separate roots are concatenated.
- The return value is the number of output bytes; each output byte is one vertex ID. A well-formed input can return fewer or more than vertex_count entries. The maximum under these bounds is 96 bytes.
- Malformed packed input, an out-of-range endpoint, or insufficient output capacity returns -2 and writes no output. The source would panic on malformed endpoints; this is benchmark ABI normalization.

The workload includes a branching DAG that produces a non-topological order, a
cycle-only component that is omitted, and a reachable self-loop that repeats
its vertex. Cycles are included to record the source's observable behavior
even though its comments say callers should provide a DAG.

## Pinned source

- Go Topological: https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/topological.go
- Go DepthFirstSearchHelper: https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/depthfirstsearch.go

All nine ports use the i64_array_bytes_output ABI. Build and record with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm topological --language rust
    python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/t/topological/rust/build.json
