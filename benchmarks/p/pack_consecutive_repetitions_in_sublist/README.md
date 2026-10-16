# Pack consecutive repetitions in a sublist

The pinned Clojure source defines three versions of the same run-packing operation. `pack-1` accumulates adjacent equal values, `pack-2` uses `partition-by identity`, and `pack-3` lazily takes each consecutive equal run.

## Contract

Input is `[count, signed-i32 values...]`, with 0–64 values. The benchmark groups each maximal run of equal adjacent values and hashes each `(value, run_length)` pair in encounter order. Each pair is serialized as little-endian signed-i32 value followed by little-endian unsigned-i32 run length, then fed to 32-bit FNV-1a. An empty list hashes the empty serialization. Invalid inputs return `-1`.

See [`workload.json`](workload.json) and the runtime [oracle](../../pack_consecutive_repetitions_in_sublist_oracle.py). Pinned source: [TheAlgorithms/Clojure `pack_consecutive_repetitions_in_sublist.clj`](https://github.com/TheAlgorithms/Clojure/blob/a9c5bec14928cb22fd4d69e951edf5bd15e16a18/src/data_structures/lists/pack_consecutive_repetitions_in_sublist.clj).

| Language | Port |
|---|---|
| C | [`c/p/pack_consecutive_repetitions_in_sublist.c`](../../../c/p/pack_consecutive_repetitions_in_sublist.c) |
| C3 | [`c3/p/pack_consecutive_repetitions_in_sublist.c3`](../../../c3/p/pack_consecutive_repetitions_in_sublist.c3) |
| C++ | [`cpp/p/pack_consecutive_repetitions_in_sublist.cpp`](../../../cpp/p/pack_consecutive_repetitions_in_sublist.cpp) |
| Elisa | [`elisa/p/pack_consecutive_repetitions_in_sublist.elisa`](../../../elisa/p/pack_consecutive_repetitions_in_sublist.elisa) |
| Nim | [`nim/p/pack_consecutive_repetitions_in_sublist.nim`](../../../nim/p/pack_consecutive_repetitions_in_sublist.nim) |
| Odin | [`odin/p/pack_consecutive_repetitions_in_sublist.odin`](../../../odin/p/pack_consecutive_repetitions_in_sublist.odin) |
| Rust | [`rust/p/pack_consecutive_repetitions_in_sublist.rs`](../../../rust/p/pack_consecutive_repetitions_in_sublist.rs) |
| V | [`v/p/pack_consecutive_repetitions_in_sublist.v`](../../../v/p/pack_consecutive_repetitions_in_sublist.v) |
| Zig | [`zig/p/pack_consecutive_repetitions_in_sublist.zig`](../../../zig/p/pack_consecutive_repetitions_in_sublist.zig) |
