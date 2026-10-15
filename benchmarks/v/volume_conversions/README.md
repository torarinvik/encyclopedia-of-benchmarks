# Metric volume conversions

This package follows the pinned Python and Rust volume-unit converters on a restricted shared metric domain. It returns one converted value as little-endian IEEE-754 binary64 bytes.

## Contract

The `i64_array_bytes_output` input is exactly `[value, from_unit, to_unit]`. `value` is an integer from 0 through 1000. Unit codes are 0 for cubic meter, 1 for litre/liter, and 2 for kilolitre/kiloliter. The source factors to cubic meters are `1.0`, `0.001`, and `1.0`. The source and target units must differ, yielding six directed conversions. A valid call returns 8 and writes the converted binary64 value; malformed input, an unsupported unit, an identity conversion, or an out-of-range value returns `-1`. Output capacity below 8 bytes or a null output pointer returns `-2`.

The Python source has seven named units and uses paired approximate factors; Rust supports dozens of units and converts through cubic meters. Only cubic meter, litre, and kilolitre factors are shared exactly. Gallon, cubic-yard, cubic-foot, and cup conversions are excluded because their source constants differ. The `litre -> litre` identity conversion is excluded because the two source arithmetic paths can produce different binary64 bits for some integer values. On the six non-identity metric pairs and the bounded integer value range, the source results agree exactly.

## Workload and recording

[`workload.json`](workload.json) covers all six directed conversions, zero and maximum values, identity and unsupported-unit rejection, malformed packed lengths, and short output capacity.
The byte-output runner includes a source oracle for this restricted metric contract.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm volume_conversions --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm volume_conversions
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/v/volume_conversions.c`](../../../c/v/volume_conversions.c) |
| C3 | [`c3/v/volume_conversions.c3`](../../../c3/v/volume_conversions.c3) |
| C++ | [`cpp/v/volume_conversions.cpp`](../../../cpp/v/volume_conversions.cpp) |
| Elisa | [`elisa/v/volume_conversions.elisa`](../../../elisa/v/volume_conversions.elisa) |
| Nim | [`nim/v/volume_conversions.nim`](../../../nim/v/volume_conversions.nim) |
| Odin | [`odin/v/volume_conversions.odin`](../../../odin/v/volume_conversions.odin) |
| Rust | [`rust/v/volume_conversions.rs`](../../../rust/v/volume_conversions.rs) |
| V | [`v/v/volume_conversions.v`](../../../v/v/volume_conversions.v) |
| Zig | [`zig/v/volume_conversions.zig`](../../../zig/v/volume_conversions.zig) |

## Pinned sources

- Python [`volume_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/volume_conversions.py)
- Rust [`volume.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/volume.rs)
