# Hash map

This benchmark ports the pinned Go separate-chaining map at [TheAlgorithms/Go, commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/hashmap/hashmap.go). It exercises `New(0, capacity)`, `Put`, `Get`, and `Contains` on a deterministic integer domain.

## Input

The input is a signed 64-bit integer array:

```text
[initial_capacity, operation_count, (opcode, key, value)*]
```

The initial capacity must be a power of two from 1 through 64. There are at most 128 operations. Keys and values must fit signed 32-bit integers. The opcodes are:

| Opcode | Operation | Value field |
| --- | --- | --- |
| `0` | Put or replace `key` with `value` | signed i32 value |
| `1` | Get `key` | must be zero |
| `2` | Check whether `key` is present | must be zero |

The packed length must be exactly `2 + 3 * operation_count`. Invalid input returns `-1` and writes no bytes.

## Semantics

Keys are formatted as their base-10 signed integer text, matching Go's `fmt.Sprintf("%v", key)`. The bytes are hashed with 64-bit FNV-1a; the source folds the hash with `hash ^ (hash >> 16)` and masks it by `capacity - 1`. Buckets use separate chains, new keys append to the end of a chain, and replacing an existing key leaves the size unchanged. Capacity doubles after a new insertion makes the load factor greater than `0.75`. Missing `Get` values are distinguished from a stored zero by an explicit presence bit. The bounded trace excludes pointer identity and internal bucket layout.

## Output

Success returns the number of bytes written. The output is a little-endian signed-i64 vector:

```text
[query_count, (get_opcode, present, value | contains_opcode, present)*, final_size, final_capacity]
```

Each `Get` contributes three words: opcode `1`, presence (`0` or `1`), and the value (zero when absent). Each `Contains` contributes two words: opcode `2` and presence (`0` or `1`). `Put` contributes no query record. The vector always includes the final size and capacity, including an empty trace. Insufficient output capacity, including a null output pointer, returns `-2` and writes no bytes. Invalid input takes precedence over output capacity and a null output pointer.

The maximum trace has 128 queries and requires 3,096 bytes. The default workload output workspace is sized for that maximum.

## Workload

The cases cover empty state, stored zero versus absence, overwrite, explicit collision chains, exact and crossed load thresholds, signed integer boundaries, maximum-length traces and output, malformed inputs, short/exact output capacities, and null-output precedence. The independent oracle models the map with a dictionary and serializes only public query results and final size/capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hashmap.c`](../../../c/h/hashmap.c) |
| C3 | [`c3/h/hashmap.c3`](../../../c3/h/hashmap.c3) |
| C++ | [`cpp/h/hashmap.cpp`](../../../cpp/h/hashmap.cpp) |
| Elisa | [`elisa/h/hashmap.elisa`](../../../elisa/h/hashmap.elisa) |
| Nim | [`nim/h/hashmap.nim`](../../../nim/h/hashmap.nim) |
| Odin | [`odin/h/hashmap.odin`](../../../odin/h/hashmap.odin) |
| Rust | [`rust/h/hashmap.rs`](../../../rust/h/hashmap.rs) |
| V | [`v/h/hashmap.v`](../../../v/h/hashmap.v) |
| Zig | [`zig/h/hashmap.zig`](../../../zig/h/hashmap.zig) |

## Build, record, and verify

Build one implementation and its C ABI runner:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hashmap --language c --with-checker
```

Record the workload for that build:

```sh
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/h/hashmap/c/build.json
```

Build and verify all nine implementations against the workload and generated oracle corpus:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm hashmap
```
