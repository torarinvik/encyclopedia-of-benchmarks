# Find Triplets With Zero Sum (Hashing)

Find unique value triples whose sum is zero using the pinned Python helper's per-start hash set. Each candidate value is paired with the complement needed to reach zero. The helper sorts each matching triple, removes value duplicates, and preserves the order in which unique triples are first found. This is the hashing variant, distinct from the combinations and sorted two-pointer implementations.

## Contract

The `i64_array_bytes_output` ABI accepts an array of 0 to 64 integers in `[-100000, 100000]`. It returns the number of unique value triples in source discovery order. Each triple is encoded as three signed 32-bit little-endian values, with the values inside each triple sorted ascending. Duplicate values at different input positions do not duplicate output triples. The input is not modified. Invalid input returns `-1`; a null output pointer or insufficient capacity for the actual output returns `-2` without writing. Empty and fewer-than-three-element arrays return zero.

## Workload and source

[`workload.json`](workload.json) covers the pinned examples, discovery order, duplicates, bounds, maximum length, malformed inputs, and insufficient output capacity.

- Python [`find_triplets_with_0_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/find_triplets_with_0_sum.py)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm find_triplets_with_0_sum_hashing --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/find_triplets_with_0_sum_hashing/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/find_triplets_with_0_sum_hashing.c`](../../../c/f/find_triplets_with_0_sum_hashing.c) |
| C3 | [`c3/f/find_triplets_with_0_sum_hashing.c3`](../../../c3/f/find_triplets_with_0_sum_hashing.c3) |
| C++ | [`cpp/f/find_triplets_with_0_sum_hashing.cpp`](../../../cpp/f/find_triplets_with_0_sum_hashing.cpp) |
| Elisa | [`elisa/f/find_triplets_with_0_sum_hashing.elisa`](../../../elisa/f/find_triplets_with_0_sum_hashing.elisa) |
| Nim | [`nim/f/find_triplets_with_0_sum_hashing.nim`](../../../nim/f/find_triplets_with_0_sum_hashing.nim) |
| Odin | [`odin/f/find_triplets_with_0_sum_hashing.odin`](../../../odin/f/find_triplets_with_0_sum_hashing.odin) |
| Rust | [`rust/f/find_triplets_with_0_sum_hashing.rs`](../../../rust/f/find_triplets_with_0_sum_hashing.rs) |
| V | [`v/f/find_triplets_with_0_sum_hashing.v`](../../../v/f/find_triplets_with_0_sum_hashing.v) |
| Zig | [`zig/f/find_triplets_with_0_sum_hashing.zig`](../../../zig/f/find_triplets_with_0_sum_hashing.zig) |
