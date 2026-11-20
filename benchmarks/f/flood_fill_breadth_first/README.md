# Breadth-first flood fill

This benchmark models the bounded eight-connected image replacement described by the Algorithm Archive flood-fill page and the pinned `TheAlgorithms/C-Sharp` implementation. The primary kernel uses a FIFO queue and recolors a matching cell before enqueueing it. The mark-on-enqueue rule ensures that each cell enters the queue at most once.

## Contract

Input is `[width,height,start_x,start_y,new_color,target_color,pixels...]`. Width and height are each 1..32. Pixels use x-major storage at `x * height + y`; all colors are signed 32-bit values carried in signed 64-bit words. The input must contain exactly `6 + width * height` words. The seed coordinates must be in bounds, and `new_color` must differ from `target_color`. Invalid input returns `-1`.

Replace every target-color pixel in the seed's eight-connected component with `new_color`. The seed remains unchanged when it does not match the target. Neighbor checks visit `dx` from -1 through 1, then `dy` from -1 through 1, skipping `(0,0)`. Coordinates beyond the image are ignored; the image does not wrap. Output is the complete x-major image as little-endian signed 64-bit values, and the result is its byte length. Null or insufficient output returns `-2`. The maximum output is 8192 bytes. The primary kernel uses O(width × height) time and O(width × height) queue and image storage; its fixed scratch bound is 16,384 bytes, excluding caller buffers.

## Traversal profile and references

The existing [`flood_fill`](../flood_fill/README.md) package has the same image operation and uses a LIFO stack for depth-first traversal. This package uses FIFO traversal, so it processes cells in nondecreasing distance from the seed and maintains a broad frontier before moving to deeper layers. The queue schedule changes locality, frontier width, and memory traffic while preserving the same final image. The explicit-graph [`breadth_first_search`](../../b/breadth_first_search/README.md) traverses supplied graph edges and records graph visitation/distances; this kernel instead discovers an implicit eight-neighbor image component and replaces its colors.

`primary_oracle.py` mirrors the FIFO kernel. `independent_oracle.py` repeatedly scans the entire image and expands a boolean component mask to closure, then applies the replacement in one pass. The workload includes a broad 4×4 region, an 8-cell narrow corridor, diagonal connectivity, unchanged-seed behavior, and invalid/capacity cases. The two methods and expected byte strings are included for local comparison only; no native source, test, example, or fixture was copied.

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm flood_fill_breadth_first --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm flood_fill_breadth_first
```

## Language ports

| Language | Source |
|---|---|
| C | [flood_fill_breadth_first.c](../../../c/f/flood_fill_breadth_first.c) |
| C3 | [flood_fill_breadth_first.c3](../../../c3/f/flood_fill_breadth_first.c3) |
| C++ | [flood_fill_breadth_first.cpp](../../../cpp/f/flood_fill_breadth_first.cpp) |
| Elisa | [flood_fill_breadth_first.elisa](../../../elisa/f/flood_fill_breadth_first.elisa) |
| Mojo | [flood_fill_breadth_first.mojo](../../../mojo/f/flood_fill_breadth_first.mojo) |
| Nim | [flood_fill_breadth_first.nim](../../../nim/f/flood_fill_breadth_first.nim) |
| Odin | [flood_fill_breadth_first.odin](../../../odin/f/flood_fill_breadth_first.odin) |
| Rust | [flood_fill_breadth_first.rs](../../../rust/f/flood_fill_breadth_first.rs) |
| V | [flood_fill_breadth_first.v](../../../v/f/flood_fill_breadth_first.v) |
| Zig | [flood_fill_breadth_first.zig](../../../zig/f/flood_fill_breadth_first.zig) |

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), and [`INVENTORY.md`](INVENTORY.md). The sources and fixtures are clean-room implementations of the stated algorithm and locally defined contract. No programs, tests, checkers, scripts, builds, compilers, or benchmarks have been run.
