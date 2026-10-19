# Partial sums

This package ports `BenchmarkGame/partialsums/partialsums.c` from
[`lac-dcc/Benchmarks`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/partialsums/partialsums.c)
at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.

## Contract

The ABI accepts one finite binary64 input, `[n]`, where `n` is an exact integer
in `1..=10000`. It writes nine binary64 sums and returns `9`; invalid input
returns `-1`, and a null output pointer or capacity below nine returns `-2`
without writing output. Input is not modified.

The outputs follow the pinned source order: geometric `(2/3)^k`, inverse square
root, telescoping `1/(k(k+1))`, Flint Hills, Cookson Hills, harmonic, Riemann
zeta, alternating harmonic, and Gregory. The Flint Hills and Cookson Hills
terms use radians. The source accumulates five sums into two lanes, odd `k` in
lane 0 and even `k` in lane 1, then adds lane 0 before lane 1. Its loop tests
only lane 0, so odd `n` also includes the next even `k=n+1` in lane 1. Scalar
ports preserve that lane order and boundary behavior. The suite uses a shared absolute tolerance of
`1e-8` and relative tolerance of `1e-10` to allow ordinary binary64 reduction
and vector-lane order differences.

The bounded workload includes `n` values 1, 2, 10, 100, 1000, and 10000. The
independent oracle is [`benchmarks/partialsums_oracle.py`](../../partialsums_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/partialsums.c](../../../c/p/partialsums.c) |
| C3 | [c3/p/partialsums.c3](../../../c3/p/partialsums.c3) |
| C++ | [cpp/p/partialsums.cpp](../../../cpp/p/partialsums.cpp) |
| Elisa | [elisa/p/partialsums.elisa](../../../elisa/p/partialsums.elisa) |
| Nim | [nim/p/partialsums.nim](../../../nim/p/partialsums.nim) |
| Odin | [odin/p/partialsums.odin](../../../odin/p/partialsums.odin) |
| Rust | [rust/p/partialsums.rs](../../../rust/p/partialsums.rs) |
| V | [v/p/partialsums.v](../../../v/p/partialsums.v) |
| Zig | [zig/p/partialsums.zig](../../../zig/p/partialsums.zig) |

## Reproduce

Build a language port and run the shared `float64_slice_io` suite:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm partialsums --language c
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/p/partialsums/c/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm partialsums --languages c
```
