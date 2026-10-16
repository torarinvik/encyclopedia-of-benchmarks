# Project Euler Problem 206: concealed square

## Contract

The pinned source takes no arguments. The scalar ABI uses `0` as its placeholder and returns `-1` for every other input. For zero, the source returns the first value found by its descending search whose square has the fixed digits `1_2_3_4_5_6_7_8_9`; the source appends the final zero to the root after searching. The result is **1,389,019,170**.

The ports start at the source's upper candidate 138,902,663. They test the square's digits from the right at every second decimal position, expecting 9 down through 1. Candidate roots end in 3 or 7, so the search steps downward by 6 and 4 alternately. The bounded candidate interval is 101,010,103 through 138,902,663.

## Workload

[`workload.json`](workload.json) covers the fixed no-argument result and rejected placeholder values.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm problem206 --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/problem206/rust/build.json
```

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_206/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem206.c](../../../c/p/problem206.c) |
| C3 | [c3/p/problem206.c3](../../../c3/p/problem206.c3) |
| C++ | [cpp/p/problem206.cpp](../../../cpp/p/problem206.cpp) |
| Elisa | [elisa/p/problem206.elisa](../../../elisa/p/problem206.elisa) |
| Nim | [nim/p/problem206.nim](../../../nim/p/problem206.nim) |
| Odin | [odin/p/problem206.odin](../../../odin/p/problem206.odin) |
| Rust | [rust/p/problem206.rs](../../../rust/p/problem206.rs) |
| V | [v/p/problem206.v](../../../v/p/problem206.v) |
| Zig | [zig/p/problem206.zig](../../../zig/p/problem206.zig) |
