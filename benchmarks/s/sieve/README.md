# Shootout Sieve

This package ports the lac-dcc Shootout sieve benchmark. It retains the source's repeated byte-flag sieve over the fixed inclusive range 2 through 8192 and the exact ASCII output line.

## Source and contract

Pinned source: [`Shootout/sieve/sieve.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/sieve.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The pinned [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/info.sh) supplies no run options. The source defaults to 170,000 sieve passes, or 17,000 with `SMALL_PROBLEM_SIZE`.

The exported function accepts the pass count. The suite bounds it to 0..64 so all nine implementations remain practical to measure. Each pass resets the count and sets flags from 2 through 8192, then scans upward; each still-set value is counted and its multiples are cleared beginning at twice that value. Zero passes produce `Count: 0\n`. Every positive bounded pass count produces `Count: 1028\n`, since 1028 primes lie in the fixed range. The upstream default has the same result, but is recorded as source metadata rather than run in the bounded workload.

Invalid counts below zero or above 64 return -1 without output. A null output pointer or insufficient capacity returns -2 without writing. Valid results are the exact bytes from the source's `printf("Count: %d\n", count)`.

## Workload and oracle

[`workload.json`](workload.json) includes zero, small, and maximum bounded pass counts, invalid signed inputs, and output-buffer errors. [`shootout_sieve_oracle.py`](../../shootout_sieve_oracle.py) computes the count through 8192 by trial division, independently of the source's repeated sieve, then formats the exact stdout line. The shared `i64_scalar_bytes_output` runner and verifier check the bounded workload and buffer contract.

The pinned source has no explicit license notice; these are independently written ports.

| Language | Source |
| --- | --- |
| C | [`c/s/sieve.c`](../../../c/s/sieve.c) |
| C3 | [`c3/s/sieve.c3`](../../../c3/s/sieve.c3) |
| C++ | [`cpp/s/sieve.cpp`](../../../cpp/s/sieve.cpp) |
| Elisa | [`elisa/s/sieve.elisa`](../../../elisa/s/sieve.elisa) |
| Nim | [`nim/s/sieve.nim`](../../../nim/s/sieve.nim) |
| Odin | [`odin/s/sieve.odin`](../../../odin/s/sieve.odin) |
| Rust | [`rust/s/sieve.rs`](../../../rust/s/sieve.rs) |
| V | [`v/s/sieve.v`](../../../v/s/sieve.v) |
| Zig | [`zig/s/sieve.zig`](../../../zig/s/sieve.zig) |
