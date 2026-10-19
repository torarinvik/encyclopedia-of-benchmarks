# Takeuchi

This benchmark ports the integer `tak` recurrence from
[`BenchmarkGame/recursive/recursive.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/recursive.c)
in `lac-dcc/Benchmarks` at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

## Contract

`takeuchi(x, y, z)` accepts three signed 64-bit integers, each in `0..12`.
Invalid external arguments return `-1`. The recurrence is exactly

```text
if y < x then tak(tak(x-1,y,z), tak(y-1,z,x), tak(z-1,x,y)) else z
```

The range keeps the direct, uncached recursive evaluation bounded. Validation
applies to the three external arguments; recursive internal arguments may be
negative and follow the recurrence normally. The independent memoized oracle
is [`benchmarks/takeuchi_oracle.py`](../../takeuchi_oracle.py).

## Workload and verification

[`workload.json`](workload.json) covers the base case, nested recursion, the
upper input bound, and invalid values in each argument position. Verify the
nine language ports with:

```sh
python3 benchmarks/verify_i64_triple.py --algorithm takeuchi
```

Build and record one port with the `i64_triple` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_triple --algorithm takeuchi --language rust
python3 benchmarks/run_i64_triple.py --build-manifest build/i64_triple/t/takeuchi/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/t/takeuchi.c](../../../c/t/takeuchi.c) |
| C3 | [c3/t/takeuchi.c3](../../../c3/t/takeuchi.c3) |
| C++ | [cpp/t/takeuchi.cpp](../../../cpp/t/takeuchi.cpp) |
| Elisa | [elisa/t/takeuchi.elisa](../../../elisa/t/takeuchi.elisa) |
| Nim | [nim/t/takeuchi.nim](../../../nim/t/takeuchi.nim) |
| Odin | [odin/t/takeuchi.odin](../../../odin/t/takeuchi.odin) |
| Rust | [rust/t/takeuchi.rs](../../../rust/t/takeuchi.rs) |
| V | [v/t/takeuchi.v](../../../v/t/takeuchi.v) |
| Zig | [zig/t/takeuchi.zig](../../../zig/t/takeuchi.zig) |
