# Unbias 0/1

Use the Von Neumann pair extractor on a bounded stream of biased binary outcomes. The pinned Lua source draws two values at a time until they differ, then returns the first value. The benchmark supplies those outcomes as input so the same pair-selection behavior has a deterministic result.

## Contract

- Input is `[n, bit_0, ..., bit_(n-1)]`; `n` is 0 through 256 and each bit is 0 or 1.
- Examine disjoint adjacent pairs from the start. For the first pair `(0,1)` return 0; for `(1,0)` return 1. Equal pairs are discarded.
- Return `-1` for malformed input or if the bounded stream ends without an unequal pair. An odd final bit is unused.

[`workload.json`](workload.json) includes both unequal-pair outcomes, skipped equal pairs, exhaustion, and malformed values. The runtime oracle is [`unbias_01_oracle.py`](../../unbias_01_oracle.py).

## Pinned source

- [Lua `unbias_01.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/unbias_01.lua)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm unbias_01 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/u/unbias_01/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/u/unbias_01.c`](../../../c/u/unbias_01.c) |
| C3 | [`c3/u/unbias_01.c3`](../../../c3/u/unbias_01.c3) |
| C++ | [`cpp/u/unbias_01.cpp`](../../../cpp/u/unbias_01.cpp) |
| Elisa | [`elisa/u/unbias_01.elisa`](../../../elisa/u/unbias_01.elisa) |
| Nim | [`nim/u/unbias_01.nim`](../../../nim/u/unbias_01.nim) |
| Odin | [`odin/u/unbias_01.odin`](../../../odin/u/unbias_01.odin) |
| Rust | [`rust/u/unbias_01.rs`](../../../rust/u/unbias_01.rs) |
| V | [`v/u/unbias_01.v`](../../../v/u/unbias_01.v) |
| Zig | [`zig/u/unbias_01.zig`](../../../zig/u/unbias_01.zig) |
