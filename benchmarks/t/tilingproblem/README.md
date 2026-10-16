# 2-by-n domino tiling count

Count the ways to cover a 2-by-n board with 2-by-1 dominoes. The pinned Go dynamic program counts the two possible placements at the boundary: one vertical domino or two horizontal dominoes, giving the Fibonacci recurrence.

## Contract

- Input is a one-element signed 64-bit array `[n]`, where `n` is 0 through 91.
- Return `ways(0)=ways(1)=1` and `ways(n)=ways(n-1)+ways(n-2)` for `n>=2`.
- Return `-1` for invalid length or width. The upper bound keeps every result in signed 64-bit.

[`workload.json`](workload.json) covers base cases, recurrence values, the maximum width, and malformed inputs. The runtime oracle is [`tilingproblem_oracle.py`](../../tilingproblem_oracle.py).

## Pinned source

- [Go `tilingproblem.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/tilingproblem.go)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm tilingproblem --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/t/tilingproblem/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/tilingproblem.c`](../../../c/t/tilingproblem.c) |
| C3 | [`c3/t/tilingproblem.c3`](../../../c3/t/tilingproblem.c3) |
| C++ | [`cpp/t/tilingproblem.cpp`](../../../cpp/t/tilingproblem.cpp) |
| Elisa | [`elisa/t/tilingproblem.elisa`](../../../elisa/t/tilingproblem.elisa) |
| Nim | [`nim/t/tilingproblem.nim`](../../../nim/t/tilingproblem.nim) |
| Odin | [`odin/t/tilingproblem.odin`](../../../odin/t/tilingproblem.odin) |
| Rust | [`rust/t/tilingproblem.rs`](../../../rust/t/tilingproblem.rs) |
| V | [`v/t/tilingproblem.v`](../../../v/t/tilingproblem.v) |
| Zig | [`zig/t/tilingproblem.zig`](../../../zig/t/tilingproblem.zig) |
