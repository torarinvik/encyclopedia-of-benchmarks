# Burst balloons

Given a sequence of balloon values, choose a bursting order that maximizes the
coins collected. When balloon `i` is burst, it earns the product of its value
and the values of the nearest still-present balloons to its left and right;
the missing neighbors at either end have value 1.

## Contract

- Input is an array of 0 to 128 signed 64-bit values, each from 0 through 1,000.
- Return the maximum coin total. An empty array returns 0.
- Arrays longer than 128 or containing a value outside the range return -1.
- For each interval, the implementation tries every balloon as the last one to
  burst. The two remaining subintervals are then independent. This is the
  interval dynamic-programming algorithm in the pinned Go source.
- The value bounds keep every product and total within signed 64-bit range.

## Workload and oracle

[`workload.json`](workload.json) covers empty and singleton arrays, the
canonical examples, zero values, invalid values, and the maximum supported
length. The independent Python oracle uses a top-down memoized interval
recurrence. After building the ABI artifacts, verify the ports with
`python3 benchmarks/verify_i64_array_scalar.py --algorithms burstballoons --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

[TheAlgorithms/Go `dynamic/burstballoons.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/burstballoons.go)
defines `MaxCoins`, pads the values with boundary ones, and fills an interval
table in increasing interval length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/burstballoons.c`](../../../c/b/burstballoons.c) |
| C3 | [`c3/b/burstballoons.c3`](../../../c3/b/burstballoons.c3) |
| C++ | [`cpp/b/burstballoons.cpp`](../../../cpp/b/burstballoons.cpp) |
| Elisa | [`elisa/b/burstballoons.elisa`](../../../elisa/b/burstballoons.elisa) |
| Nim | [`nim/b/burstballoons.nim`](../../../nim/b/burstballoons.nim) |
| Odin | [`odin/b/burstballoons.odin`](../../../odin/b/burstballoons.odin) |
| Rust | [`rust/b/burstballoons.rs`](../../../rust/b/burstballoons.rs) |
| V | [`v/b/burstballoons.v`](../../../v/b/burstballoons.v) |
| Zig | [`zig/b/burstballoons.zig`](../../../zig/b/burstballoons.zig) |

The oracle is [`burstballoons_oracle.py`](../../burstballoons_oracle.py).
