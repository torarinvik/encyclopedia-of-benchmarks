# Shootout heapsort

This package ports the generated-double heapsort from the pinned Shootout benchmark. It keeps the local linear congruential generator, the one-based max-heapsort, and the source's final maximum printed with six fractional digits.

## Source and contract

The pinned source is [`Shootout/heapsort/heapsort.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/heapsort.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/info.sh) compiles `heapsort.c`, links `-lm`, and supplies no run options. The launcher therefore uses the source default of 8,000,000 values (800,000 with `SMALL_PROBLEM_SIZE`).

The exported function accepts a bounded length from 2 through 8,192. Each call resets the generator state to 42, generates values with `state = (state * 3877 + 29573) % 139968`, stores `state / 139968.0` in one-based slots, and runs the source's one-based max-heapsort. It returns only the largest value as nine ASCII bytes in `%.6f\n` form. The state is local to each call so repeated suite calls match separate launcher executions.

Invalid lengths return -1. A null output pointer or a buffer shorter than nine bytes returns -2 without writing. The source's unbounded default is documented as launcher context; suite cases use the bounded profile.

## Workload and oracle

[`workload.json`](workload.json) records the pinned launcher and bounded contract. [`shootout_heapsort_oracle.py`](../../shootout_heapsort_oracle.py) independently generates the LCG states and computes the maximum directly, without applying heapsort, then formats that live-out as the source's fixed-six decimal line. The ports use the `i64_scalar_bytes_output` ABI family.

The pinned C source has no explicit license notice; these ports are independently written.

| Language | Port |
|---|---|
| C | [`c/s/shootout_heapsort.c`](../../../c/s/shootout_heapsort.c) |
| C3 | [`c3/s/shootout_heapsort.c3`](../../../c3/s/shootout_heapsort.c3) |
| C++ | [`cpp/s/shootout_heapsort.cpp`](../../../cpp/s/shootout_heapsort.cpp) |
| Elisa | [`elisa/s/shootout_heapsort.elisa`](../../../elisa/s/shootout_heapsort.elisa) |
| Nim | [`nim/s/shootout_heapsort.nim`](../../../nim/s/shootout_heapsort.nim) |
| Odin | [`odin/s/shootout_heapsort.odin`](../../../odin/s/shootout_heapsort.odin) |
| Rust | [`rust/s/shootout_heapsort.rs`](../../../rust/s/shootout_heapsort.rs) |
| V | [`v/s/shootout_heapsort.v`](../../../v/s/shootout_heapsort.v) |
| Zig | [`zig/s/shootout_heapsort.zig`](../../../zig/s/shootout_heapsort.zig) |
