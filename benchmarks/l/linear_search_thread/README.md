# Linear search thread worker

## Contract

This benchmark extracts the `Searcher.run()` worker kernel from the pinned Java `LinearSearchThread`. Input is `[n, left, right, target, values...]`: `n` is 1..64, values and target are signed 32-bit integers, and the packed array must contain exactly `n` values. The searched segment is half-open `[left, right)`, with `0 <= left <= right <= n`.

The result is `1` when the target occurs in the segment and `0` otherwise. The worker stops when it finds the first match. An empty segment returns `0`. A null pointer, malformed input, or out-of-range bounds return `-1`.

The package measures the bounded worker search only. It does not include thread creation, scheduling, the original four-segment coordinator, or result consolidation.

## Workload

[`workload.json`](workload.json) includes first and last hits, duplicates, excluded matches at each segment boundary, empty and one-element segments, i32 extremes, a maximum-size segment, malformed lengths, and invalid bounds.

## TheAlgorithms reference

- Java [`LinearSearchThread.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/LinearSearchThread.java) contains the `Searcher.run()` loop and `getResult()` boolean.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/linear_search_thread.c](../../../c/l/linear_search_thread.c) |
| C3 | [c3/l/linear_search_thread.c3](../../../c3/l/linear_search_thread.c3) |
| C++ | [cpp/l/linear_search_thread.cpp](../../../cpp/l/linear_search_thread.cpp) |
| Elisa | [elisa/l/linear_search_thread.elisa](../../../elisa/l/linear_search_thread.elisa) |
| Nim | [nim/l/linear_search_thread.nim](../../../nim/l/linear_search_thread.nim) |
| Odin | [odin/l/linear_search_thread.odin](../../../odin/l/linear_search_thread.odin) |
| Rust | [rust/l/linear_search_thread.rs](../../../rust/l/linear_search_thread.rs) |
| V | [v/l/linear_search_thread.v](../../../v/l/linear_search_thread.v) |
| Zig | [zig/l/linear_search_thread.zig](../../../zig/l/linear_search_thread.zig) |
