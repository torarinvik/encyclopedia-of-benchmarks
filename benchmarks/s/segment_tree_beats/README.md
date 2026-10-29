# Segment Tree Beats

This benchmark handles range chmin, range chmax, range addition, and range-sum queries with a segment tree beats data structure. Every language port is a clean implementation of the algorithm; source code and judge statements were not copied.

## Contract

- Input is a signed 64-bit array packed as `[n, initial_values..., q, (opcode, left, right, argument)*]`.
- `n` is 1 through 64 and `q` is 0 through 128. Initial values and update arguments are in `[-1,000,000, 1,000,000]`.
- Every range is zero-based, half-open, and nonempty: `0 <= left < right <= n`.
- Opcode `0` applies `a[i] = min(a[i], argument)` over the range. Opcode `1` applies `a[i] = max(a[i], argument)`. Opcode `2` adds `argument`. Opcode `3` returns the range sum and requires `argument == 0`.
- The result is the sum, in query order, of `query_ordinal * (range_sum + 8,256,000,001)`. It is zero when there are no queries. Under the input bounds, the offset makes each query term positive and the checksum fits in signed 64-bit arithmetic; valid input cannot produce the invalid-input sentinel `-1`.
- Malformed lengths, opcodes, ranges, values, or a nonzero query argument return `-1`. The largest packed input has `2 + 64 + 4 * 128 = 578` values.

## Algorithm and complexity

Each node stores its sum, largest and second-largest values with the count of the largest, smallest and second-smallest values with the count of the smallest, plus a pending range addition. A chmin or chmax can update a fully covered node directly when its threshold lies strictly between the first and second extreme; otherwise the operation descends and recomputes the node. Range additions propagate lazily, and a sum query pushes pending constraints only along intersecting paths.

The combined update profile has amortized `O((n + q) log² n)` time and `O(n)` space. The oracle uses a plain array and visits every affected element, independently of the tree structure.

## Workload and provenance

[`workload.json`](workload.json) includes mixed clamp/add/query traces, a single-element trace, a no-query trace, and malformed inputs. The operation profile follows the [Library Checker Range Chmin Chmax Add Range Sum problem](https://judge.yosupo.jp/problem/range_chmin_chmax_add_range_sum), used as an algorithm reference only. Implementations were written independently; no submissions or problem text were reused.

The package-local [`oracle`](../../segment_tree_beats_oracle.py) evaluates each update by direct element-wise modification. [`verifier helpers`](../../segment_tree_beats_verifier.py) compare workload results against that independent oracle. Compilation, runtime checks, and benchmark validation have not been performed; shared suite integration remains pending.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/segment_tree_beats.c](../../../c/s/segment_tree_beats.c) |
| C3 | [c3/s/segment_tree_beats.c3](../../../c3/s/segment_tree_beats.c3) |
| C++ | [cpp/s/segment_tree_beats.cpp](../../../cpp/s/segment_tree_beats.cpp) |
| Elisa | [elisa/s/segment_tree_beats.elisa](../../../elisa/s/segment_tree_beats.elisa) |
| Nim | [nim/s/segment_tree_beats.nim](../../../nim/s/segment_tree_beats.nim) |
| Odin | [odin/s/segment_tree_beats.odin](../../../odin/s/segment_tree_beats.odin) |
| Rust | [rust/s/segment_tree_beats.rs](../../../rust/s/segment_tree_beats.rs) |
| V | [v/s/segment_tree_beats.v](../../../v/s/segment_tree_beats.v) |
| Zig | [zig/s/segment_tree_beats.zig](../../../zig/s/segment_tree_beats.zig) |
