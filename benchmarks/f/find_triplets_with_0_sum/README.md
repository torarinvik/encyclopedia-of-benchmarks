# Find Triplets With Zero Sum (Combinations)

Find unique value triples whose sum is zero by enumerating every three-position combination. The primary pinned Python function sorts the input, uses `itertools.combinations`, collects tuples in a set, then sorts the result. This is the O(n³) combinations variant.

## Contract

The `i64_array_bytes_output` ABI accepts an array of 0 to 64 integers in `[-100000, 100000]`. It returns the number of unique value triples in lexicographic order. Each triple is encoded as three signed 32-bit little-endian values. Duplicate values at different input positions do not duplicate output triples. The input is not modified. Invalid input returns `-1`; a null output pointer or insufficient capacity for the actual output returns `-2` without writing. Empty and fewer-than-three-element arrays return zero.

All three nested loops visit the sorted input combinations, matching the source's brute-force enumeration cost. Matching duplicate triples are emitted once, in the same lexicographic order as the source's sorted set. The file also contains a separately named hashing implementation; this package covers the primary `find_triplets_with_0_sum` combinations function.

## Workload and source

[`workload.json`](workload.json) includes the source examples, duplicates, empty and short arrays, bounded values, and maximum length, and insufficient output capacity.

- Python [`find_triplets_with_0_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/find_triplets_with_0_sum.py)

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm find_triplets_with_0_sum --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/find_triplets_with_0_sum/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/find_triplets_with_0_sum.c`](../../../c/f/find_triplets_with_0_sum.c) |
| C3 | [`c3/f/find_triplets_with_0_sum.c3`](../../../c3/f/find_triplets_with_0_sum.c3) |
| C++ | [`cpp/f/find_triplets_with_0_sum.cpp`](../../../cpp/f/find_triplets_with_0_sum.cpp) |
| Elisa | [`elisa/f/find_triplets_with_0_sum.elisa`](../../../elisa/f/find_triplets_with_0_sum.elisa) |
| Nim | [`nim/f/find_triplets_with_0_sum.nim`](../../../nim/f/find_triplets_with_0_sum.nim) |
| Odin | [`odin/f/find_triplets_with_0_sum.odin`](../../../odin/f/find_triplets_with_0_sum.odin) |
| Rust | [`rust/f/find_triplets_with_0_sum.rs`](../../../rust/f/find_triplets_with_0_sum.rs) |
| V | [`v/f/find_triplets_with_0_sum.v`](../../../v/f/find_triplets_with_0_sum.v) |
| Zig | [`zig/f/find_triplets_with_0_sum.zig`](../../../zig/f/find_triplets_with_0_sum.zig) |
