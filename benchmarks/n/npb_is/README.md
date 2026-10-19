# NAS Parallel Benchmarks Integer Sort (NPB IS)

This package ports the class-W integer sort from the pinned NAS Parallel Benchmarks serial IS source. It preserves the 46-bit random key generation, bucket distribution, exact-key histogram and prefix ranking, the five partial-rank checks, and the final full-order verification.

## Source and bounded contract

The source is [`NPB-serial/is/is.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/is.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/info.sh) builds `is.c` without default compile flags or run options. When `SMALL_PROBLEM_SIZE` is set, it adds `-DSMALL_PROBLEM_SIZE`; the source then selects class W. This package fixes that bounded class-W profile: 1,048,576 keys, a key range of 0 through 65,535, 1,024 buckets, and ten source iterations.

The exported function `npb_is` accepts `pass_count` from 1 through 10 using input encoding `npb_is_class_w_ascii`. It generates the base keys once from seed `314159265` and multiplier `1220703125` using four 46-bit LCG states per key. It performs the source's warm-up `rank(1)`, then source-equivalent passes `1..pass_count`, retaining the in-place test-key updates between passes. Each pass emits the five partial ranks as comma-separated signed decimal values followed by LF using output encoding `npb_is_partial_ranks_csv_ascii`. A final line contains the verification count; a successful prefix run reports `5 * pass_count + 1`.

Invalid pass counts return -1. A null output or capacity shorter than the exact serialized result returns -2 without writing. The maximum output is 353 bytes for all ten passes. The ports use the `i64_scalar_bytes_output` ABI family.

## Oracle and workload

[`workload.json`](workload.json) records the pinned source, class-W launcher profile, byte-output contract, and boundary fixtures. [`npb_is_oracle.py`](../../npb_is_oracle.py) uses integer modular arithmetic for the 46-bit LCG and a direct frequency histogram for partial ranks. It does not implement the source's bucket scatter; it sorts the final keys separately for the full-order check.

The repository already has [`benchmarks/i/is`](../i/is), which is the unrelated Lua `uint53_is` predicate. This package has the distinct `npb_is` name to avoid colliding with that algorithm.

The pinned source grants permission to use, copy, distribute, and modify the software for any purpose, with or without fee. It requests that derived work reference NAS Parallel Benchmarks 3.3 and includes an as-is warranty disclaimer; these ports are independently written.

| Language | Port |
|---|---|
| C | [`c/n/npb_is.c`](../../../c/n/npb_is.c) |
| C3 | [`c3/n/npb_is.c3`](../../../c3/n/npb_is.c3) |
| C++ | [`cpp/n/npb_is.cpp`](../../../cpp/n/npb_is.cpp) |
| Elisa | [`elisa/n/npb_is.elisa`](../../../elisa/n/npb_is.elisa) |
| Nim | [`nim/n/npb_is.nim`](../../../nim/n/npb_is.nim) |
| Odin | [`odin/n/npb_is.odin`](../../../odin/n/npb_is.odin) |
| Rust | [`rust/n/npb_is.rs`](../../../rust/n/npb_is.rs) |
| V | [`v/n/npb_is.v`](../../../v/n/npb_is.v) |
| Zig | [`zig/n/npb_is.zig`](../../../zig/n/npb_is.zig) |
