# HPCC RandomAccess

This package implements a bounded, single-process profile of the HPC Challenge RandomAccess kernel. The official [RandomAccess Rules](https://hpcchallenge.org/projectsfiles/hpcc/RandomAccess.html) define updates as 64-bit table read-modify-writes with XOR in GF(2). The HPCC source's scalar update loop in [`time_bound.c`](https://github.com/icl-utk-edu/hpcc/blob/main/RandomAccess/time_bound.c) shows the recurrence and `Table[Ran & (TABSIZE-1)] ^= Ran` operation. These ports are clean-room implementations of that operation.

## Contract

Input is the one-element signed 64-bit array `[N]`. `N` must be a power of two in `[2,256]`. Initialize the unsigned 64-bit table as `T[i]=i`, then perform exactly `4*N` updates from `ran=1`. On each update, inspect the current high bit before shifting and compute `ran = (ran << 1) XOR (high_bit ? 7 : 0)` with 64-bit wraparound; then update `T[ran & (N-1)] ^= ran`. This local profile uses the low `log2(N)` bits as the table index, matching the bounded sequential update contract; it does not implement the full MPI distribution, address-stream partitioning, lookahead, or permitted lost-update behavior of system-scale runs.

The return value is a deterministic 64-bit table digest reduced to the nonnegative signed range: compute `sum((i+1)*T[i])` in unsigned 64-bit arithmetic and clear the high bit. Invalid input returns `-1`. The high bit is cleared so that this digest cannot be confused with the invalid-input result in the scalar ABI. This weighted reduction makes the observable result depend on both the final table values and their positions.

The kernel uses `O(N)` table storage and `O(N)` update work. The maximum table contains 256 words and the maximum update count is 1024. This bounded profile preserves the RandomAccess update kernel but does not claim to reproduce a full HPCC GUPS result or a distributed-memory run.

## Distinction from the local LFSR package

[`lfsr`](../../l/lfsr/README.md) benchmarks a configurable A5-style register transition and returns generated output bits and its final register state. HPCC RandomAccess uses a fixed LFSR only to produce the update stream; its measured operation is a repeated pseudorandom indexed read-modify-write over a 64-bit table, followed by a table digest. The table kernel is therefore a distinct integrated workload, not another standalone LFSR benchmark.

## Oracle and workload

The [Python oracle](../../hpcc_random_access_oracle.py) initializes a dense bounded table and computes the specified digest. A separate [verifier oracle](../../hpcc_random_access_verifier_oracle.py) tracks only entries that differ from their initial value. The [workload](workload.json) records the scalar ABI, bounds, official HPCC sources, and hand-derived small fixtures. The fixtures include `N=16`, whose 64th update exercises the polynomial feedback bit.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/hpcc_random_access.c`](../../../c/r/hpcc_random_access.c) |
| C3 | [`c3/r/hpcc_random_access.c3`](../../../c3/r/hpcc_random_access.c3) |
| C++ | [`cpp/r/hpcc_random_access.cpp`](../../../cpp/r/hpcc_random_access.cpp) |
| Elisa | [`elisa/r/hpcc_random_access.elisa`](../../../elisa/r/hpcc_random_access.elisa) |
| Mojo | [`mojo/r/hpcc_random_access.mojo`](../../../mojo/r/hpcc_random_access.mojo) |
| Nim | [`nim/r/hpcc_random_access.nim`](../../../nim/r/hpcc_random_access.nim) |
| Odin | [`odin/r/hpcc_random_access.odin`](../../../odin/r/hpcc_random_access.odin) |
| Rust | [`rust/r/hpcc_random_access.rs`](../../../rust/r/hpcc_random_access.rs) |
| V | [`v/r/hpcc_random_access.v`](../../../v/r/hpcc_random_access.v) |
| Zig | [`zig/r/hpcc_random_access.zig`](../../../zig/r/hpcc_random_access.zig) |
