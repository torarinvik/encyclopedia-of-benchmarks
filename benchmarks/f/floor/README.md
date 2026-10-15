# Floor

## Contract

For a finite binary64 input in `[-1,000,000, 1,000,000]`, return the largest integer less than or equal to the input, represented exactly as a binary64 value. Inputs outside this range return `-1`.

The exported C ABI entry point is:

```c
double floor(double value);
```

The pinned Java, Python, and Julia sources convert toward zero, then subtract one when the input is below that truncated value. The C# source converts to a nearest integer and adjusts downward when that value exceeds the input; it produces the same floor over the bounded domain. The local ports use truncation followed by the negative-fraction correction. The input bound keeps the integer conversion safe and every returned integer exactly representable in binary64.

## Workload and recording

[`workload.json`](workload.json) covers positive and negative integers, positive and negative fractions, half values, both bounds, and out-of-range inputs. Build with the `float64_unary` ABI family and record with:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm floor --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/floor/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/floor.c`](../../../c/f/floor.c) |
| C3 | [`c3/f/floor.c3`](../../../c3/f/floor.c3) |
| C++ | [`cpp/f/floor.cpp`](../../../cpp/f/floor.cpp) |
| Elisa | [`elisa/f/floor.elisa`](../../../elisa/f/floor.elisa) |
| Nim | [`nim/f/floor.nim`](../../../nim/f/floor.nim) |
| Odin | [`odin/f/floor.odin`](../../../odin/f/floor.odin) |
| Rust | [`rust/f/floor.rs`](../../../rust/f/floor.rs) |
| V | [`v/f/floor.v`](../../../v/f/floor.v) |
| Zig | [`zig/f/floor.zig`](../../../zig/f/floor.zig) |

## TheAlgorithms sources

- [Java `Floor.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Floor.java)
- [Python `floor.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/floor.py)
- [C# `Floor.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/Floor.cs)
- [Julia `floor.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/floor.jl)
