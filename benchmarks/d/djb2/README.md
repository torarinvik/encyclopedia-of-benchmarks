# DJB2 Hash

This benchmark ports the pinned Python [`djb2`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/djb2.py) function.

## Contract

- The `i64_array_scalar` input contains one Python character code point per element. The benchmark restricts code points to `[0, 255]` and strings to 0 through 64 characters.
- Starting from 5381, each code point updates the hash as `hash = hash * 33 + code_point`. The source masks the final value to 32 bits; ports may reduce after each step because this gives the same result.
- The result is the unsigned 32-bit hash as a nonnegative signed-i64 value. The empty string returns 5381. Invalid lengths or code points return `-1`.
- The parser admits 65 values so the workload can check the one-over-length boundary. Code points above 255 are outside this bounded benchmark contract.

## Pinned source

Python `hashes/djb2.py` at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Workload and build

[`workload.json`](workload.json) covers the source examples, empty input, embedded NUL, the upper byte value, maximum length, and invalid inputs. The independent oracle is [`djb2_oracle.py`](../../djb2_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm djb2 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/djb2/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms djb2
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/djb2.c`](../../../c/d/djb2.c) |
| C3 | [`c3/d/djb2.c3`](../../../c3/d/djb2.c3) |
| C++ | [`cpp/d/djb2.cpp`](../../../cpp/d/djb2.cpp) |
| Elisa | [`elisa/d/djb2.elisa`](../../../elisa/d/djb2.elisa) |
| Nim | [`nim/d/djb2.nim`](../../../nim/d/djb2.nim) |
| Odin | [`odin/d/djb2.odin`](../../../odin/d/djb2.odin) |
| Rust | [`rust/d/djb2.rs`](../../../rust/d/djb2.rs) |
| V | [`v/d/djb2.v`](../../../v/d/djb2.v) |
| Zig | [`zig/d/djb2.zig`](../../../zig/d/djb2.zig) |
