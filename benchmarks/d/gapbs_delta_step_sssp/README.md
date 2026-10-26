# GAPBS delta-stepping SSSP

This package implements a bounded single-worker profile of GAPBS's `DeltaStep` single-source shortest-path kernel. It computes the full distance vector using distance buckets of width `delta`. The repository already contains Dijkstra, Bellman–Ford, Johnson, bidirectional Dijkstra, and FIFO label-correcting profiles; this package preserves GAPBS's distinct δ-stepping bucket order and same-bucket relaxation.

## Contract

- The exported function is `gapbs_delta_step_sssp` and uses the `i64_array_bytes_output` ABI.
- Input is `[n, m, source, delta, (from, to, weight)...]`, with `1 <= n <= 16`, `0 <= m <= 64`, `0 <= source < n`, and `1 <= delta <= 16`.
- Each directed edge has endpoints in `0..n-1` and a nonnegative weight in `0..32`. Parallel edges and self-loops are allowed. The packed input length must equal `4 + 3*m`.
- Output contains one signed i64 distance per vertex in ascending vertex order, encoded little-endian. Unreachable vertices use `1,073,741,823`, matching GAPBS's `INT32_MAX/2` sentinel. Success returns `8*n`; malformed input returns `-1`; a null output or capacity below `8*n` returns `-2` without writing.
- With at most 16 vertices and weights at most 32, a finite shortest path is at most 480. Since an accepted distance update is a strict decrease among integer values from 0 through 480, there can be at most 481 successful updates per vertex. Together with the initial source entry, this bounds the queue below 7,697 entries; the ports reserve 8,192. The maximum bucket index is 480 when `delta=1`.

The profile uses GAPBS's relaxation rule: a strict distance improvement queues the vertex in `floor(distance/delta)`, and an entry is ignored when its current distance is below `delta*bucket`. The bounded implementation is deterministic and single-worker: it drains the current bucket, including entries added to that bucket during relaxation, before advancing to the next nonempty bucket. This preserves the source's same-priority bucket fusion result while leaving out OpenMP scheduling, atomics, timers, logging, and the parallel 1000-entry fusion threshold. Edge weights and distances are bounded projections of source `WeightT` (`int32_t`); output widening to i64 is the suite ABI encoding.

## Source and rights

Behavior reference: [`src/sssp.cc::RelaxEdges` and `DeltaStep`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/sssp.cc), pinned to commit `b5e3e19c2845f22fb338f4a4bc4b1ccee861d026`. The source type is `WeightT = int32_t` in [`src/benchmark.h`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/src/benchmark.h). The pinned repository's [`LICENSE`](https://github.com/sbeamer/gapbs/blob/b5e3e19c2845f22fb338f4a4bc4b1ccee861d026/LICENSE) is BSD-3-Clause. These ports were independently written and do not copy upstream code or comments. The full source rights notice is included in [`LICENSE.txt`](LICENSE.txt).

The independent oracle uses Bellman–Ford relaxation rather than delta buckets. [`workload.json`](workload.json) covers same-bucket closure, stale entries, bucket boundaries, zero-weight cycles, parallel edges, unreachable vertices, maximum-size output, and malformed inputs. The oracle is [`gapbs_delta_step_sssp_oracle.py`](../../gapbs_delta_step_sssp_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/gapbs_delta_step_sssp.c`](../../../c/d/gapbs_delta_step_sssp.c) |
| C3 | [`c3/d/gapbs_delta_step_sssp.c3`](../../../c3/d/gapbs_delta_step_sssp.c3) |
| C++ | [`cpp/d/gapbs_delta_step_sssp.cpp`](../../../cpp/d/gapbs_delta_step_sssp.cpp) |
| Elisa | [`elisa/d/gapbs_delta_step_sssp.elisa`](../../../elisa/d/gapbs_delta_step_sssp.elisa) |
| Nim | [`nim/d/gapbs_delta_step_sssp.nim`](../../../nim/d/gapbs_delta_step_sssp.nim) |
| Odin | [`odin/d/gapbs_delta_step_sssp.odin`](../../../odin/d/gapbs_delta_step_sssp.odin) |
| Rust | [`rust/d/gapbs_delta_step_sssp.rs`](../../../rust/d/gapbs_delta_step_sssp.rs) |
| V | [`v/d/gapbs_delta_step_sssp.v`](../../../v/d/gapbs_delta_step_sssp.v) |
| Zig | [`zig/d/gapbs_delta_step_sssp.zig`](../../../zig/d/gapbs_delta_step_sssp.zig) |
