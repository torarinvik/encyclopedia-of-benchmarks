# XOR filter peeling

This draft builds one static three-slot XOR filter from supplied hash outcomes.
It counts incident keys at each slot, peels degree-one slots, and assigns
fingerprints in reverse peel order. Query fingerprints are compared with the
XOR of the three resulting slot values. The online bit-setting Bloom filter
and exact cuckoo hash map use different construction and query algorithms.

The intended `i64_array_scalar` input is
`[n,s,q,(u,v,w,f)*n,(u,v,w,f)*q]`. There are `0<=n,q<=32` records and
`3<=s<=96` slots. Each record has three pairwise-distinct slot indices in
`0..s-1` and an 8-bit fingerprint `f` in `0..255`. Exact frame length is
`3+4*n+4*q`, at most 259 values. All records are validated before construction.
Null or malformed input returns -1; an unpeelable graph returns -2.

Initial degree-one slots enter a FIFO in increasing slot order. When an edge
is removed, its slots are decremented in `u,v,w` order; any newly degree-one
slot is appended. A queued slot that has since become empty is skipped.
For each removed edge, its triggering slot and edge index are stored.
After a successful peel, initialize all slot fingerprints to zero and replay
the stack backward, setting the triggering slot to the record fingerprint
XOR the other two slot fingerprints. Return the sum of one-based query
indices for which the slot XOR equals that query's fingerprint; an empty query
set returns zero.

The bounded construction takes `O(s+n)` time and space, and each query takes
constant time. Caller-supplied positions and fingerprints avoid fixing an
upstream hash or retry policy; consequently this profile makes no probabilistic
false-positive-rate claim. Graphs that fail to peel are reported rather than
rehashed. Graf and Lemire's [*Xor Filters: Faster and Smaller Than Bloom and
Cuckoo Filters*](https://arxiv.org/abs/1912.08258) supplies the algorithmic
idea only; code, contract, and cases are independently written.

Ten language drafts, two references, workload, inventory checker, and scalar
suite integration are present. The verifier source specifies small three-slot
graphs, a maximum frame, and null inputs. The Elisa draft uses a bounded view
and indexed arrays. Each slot is queued at most once because its degree only
decreases, so the 96-entry FIFO suffices. Verifier source additionally covers
slot permutations and checks that successful builds recognize all supplied
records. Nothing has been compiled or run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/x/xor_filter_peeling.c) |
| C3 | [C3](../../../c3/x/xor_filter_peeling.c3) |
| C++ | [C++](../../../cpp/x/xor_filter_peeling.cpp) |
| Elisa | [Elisa](../../../elisa/x/xor_filter_peeling.elisa) |
| Mojo | [Mojo](../../../mojo/x/xor_filter_peeling.mojo) |
| Nim | [Nim](../../../nim/x/xor_filter_peeling.nim) |
| Odin | [Odin](../../../odin/x/xor_filter_peeling.odin) |
| Rust | [Rust](../../../rust/x/xor_filter_peeling.rs) |
| V | [V](../../../v/x/xor_filter_peeling.v) |
| Zig | [Zig](../../../zig/x/xor_filter_peeling.zig) |
