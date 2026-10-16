# Hamming distance for byte strings

Count the byte positions that differ between two equal-length byte strings. The pinned Go and Lua sources both compare bytes and reject strings whose byte lengths differ. Their contract differs from [`hamming_distance`](../hamming_distance/README.md), which counts differing bits in unsigned 64-bit integers.

## Contract

The input is a signed-i64 array laid out as `[byte_count, left_bytes..., right_bytes...]`. The count is from 0 through 1,024; each byte is from 0 through 255. Return the number of unequal byte positions, from 0 through `byte_count`. Malformed shapes or out-of-range values return `-1`. The input is read only.

The shared ABI is:

```c
int64_t hamming_distance_bytes(const int64_t *values, size_t length);
```

The valid input length is `1 + 2 * byte_count`. A 2,050-element input bound leaves room for one extra-value malformed case at the maximum count.

## Workload and verification

[`workload.json`](workload.json) covers empty and nonempty byte strings, UTF-8 byte sequences, embedded zero and `0xff` values, the maximum byte count, malformed lengths, and invalid bytes. The independent oracle is [`benchmarks/hamming_distance_bytes_oracle.py`](../../hamming_distance_bytes_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hamming_distance_bytes --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_scalar.py \
  --build-manifest build/i64_array_scalar/h/hamming_distance_bytes/rust/build.json
```

Verify the registered algorithm across all nine languages with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms hamming_distance_bytes
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/h/hamming_distance_bytes.c`](../../../c/h/hamming_distance_bytes.c) |
| C3 | [`c3/h/hamming_distance_bytes.c3`](../../../c3/h/hamming_distance_bytes.c3) |
| C++ | [`cpp/h/hamming_distance_bytes.cpp`](../../../cpp/h/hamming_distance_bytes.cpp) |
| Elisa | [`elisa/h/hamming_distance_bytes.elisa`](../../../elisa/h/hamming_distance_bytes.elisa) |
| Nim | [`nim/h/hamming_distance_bytes.nim`](../../../nim/h/hamming_distance_bytes.nim) |
| Odin | [`odin/h/hamming_distance_bytes.odin`](../../../odin/h/hamming_distance_bytes.odin) |
| Rust | [`rust/h/hamming_distance_bytes.rs`](../../../rust/h/hamming_distance_bytes.rs) |
| V | [`v/h/hamming_distance_bytes.v`](../../../v/h/hamming_distance_bytes.v) |
| Zig | [`zig/h/hamming_distance_bytes.zig`](../../../zig/h/hamming_distance_bytes.zig) |

## TheAlgorithms references

- [Go `hammingdistance.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/hamming/hammingdistance.go)
- [Lua `hamming.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/string/distance/hamming.lua)
