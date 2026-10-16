# Project Euler Problem 188

## Contract

`problem188(base, height, digits)` returns the pinned source's iterative modular tetration result. It starts with `result = base`, then applies the source's recursive `_modexpt(base, result, 10**digits)` for each remaining height level. The helper returns `base` directly when its exponent is 1; at height 1 the function therefore returns `base` without truncating it to the requested digit count.

The portable input range is base 1..1,000,000,000 with a nonzero units digit, height 1..10,000, and digits 1..8. Other inputs return `-1`. The nonzero units digit avoids the source helper's nonterminating zero-exponent case for bases divisible by 10. The source examples return **27** for (3, 2, 8), **97484987** for (3, 3, 8), and **2547** for (123, 456, 4). The default (1777, 1855, 8) returns **95962097**.

## Workload

[`workload.json`](workload.json) includes the source examples, default, an untruncated height-one case, and invalid values at each input boundary.

Build and record with the `i64_triple` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_triple --algorithm problem188 --language rust
python3 benchmarks/run_i64_triple.py --build-manifest build/i64_triple/p/problem188/rust/build.json
```

Run the independent corpus verifier with `python3 benchmarks/verify_i64_triple.py`.

## TheAlgorithms reference

- Python [`sol1.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_188/sol1.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem188.c](../../../c/p/problem188.c) |
| C3 | [c3/p/problem188.c3](../../../c3/p/problem188.c3) |
| C++ | [cpp/p/problem188.cpp](../../../cpp/p/problem188.cpp) |
| Elisa | [elisa/p/problem188.elisa](../../../elisa/p/problem188.elisa) |
| Nim | [nim/p/problem188.nim](../../../nim/p/problem188.nim) |
| Odin | [odin/p/problem188.odin](../../../odin/p/problem188.odin) |
| Rust | [rust/p/problem188.rs](../../../rust/p/problem188.rs) |
| V | [v/p/problem188.v](../../../v/p/problem188.v) |
| Zig | [zig/p/problem188.zig](../../../zig/p/problem188.zig) |
