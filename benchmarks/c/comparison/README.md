# String Comparison

Compare two bounded ASCII strings lexicographically. Mode 0 is case-sensitive; mode 1 folds ASCII `A` through `Z` to lowercase before comparing.

## Contract

- Pack the `i64_array_scalar` input as `[mode, n1, bytes1..., n2, bytes2...]`. Mode is 0 for case-sensitive comparison or 1 for ASCII case-insensitive comparison. Each string length is from 0 through 64.
- String bytes must be nonzero ASCII values from 1 through 127. The length fields act as the NUL terminators used by the source routine; embedded NUL is outside the domain.
- Return `-1` when the first string sorts before the second, `0` when they compare equal, and `1` when the first sorts after the second. Case-insensitive mode folds only ASCII uppercase letters.
- Malformed input returns `-2`, which is distinct from the valid `-1` less-than result.

The source includes case-sensitive and case-insensitive comparison routines plus a console wrapper. This benchmark covers the two comparison routines and leaves out the wrapper's printing behavior.

## Pinned source and workload

- [TheAlgorithms/AArch64_Assembly `comparison.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/string/comparison.s)

The source header attributes the assembly example to Rosetta Code and identifies the source license as [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). This package preserves attribution and license information while implementing the same byte-comparison behavior portably.

[`workload.json`](workload.json) covers both modes, empty strings, first-byte and prefix differences, case folding, ASCII boundary bytes, maximum-length strings, and malformed layouts or values. [`comparison_oracle.py`](../../comparison_oracle.py) computes the sign of the lexicographic comparison independently.

Build and verify with the shared scalar ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm comparison --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/comparison/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms comparison
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/c/comparison.c`](../../../c/c/comparison.c) |
| C3 | [`c3/c/comparison.c3`](../../../c3/c/comparison.c3) |
| C++ | [`cpp/c/comparison.cpp`](../../../cpp/c/comparison.cpp) |
| Elisa | [`elisa/c/comparison.elisa`](../../../elisa/c/comparison.elisa) |
| Nim | [`nim/c/comparison.nim`](../../../nim/c/comparison.nim) |
| Odin | [`odin/c/comparison.odin`](../../../odin/c/comparison.odin) |
| Rust | [`rust/c/comparison.rs`](../../../rust/c/comparison.rs) |
| V | [`v/c/comparison.v`](../../../v/c/comparison.v) |
| Zig | [`zig/c/comparison.zig`](../../../zig/c/comparison.zig) |
