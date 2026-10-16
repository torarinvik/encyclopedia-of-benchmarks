# Damm check digit

The benchmark exposes both operations from the pinned Java implementation: validate a complete decimal sequence, or compute the digit to append.

## Contract

- Uses the `i64_array_scalar` ABI. Input is `[mode, digit_count, digits...]`.
- Mode `0` validates the complete sequence and returns `1` for valid or `0` for invalid. Mode `1` returns the Damm check digit to append.
- `digit_count` must be 1 through 256, and every digit must be in 0 through 9. The array length must be exactly `digit_count + 2`.
- Invalid shape, mode, or digit returns `-1`.
- The Damm quasigroup table and left-to-right state update match the pinned source.

[`workload.json`](workload.json) includes valid and invalid strings, check-digit generation, boundary shapes, invalid digits, and long inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm damm --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/damm/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/d/damm.c`](../../../c/d/damm.c) |
| C3 | [`c3/d/damm.c3`](../../../c3/d/damm.c3) |
| C++ | [`cpp/d/damm.cpp`](../../../cpp/d/damm.cpp) |
| Elisa | [`elisa/d/damm.elisa`](../../../elisa/d/damm.elisa) |
| Nim | [`nim/d/damm.nim`](../../../nim/d/damm.nim) |
| Odin | [`odin/d/damm.odin`](../../../odin/d/damm.odin) |
| Rust | [`rust/d/damm.rs`](../../../rust/d/damm.rs) |
| V | [`v/d/damm.v`](../../../v/d/damm.v) |
| Zig | [`zig/d/damm.zig`](../../../zig/d/damm.zig) |

## TheAlgorithms reference

- [Java `Damm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/Damm.java)
