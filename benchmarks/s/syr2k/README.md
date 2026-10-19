# SYR2K: symmetric rank-2k update

This package implements the pinned PolyBench/C `kernel_syr2k`, its initialization, and its row-major live-out matrix. The launcher selects the extra-large dataset; this package uses a bounded profile so the full matrix fits the shared output buffer.

## Contract

The ABI is `float64_slice_io`. Input is exactly `[n,m]`, finite integral binary64 dimensions with `1 <= n <= 8` and `1 <= m <= 16`. The implementation initializes `A[i][j]=((i*j+1)%n)/n` and `B[i][j]=((i*j+2)%m)/m`, then `C[i][j]=((i*j+3)%n)/m`, all in row-major order. The pinned source uses `alpha=1.5` and `beta=1.2`.

For each `i` ascending, the kernel first scales `C[i][j]` by beta for `j=0..i`. It then visits `k=0..m-1`, and for each `k` visits `j=0..i`, applying the source expression in order:

```text
C[i][j] += A[j][k]*alpha*B[i][k] + B[j][k]*alpha*A[i][k]
```

Only the lower triangle is updated. The strict upper triangle retains its initialized values. Return all `n*n` values of C in row-major order as unrounded binary64 values; the source's `%0.2lf` printing format is not part of the numeric ABI. Invalid dimensions return `-1`. A null output pointer or capacity below `n*n` returns `-2` without writing. The bounds limit output to 64 values and both A/B workspaces to 128 values.

The pinned launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syr2k/info.sh); it selects `*.c`, enables `POLYBENCH_DUMP_ARRAYS` and `EXTRALARGE_DATASET`, and supplies no runtime options. The source header defines the extra-large dimensions as `n=2600,m=2000` and defaults the element type to double. The benchmark keeps source loop order while using the bounded profile above.

## Workload and provenance

[`workload.json`](workload.json) records the bounded inputs and source contract. [`syr2k_oracle.py`](../../syr2k_oracle.py) is the independent reference model. Source and launcher files are pinned to commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`:

- [`syr2k.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syr2k/syr2k.c): `init_array`, `kernel_syr2k`, and `print_array`.
- [`syr2k.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syr2k/syr2k.h): dataset and type definitions.

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/syr2k.c`](../../../c/s/syr2k.c) |
| C3 | [`c3/s/syr2k.c3`](../../../c3/s/syr2k.c3) |
| C++ | [`cpp/s/syr2k.cpp`](../../../cpp/s/syr2k.cpp) |
| Elisa | [`elisa/s/syr2k.elisa`](../../../elisa/s/syr2k.elisa) |
| Nim | [`nim/s/syr2k.nim`](../../../nim/s/syr2k.nim) |
| Odin | [`odin/s/syr2k.odin`](../../../odin/s/syr2k.odin) |
| Rust | [`rust/s/syr2k.rs`](../../../rust/s/syr2k.rs) |
| V | [`v/s/syr2k.v`](../../../v/s/syr2k.v) |
| Zig | [`zig/s/syr2k.zig`](../../../zig/s/syr2k.zig) |
