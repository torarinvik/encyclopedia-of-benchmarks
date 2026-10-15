# Farey approximation

Approximate a fractional decimal with the final mediant fraction from the pinned JavaScript implementation.

## Contract

The `i64_array_bytes_output` input is `[decimal_millionths, repeat]`. It represents `decimal_millionths / 1,000,000`, which must lie strictly between zero and one; `repeat` must be in `1..20`. The algorithm starts with lower bound `0/1` and upper bound `1/1`. Each iteration forms their mediant, stores it as the current result, and replaces the lower bound when the target decimal is greater than the mediant; otherwise it replaces the upper bound. The final mediant is returned, even if it is not the closest rational after the last update.

The successful return value is 16. The output buffer contains the numerator and denominator as two little-endian signed 64-bit integers. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. At most 20 iterations keep both values well within signed 64-bit bounds.

## Source

The pinned JavaScript [`FareyApproximation.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/FareyApproximation.js) uses those mediant bounds for a decimal in `(0,1)` and defaults to 20 repetitions. This workload encodes the target as integer millionths for a stable portable input representation.

## Workload and recording

[`workload.json`](workload.json) covers early mediants, exact comparison ties, the 20-iteration source default, range endpoints, and malformed parameters.

The shared `i64_array_bytes_output` runner checks the returned numerator/denominator pair.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm farey_approximation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/farey_approximation/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/f/farey_approximation.c`](../../../c/f/farey_approximation.c) |
| C3 | [`c3/f/farey_approximation.c3`](../../../c3/f/farey_approximation.c3) |
| C++ | [`cpp/f/farey_approximation.cpp`](../../../cpp/f/farey_approximation.cpp) |
| Elisa | [`elisa/f/farey_approximation.elisa`](../../../elisa/f/farey_approximation.elisa) |
| Nim | [`nim/f/farey_approximation.nim`](../../../nim/f/farey_approximation.nim) |
| Odin | [`odin/f/farey_approximation.odin`](../../../odin/f/farey_approximation.odin) |
| Rust | [`rust/f/farey_approximation.rs`](../../../rust/f/farey_approximation.rs) |
| V | [`v/f/farey_approximation.v`](../../../v/f/farey_approximation.v) |
| Zig | [`zig/f/farey_approximation.zig`](../../../zig/f/farey_approximation.zig) |
