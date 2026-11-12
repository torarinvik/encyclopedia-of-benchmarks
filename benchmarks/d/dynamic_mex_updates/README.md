# Dynamic MEX with point updates

Maintain an integer sequence under point replacements and report its current
minimum excluded nonnegative value (MEX) after every replacement. Values may
be negative or larger than the sequence length; they do not occupy positions
in the bounded MEX domain `0..N`.

## Contract

The byte-output ABI symbol is `dynamic_mex_updates`. Input is the signed 64-bit
array `[N,Q,initial_values...,(index,new_value)*Q]`. Bounds are `1<=N<=32`,
`0<=Q<=32`, and all initial and replacement values are in `[-1000,1000]`.
Indices are zero-based and must satisfy `0<=index<N`. The exact input length is
`2+N+2Q`; the maximum valid length is 98 words, with 99 parseable words allowed
to detect trailing input. Invalid or out-of-profile input returns `-1`.

Successful calls write the MEX after each update as one signed 64-bit
little-endian value, then return the number of bytes written. The maximum output
is 256 bytes. A null output or insufficient capacity for a nonempty output
returns `-2` without writing; a valid trace with `Q=0` succeeds with zero bytes.
The workspace capacity recorded for the runner is 256 bytes.

The primary algorithm tracks frequencies for values `0..N`, and a segment tree
stores how many distinct values are present in each value interval. A point
replacement changes a tree leaf only when a frequency crosses zero. The MEX is
found by descending into the first interval whose occupied count is smaller
than its width. Since an array of N values cannot contain every one of the
N+1 candidates, the MEX always lies in this domain. Initial construction is
`O(N log N)`; each update and MEX query takes `O(log N)` time and `O(N)` space.
The independent oracle scans the current array for each candidate after every
update in `O(QN)` time.

## Distinctness and provenance

[`mex`](../../m/mex/README.md) computes one static MEX by sorting a copy of the
input; this package measures repeated MEX queries under point updates.
[`point_set_range_frequency`](../../p/point_set_range_frequency/README.md)
supports point assignments with range-frequency queries, but does not maintain
the first missing nonnegative value.

The dynamic operation and segment-tree/frequency approach are described in
[CP-Algorithms, “MEX (minimal excluded) of a sequence”](https://cp-algorithms.com/sequences/mex.html),
licensed under CC BY-SA 4.0. The bounded ABI, workload, direct-scan oracle, and
ten ports are clean-room work; no source code, prose, tests, or examples were
copied. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../dynamic_mex_updates_oracle.py), the
[independent verifier](../../dynamic_mex_updates_verifier_oracle.py), and the
[static inventory checker](../../check_dynamic_mex_updates_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/dynamic_mex_updates.c`](../../../c/d/dynamic_mex_updates.c) |
| C3 | [`c3/d/dynamic_mex_updates.c3`](../../../c3/d/dynamic_mex_updates.c3) |
| C++ | [`cpp/d/dynamic_mex_updates.cpp`](../../../cpp/d/dynamic_mex_updates.cpp) |
| Elisa | [`elisa/d/dynamic_mex_updates.elisa`](../../../elisa/d/dynamic_mex_updates.elisa) |
| Mojo | [`mojo/d/dynamic_mex_updates.mojo`](../../../mojo/d/dynamic_mex_updates.mojo) |
| Nim | [`nim/d/dynamic_mex_updates.nim`](../../../nim/d/dynamic_mex_updates.nim) |
| Odin | [`odin/d/dynamic_mex_updates.odin`](../../../odin/d/dynamic_mex_updates.odin) |
| Rust | [`rust/d/dynamic_mex_updates.rs`](../../../rust/d/dynamic_mex_updates.rs) |
| V | [`v/d/dynamic_mex_updates.v`](../../../v/d/dynamic_mex_updates.v) |
| Zig | [`zig/d/dynamic_mex_updates.zig`](../../../zig/d/dynamic_mex_updates.zig) |
