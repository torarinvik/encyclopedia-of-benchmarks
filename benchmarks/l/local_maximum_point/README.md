# Local maximum point

The pinned JavaScript routine recursively halves the search range. It returns the midpoint if it is at least as large as both neighbors; otherwise it searches left when the left neighbor is greater, and right in the remaining case. The returned index follows that branch order, including on plateaus.

## Contract

Input is 1 to 64 integers in `[-1000000,1000000]`. Output is the index selected by the source divide-and-conquer search. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../local_maximum_point_oracle.py), and pinned [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Array/LocalMaximumPoint.js).

| Language | Port |
|---|---|
| C | [`c/l/local_maximum_point.c`](../../../c/l/local_maximum_point.c) |
| C3 | [`c3/l/local_maximum_point.c3`](../../../c3/l/local_maximum_point.c3) |
| C++ | [`cpp/l/local_maximum_point.cpp`](../../../cpp/l/local_maximum_point.cpp) |
| Elisa | [`elisa/l/local_maximum_point.elisa`](../../../elisa/l/local_maximum_point.elisa) |
| Nim | [`nim/l/local_maximum_point.nim`](../../../nim/l/local_maximum_point.nim) |
| Odin | [`odin/l/local_maximum_point.odin`](../../../odin/l/local_maximum_point.odin) |
| Rust | [`rust/l/local_maximum_point.rs`](../../../rust/l/local_maximum_point.rs) |
| V | [`v/l/local_maximum_point.v`](../../../v/l/local_maximum_point.v) |
| Zig | [`zig/l/local_maximum_point.zig`](../../../zig/l/local_maximum_point.zig) |
