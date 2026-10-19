# Nestedloop

This benchmark ports the six level loop nest from the pinned
[`Shootout/nestedloop/nestedloop.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/nestedloop/nestedloop.c)
source in `lac-dcc/Benchmarks` at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

## Contract

The scalar ABI accepts `n` from 0 through 15. The implementation keeps the
source's six nested loops, each ranging from zero while its index is less than
`n`, and increments the source-style integer counter once per innermost
iteration. It returns the count `n^6`. The selected bound keeps the maximum
count, `15^6 = 11,390,625`, within the source's signed `int` range and the loop
work manageable. Negative inputs and values above 15 return `-1`.

The independent oracle is [`benchmarks/nestedloop_oracle.py`](../../nestedloop_oracle.py).
[`workload.json`](workload.json) covers zero, one, increasing loop counts, the
maximum safe bound, and invalid input boundaries.

Verify all language ports with:

```sh
python3 benchmarks/verify_scalar.py --algorithms nestedloop
```

Build and record one language with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm nestedloop --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/n/nestedloop/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/n/nestedloop.c](../../../c/n/nestedloop.c) |
| C3 | [c3/n/nestedloop.c3](../../../c3/n/nestedloop.c3) |
| C++ | [cpp/n/nestedloop.cpp](../../../cpp/n/nestedloop.cpp) |
| Elisa | [elisa/n/nestedloop.elisa](../../../elisa/n/nestedloop.elisa) |
| Nim | [nim/n/nestedloop.nim](../../../nim/n/nestedloop.nim) |
| Odin | [odin/n/nestedloop.odin](../../../odin/n/nestedloop.odin) |
| Rust | [rust/n/nestedloop.rs](../../../rust/n/nestedloop.rs) |
| V | [v/n/nestedloop.v](../../../v/n/nestedloop.v) |
| Zig | [zig/n/nestedloop.zig](../../../zig/n/nestedloop.zig) |
