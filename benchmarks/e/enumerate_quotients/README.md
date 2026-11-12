# Enumerate Quotients

For a positive integer `n`, enumerate the distinct values of `floor(n / x)` in increasing `x` order. Each quotient remains constant on a contiguous block of `x` values. The algorithm jumps directly from one block to the next, so it visits only `O(√n)` blocks rather than scanning all `n` possible divisors. The [Library Checker problem](https://judge.yosupo.jp/problem/enumerate_quotients) uses this operation; its accepted implementations emit the quotient values in order.

## Contract

The input is one signed 64-bit integer `n` in `1..=100,000`. The benchmark bounds the problem's larger input domain to fit the single-call byte-output ABI while retaining the quotient-block algorithm. For `left = 1, 2, ...`, compute `q = floor(n / left)`, emit `q` once, then jump to `floor(n / q) + 1`. Output begins with the number of distinct values as a signed 64-bit little-endian word, followed by those quotient values in signed 64-bit little-endian words, ordered by the first `x` in each block. The function returns the number of output bytes, returns `-1` for invalid `n`, and returns `-2` if the output buffer is null or too small. It makes two quotient passes so it can check capacity before writing anything. The ports implement the described quotient-block algorithm independently; they do not reuse upstream source code.

Time complexity is `O(√n)` and auxiliary storage is `O(1)`. For example, `n=10` produces count `5` followed by `10, 5, 3, 2, 1`.

See [`workload.json`](workload.json) for fixtures and [`benchmarks/enumerate_quotients_oracle.py`](../../enumerate_quotients_oracle.py) for a direct oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/enumerate_quotients.c`](../../../c/e/enumerate_quotients.c) |
| C3 | [`c3/e/enumerate_quotients.c3`](../../../c3/e/enumerate_quotients.c3) |
| C++ | [`cpp/e/enumerate_quotients.cpp`](../../../cpp/e/enumerate_quotients.cpp) |
| Elisa | [`elisa/e/enumerate_quotients.elisa`](../../../elisa/e/enumerate_quotients.elisa) |
| Mojo | [`mojo/e/enumerate_quotients.mojo`](../../../mojo/e/enumerate_quotients.mojo) |
| Nim | [`nim/e/enumerate_quotients.nim`](../../../nim/e/enumerate_quotients.nim) |
| Odin | [`odin/e/enumerate_quotients.odin`](../../../odin/e/enumerate_quotients.odin) |
| Rust | [`rust/e/enumerate_quotients.rs`](../../../rust/e/enumerate_quotients.rs) |
| V | [`v/e/enumerate_quotients.v`](../../../v/e/enumerate_quotients.v) |
| Zig | [`zig/e/enumerate_quotients.zig`](../../../zig/e/enumerate_quotients.zig) |
