# Shootout ary3

This package ports [the `Shootout/ary3/ary3.c` source](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/ary3.c) and [its `info.sh` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/info.sh), both pinned to upstream commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher selects `ary3.c`, passes `-lm` at compile time, and supplies no run options.

The bounded profile accepts a signed 64-bit length `n` from 1 through 4096. It initializes `x[i]=i+1` and zeroes `y`, then performs 1000 passes over indices in descending order with `y[i] += x[i]`. The function returns the exact ASCII bytes the source prints: `y[0]`, one space, `y[n-1]`, and a newline. The source defaults to 1,500,000 elements (150,000 with `SMALL_PROBLEM_SIZE`), but this suite contract uses explicit bounded lengths. Nonpositive lengths are rejected because `n=0` would access `y[-1]` in the source.

The independent [Python oracle](../../ary3_oracle.py) performs the same bounded initialization and repeated reverse traversal. [`workload.json`](workload.json) includes ordinary, boundary, invalid, short-capacity, and null-output cases. The ports are independently written in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/ary3.c`](../../../c/a/ary3.c) |
| C3 | [`c3/a/ary3.c3`](../../../c3/a/ary3.c3) |
| C++ | [`cpp/a/ary3.cpp`](../../../cpp/a/ary3.cpp) |
| Elisa | [`elisa/a/ary3.elisa`](../../../elisa/a/ary3.elisa) |
| Nim | [`nim/a/ary3.nim`](../../../nim/a/ary3.nim) |
| Odin | [`odin/a/ary3.odin`](../../../odin/a/ary3.odin) |
| Rust | [`rust/a/ary3.rs`](../../../rust/a/ary3.rs) |
| V | [`v/a/ary3.v`](../../../v/a/ary3.v) |
| Zig | [`zig/a/ary3.zig`](../../../zig/a/ary3.zig) |

## Build and record

~~~sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm ary3 --language c
python3 benchmarks/run_i64_scalar_bytes_output.py --algorithm ary3
python3 benchmarks/verify_i64_scalar_bytes_output.py --algorithms ary3
~~~
