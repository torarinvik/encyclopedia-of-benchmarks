# LLUBenchmark list traversal and growth

`llubenchmark_list_traversal_growth` is a bounded, clean-room profile of the standalone LLUBenchmark from the pinned LAC-DCC suite. Each pass traverses every list in order, adds each node's current count to an accumulator, increments that count, then applies the source's fractional growth rule to append nodes at each list's tail.

## Contract

The exported symbol is `llubenchmark_list_traversal_growth` and uses the `i64_array_bytes_output` ABI.

- Input: `[num_lists, initial_length, iterations]`.
- `num_lists` and `initial_length` are in `1..4`; `iterations` is in `0..16`; input length is exactly 3.
- The profile fixes the source defaults `growth_rate=0.333`, dirty-node traversal enabled, and tail insertion enabled.
- Initial lists contain `initial_length` zero-count nodes each. The source inserts initial nodes at the head; since their initial counts are all zero, this profile preserves that topology and order.
- For each pass, visit lists in ascending list index and follow each `next` link from head to tail. Add the current count to the signed accumulator, then increment it.
- After traversal, add 333 thousandths to the fractional growth state. Its whole part determines how many nodes to append per list; each new node receives the source count `list_index + insertion_ordinal`. The bounded profile never appends more than one node per list in a pass.
- Output is two little-endian signed i64 values: `[accumulate, num_allocated]`, matching the source's final counters. Success returns 2. Invalid input returns `-1`; null output or capacity below 16 returns `-2` without writes.
- The maximum profile creates 36 nodes and produces an accumulator no greater than 2736.

The index-linked node pool preserves the source's per-list links, ascending traversals, count mutations, fractional growth schedule, and tail appends. It replaces dynamic allocation and allocator/cache behavior with bounded portable storage. The benchmark's CLI parsing, periodic progress printing, timing, and process-wide allocation behavior are outside this profile.

The independent oracle uses a separately written index-linked model. The workload includes a hand-derived growth event at iteration four, a second fractional growth event, zero-iteration behavior, malformed dimensions, null pointers, and insufficient output capacity.

## Source and rights

The pinned source is [`llubenchmark/llubenchmark.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/llubenchmark/llubenchmark.c) in LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; the launcher is [`llubenchmark/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/llubenchmark/info.sh). The source header attributes the benchmark to Craig Zilles and describes linked-list traversal with optional extension. No explicit license grant was found in the pinned source or repository material reviewed. These ports are clean-room implementations and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/llubenchmark_list_traversal_growth_oracle.py`](../../llubenchmark_list_traversal_growth_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`llubenchmark_list_traversal_growth.c`](../../../c/l/llubenchmark_list_traversal_growth.c) |
| C3 | [`llubenchmark_list_traversal_growth.c3`](../../../c3/l/llubenchmark_list_traversal_growth.c3) |
| C++ | [`llubenchmark_list_traversal_growth.cpp`](../../../cpp/l/llubenchmark_list_traversal_growth.cpp) |
| Elisa | [`llubenchmark_list_traversal_growth.elisa`](../../../elisa/l/llubenchmark_list_traversal_growth.elisa) |
| Nim | [`llubenchmark_list_traversal_growth.nim`](../../../nim/l/llubenchmark_list_traversal_growth.nim) |
| Odin | [`llubenchmark_list_traversal_growth.odin`](../../../odin/l/llubenchmark_list_traversal_growth.odin) |
| Rust | [`llubenchmark_list_traversal_growth.rs`](../../../rust/l/llubenchmark_list_traversal_growth.rs) |
| V | [`llubenchmark_list_traversal_growth.v`](../../../v/l/llubenchmark_list_traversal_growth.v) |
| Zig | [`llubenchmark_list_traversal_growth.zig`](../../../zig/l/llubenchmark_list_traversal_growth.zig) |
