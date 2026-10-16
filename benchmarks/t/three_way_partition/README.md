# Three-way partition

Reorder a bounded signed-32-bit array into values less than, equal to, and greater than a pivot using the Dutch national flag scan.

## Contract

- Input is `[n, pivot, value_0, ..., value_(n-1)]`; `n` is 0 through 256, and the pivot and values fit signed 32-bit integers.
- Output is `n` partitioned values followed by the two zero-based boundaries `[less_end_exclusive, greater_start]`, each little-endian signed 32-bit. The middle interval is equal to the pivot.
- Return `n+2` on success, `-1` for malformed input and `-2` for insufficient output capacity. Empty arrays are valid and return the two zero boundaries.
- The pinned Lua function uses inclusive `from`/`to` endpoints and returns the inclusive end of its less-than region and inclusive start of its greater-than region. This contract normalizes the whole-array operation to zero-based half-open boundaries.

[`workload.json`](workload.json) records representative partitions. The independent runtime oracle is [`three_way_partition_oracle.py`](../../three_way_partition_oracle.py).

## Pinned source

- [Lua `three_way_partition.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/sorting/three_way_partition.lua)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm three_way_partition --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm three_way_partition
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/three_way_partition.c`](../../../c/t/three_way_partition.c) |
| C3 | [`c3/t/three_way_partition.c3`](../../../c3/t/three_way_partition.c3) |
| C++ | [`cpp/t/three_way_partition.cpp`](../../../cpp/t/three_way_partition.cpp) |
| Elisa | [`elisa/t/three_way_partition.elisa`](../../../elisa/t/three_way_partition.elisa) |
| Nim | [`nim/t/three_way_partition.nim`](../../../nim/t/three_way_partition.nim) |
| Odin | [`odin/t/three_way_partition.odin`](../../../odin/t/three_way_partition.odin) |
| Rust | [`rust/t/three_way_partition.rs`](../../../rust/t/three_way_partition.rs) |
| V | [`v/t/three_way_partition.v`](../../../v/t/three_way_partition.v) |
| Zig | [`zig/t/three_way_partition.zig`](../../../zig/t/three_way_partition.zig) |
