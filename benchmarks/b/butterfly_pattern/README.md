# Butterfly pattern

Build the source's symmetric ASCII butterfly from a positive row-size parameter.

## Contract

The `i64_scalar_bytes_output` ABI accepts `n` from 1 through 45. It returns the pattern as ASCII rows separated by newline bytes, with no trailing newline. Each top and bottom row has matching star wings separated by an odd-width gap; the middle row contains `2n - 1` stars. Inputs outside the range return `-1`; insufficient output capacity returns `-2` without writing.

The benchmark caps `n` at 45 because the shared output buffer holds at most 8,192 bytes. At `n = 45`, the pattern is 8,009 bytes.

[`workload.json`](workload.json) covers the smallest pattern, small symmetric layouts, and invalid lower and upper bounds. All nine ports passed 4,621 oracle values each and recorded all seven workload cases. The verifier checks every integer input through 4,096, signed boundaries, random values, and insufficient capacities.

```sh
python3 benchmarks/verify_i64_scalar_bytes_output.py --algorithms butterfly_pattern --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm butterfly_pattern --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/b/butterfly_pattern/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/b/butterfly_pattern.c`](../../../c/b/butterfly_pattern.c) |
| C3 | [`c3/b/butterfly_pattern.c3`](../../../c3/b/butterfly_pattern.c3) |
| C++ | [`cpp/b/butterfly_pattern.cpp`](../../../cpp/b/butterfly_pattern.cpp) |
| Elisa | [`elisa/b/butterfly_pattern.elisa`](../../../elisa/b/butterfly_pattern.elisa) |
| Nim | [`nim/b/butterfly_pattern.nim`](../../../nim/b/butterfly_pattern.nim) |
| Odin | [`odin/b/butterfly_pattern.odin`](../../../odin/b/butterfly_pattern.odin) |
| Rust | [`rust/b/butterfly_pattern.rs`](../../../rust/b/butterfly_pattern.rs) |
| V | [`v/b/butterfly_pattern.v`](../../../v/b/butterfly_pattern.v) |
| Zig | [`zig/b/butterfly_pattern.zig`](../../../zig/b/butterfly_pattern.zig) |

## TheAlgorithms reference

- [Python `butterfly_pattern.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/butterfly_pattern.py)
