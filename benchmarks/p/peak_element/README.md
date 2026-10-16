# Peak element

The pinned Dart routine recursively selects the midpoint of an inclusive range. It returns that index when the value is at least both neighbors (with endpoint checks); otherwise it recurses toward a larger neighbor. Equal adjacent values qualify as peaks, so the exact midpoint and branch rules determine the returned index on plateaus.

## Contract

Input is `[count, values...]`, with 1 through 128 signed 32-bit values. Output is the index returned by the pinned recursive search. Invalid input returns `-1`. This contract preserves the source's `<=` neighbor behavior, including its choice of one index from a flat peak.

See [`workload.json`](workload.json) and the runtime [oracle](../../peak_element_oracle.py). Pinned source: [TheAlgorithms/Dart `peak_element.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/search/peak_element.dart).

| Language | Port |
|---|---|
| C | [`c/p/peak_element.c`](../../../c/p/peak_element.c) |
| C3 | [`c3/p/peak_element.c3`](../../../c3/p/peak_element.c3) |
| C++ | [`cpp/p/peak_element.cpp`](../../../cpp/p/peak_element.cpp) |
| Elisa | [`elisa/p/peak_element.elisa`](../../../elisa/p/peak_element.elisa) |
| Nim | [`nim/p/peak_element.nim`](../../../nim/p/peak_element.nim) |
| Odin | [`odin/p/peak_element.odin`](../../../odin/p/peak_element.odin) |
| Rust | [`rust/p/peak_element.rs`](../../../rust/p/peak_element.rs) |
| V | [`v/p/peak_element.v`](../../../v/p/peak_element.v) |
| Zig | [`zig/p/peak_element.zig`](../../../zig/p/peak_element.zig) |
