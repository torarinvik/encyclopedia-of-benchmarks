# Rust speed conversion

This benchmark ports the pinned Rust `convert_speed` function. It covers all seven source units: kilometres per hour, metres per second, miles per hour, knots, feet per second, Mach, and speed of light.

## Contract

The signed-i64 input is `[speed_micro, from_unit, to_unit]`. `speed_micro` encodes a signed speed divided by 1,000,000, with magnitude at most 1,000,000,000 units. Unit selectors use this order:

| Selector | Unit |
|---:|---|
| 0 | km/h |
| 1 | m/s |
| 2 | mph |
| 3 | knot |
| 4 | ft/s |
| 5 | Mach |
| 6 | c |

Negative speeds are valid, matching the source's lack of sign validation.

The adapter computes the source's two ordered multiplications and applies Rust's `f64::round` behavior: nearest integer with exact half cases rounded away from zero, followed by division by 1,000. To keep the scaled rounded integer exactly representable for every port, inputs whose intermediate `result * 1000` exceeds `2^53` are outside the benchmark domain and return `-1e300`; malformed arrays, invalid unit selectors, and speed magnitudes above the bound use the same sentinel. Valid outputs have magnitude at most 9,007,199,254,740.992, so the sentinel cannot collide with a result.

The shared ABI is:

```c
double speed(const int64_t *values, size_t length);
```

[`workload.json`](workload.json) covers all 49 unit pairs, pinned source examples, negative values, ties-away-from-zero cases, both speed limits, and invalid inputs. The independent oracle is [`benchmarks/speed_oracle.py`](../../speed_oracle.py).

Build a port with the shared ABI recipe:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm speed --language rust
```

Record the workload with the build manifest:

```sh
python3 benchmarks/run_i64_array_float64.py \
  --build-manifest build/i64_array_float64/s/speed/rust/build.json
```

Verify the registered ports with:

```sh
python3 benchmarks/verify_speed.py --languages rust
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/speed.c`](../../../c/s/speed.c) |
| C3 | [`c3/s/speed.c3`](../../../c3/s/speed.c3) |
| C++ | [`cpp/s/speed.cpp`](../../../cpp/s/speed.cpp) |
| Elisa | [`elisa/s/speed.elisa`](../../../elisa/s/speed.elisa) |
| Nim | [`nim/s/speed.nim`](../../../nim/s/speed.nim) |
| Odin | [`odin/s/speed.odin`](../../../odin/s/speed.odin) |
| Rust | [`rust/s/speed.rs`](../../../rust/s/speed.rs) |
| V | [`v/s/speed.v`](../../../v/s/speed.v) |
| Zig | [`zig/s/speed.zig`](../../../zig/s/speed.zig) |

## Pinned source

- [TheAlgorithms/Rust `speed.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/speed.rs)
