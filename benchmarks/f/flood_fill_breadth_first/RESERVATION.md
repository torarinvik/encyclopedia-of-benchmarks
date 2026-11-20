# Reservation: breadth-first flood fill

**Status:** Ten source ports, two independent references, workload, rights note, inventory, and package-local checker are present. Central suite registration remains for parent integration. Ports remain uncompiled and unexecuted by design.

## Contract

Use the `i64_array_bytes_output` ABI. Input is `[width,height,start_x,start_y,new_color,target_color,pixels...]`, with dimensions 1..32, x-major signed-i32 pixel values, an in-bounds seed, exact frame length, and distinct new and target colors. Replace the seed's eight-connected target-color component and return the full image as little-endian i64 words. Invalid input returns `-1`; null or short output returns `-2`.

The primary traversal is FIFO breadth-first search over implicit image neighbors. Cells are recolored before enqueue so each is queued once. The kernel is O(width × height) time and O(width × height) auxiliary space, with at most 1024 queue entries. The independent oracle expands a separate boolean component mask through repeated full-grid scans. A 4×4 uniform image covers a broad frontier; a 1×32 uniform image covers a long narrow region.

## Provenance and distinction

The method lead is the [Algorithm Archive flood-fill page](https://www.algorithm-archive.org/contents/flood_fill/flood_fill.html), cross-checked with the pinned [TheAlgorithms/C-Sharp implementation](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/FloodFill.cs). The existing flood-fill package uses a LIFO stack, while this package pins a FIFO queue schedule. Explicit-graph breadth-first search visits supplied graph edges; this kernel discovers and recolors a component in an implicit eight-neighbor grid.

The source ports, reference methods, contract, and fixtures are clean-room work. No source code, prose, tests, examples, or fixture outputs were copied.
