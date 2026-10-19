# Shootout matrix multiplication

This package ports the pinned Shootout `matrix` benchmark, which repeatedly multiplies two fixed 10×10 integer matrices and prints four selected cells.

## Contract

The suite accepts an iteration count from 0 through 4096. Both input matrices are initialized row-major with values 1 through 100, and the destination starts with the same values. For each iteration, the source computes the complete product in row, column, then inner-index order. The input matrices never change, so the first iteration produces the same destination matrix on every later iteration. With zero iterations, the initial destination values are printed.

The output is `mm[0][0]`, `mm[2][3]`, `mm[3][2]`, and `mm[4][4]`, separated by one space and followed by LF. The zero-iteration output is `1 24 33 45\n`; every positive iteration count returns `3355 13320 17865 23575\n`.

The C ABI entry point is:

~~~c
int64_t shootout_matrix(int64_t iteration_count, uint8_t *output,
                        size_t output_capacity);
~~~

Invalid counts return -1. A null output pointer or a capacity smaller than the staged output returns -2 without writing. Success returns the byte count. The maximum output is 23 bytes.

## Source and workload

The pinned launcher runs without options. The source defaults to 3,000,000 iterations, or 300,000 with `SMALL_PROBLEM_SIZE`. This bounded profile limits the work to 4,096 iterations while retaining the source's zero-iteration behavior and every computation/output step within the profile.

[`workload.json`](workload.json) defines the bounded input and output cases. [`shootout_matrix_oracle.py`](../../shootout_matrix_oracle.py) derives the visible products using a closed-form sum, independently of the ports' nested matrix multiplication loops.

| Language | Source |
| --- | --- |
| C | [`c/s/shootout_matrix.c`](../../../c/s/shootout_matrix.c) |
| C3 | [`c3/s/shootout_matrix.c3`](../../../c3/s/shootout_matrix.c3) |
| C++ | [`cpp/s/shootout_matrix.cpp`](../../../cpp/s/shootout_matrix.cpp) |
| Elisa | [`elisa/s/shootout_matrix.elisa`](../../../elisa/s/shootout_matrix.elisa) |
| Nim | [`nim/s/shootout_matrix.nim`](../../../nim/s/shootout_matrix.nim) |
| Odin | [`odin/s/shootout_matrix.odin`](../../../odin/s/shootout_matrix.odin) |
| Rust | [`rust/s/shootout_matrix.rs`](../../../rust/s/shootout_matrix.rs) |
| V | [`v/s/shootout_matrix.v`](../../../v/s/shootout_matrix.v) |
| Zig | [`zig/s/shootout_matrix.zig`](../../../zig/s/shootout_matrix.zig) |

Pinned source: [`matrix.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/matrix/matrix.c) and [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/matrix/info.sh).
