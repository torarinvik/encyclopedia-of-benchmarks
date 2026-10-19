# LINPACK LU solve profile

This package isolates the pivoted LU factorization and forward/back solve in ANSIbench LINPACK. It is a small deterministic kernel profile, not an official LINPACK benchmark run and does not report FLOPS, KFlops, or a LINPACK score.

## Contract

Input is `[n, A, b]`, where `n` is 2 through 4, `A` is in the source's column-major storage order (`a[lda*column + row]`), and `b` contains `n` values. Matrix entries are signed integers from -8 through 8; RHS entries are signed integers from -32 through 32. The array length must be exactly `1+n*n+n`.

The profile executes the rolled `dgefa` path with `lda=n`, including `idamax` partial pivot search, row swaps, multiplier scaling, and `daxpy_r` elimination. It then runs rolled `dgesl` with `job=0` to solve `A*x=b`. Equal-magnitude pivot candidates keep the first index, matching upstream `idamax`'s strict-greater comparison. A nonzero `info` or zero diagonal is invalid. The returned scalar is `sum((i+1)*x[i])` in solution order. Invalid or null input returns `-1e300`; compare with absolute tolerance `1e-10` and relative tolerance `1e-12`.

## Upstream attribution and terms

The implementation is based on ANSIbench [`linpack/src/linpack.c`](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/linpack/src/linpack.c), pinned at commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`. The source identifies the Netlib LINPACK benchmark as public domain, credits Bonnie Toy's 1988 C translation and Will Menninger's 1993 modifications, and states that ict@nfinit.systems' 2018 and 2022 modifications are public domain. This bounded profile is independently implemented; see [LICENSE](LICENSE) for the upstream notice.

| Language | Port |
|---|---|
| C | [`c/l/linpack_lu_solve.c`](../../../c/l/linpack_lu_solve.c) |
| C3 | [`c3/l/linpack_lu_solve.c3`](../../../c3/l/linpack_lu_solve.c3) |
| C++ | [`cpp/l/linpack_lu_solve.cpp`](../../../cpp/l/linpack_lu_solve.cpp) |
| Elisa | [`elisa/l/linpack_lu_solve.elisa`](../../../elisa/l/linpack_lu_solve.elisa) |
| Nim | [`nim/l/linpack_lu_solve.nim`](../../../nim/l/linpack_lu_solve.nim) |
| Odin | [`odin/l/linpack_lu_solve.odin`](../../../odin/l/linpack_lu_solve.odin) |
| Rust | [`rust/l/linpack_lu_solve.rs`](../../../rust/l/linpack_lu_solve.rs) |
| V | [`v/l/linpack_lu_solve.v`](../../../v/l/linpack_lu_solve.v) |
| Zig | [`zig/l/linpack_lu_solve.zig`](../../../zig/l/linpack_lu_solve.zig) |

The independent oracle is [`linpack_lu_solve_oracle.py`](../../linpack_lu_solve_oracle.py). The workload uses `i64_array_float64`; see [`workload.json`](workload.json).
