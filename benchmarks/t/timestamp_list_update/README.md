# Timestamp List Update

This bounded profile implements the chapter's Timestamp policy. After an
access to item `x`, it moves `x` immediately before the first item `y` that
currently precedes `x` and has been requested at most once since the previous
request to `x`. If `x` has not previously appeared, or no preceding item
qualifies, the list is unchanged. Every request in the trace contributes to
the timestamp history.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,request_count,initial_order[n],request_ids[request_count]]`, with 1–8 items
and 0–32 requests. The initial order is a permutation of IDs `0..n-1`. The
output is `[total_access_cost,final_order[n],pre_access_positions[q]]`, as
little-endian signed 64-bit words, with at most 328 bytes. The access cost is
the 1-based position immediately before each request; the Timestamp
reorganization uses free exchanges. Malformed input returns `-1`; null output
or insufficient capacity returns `-2` without writes.

The primary oracle scans the bounded request trace between repeated requests
to `x`. The independent verifier stores each item's occurrence times and
counts those strictly between the previous and current request to `x`.

Source: Shahin Kamali, “Online List Update,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_266`](https://doi.org/10.1007/978-1-4939-2864-4_266).
This is a clean-room profile; no book code or prose was copied. See
[workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the [primary
oracle](../../timestamp_list_update_oracle.py), and the [independent
verifier](../../timestamp_list_update_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/t/timestamp_list_update.c`](../../../c/t/timestamp_list_update.c) |
| C3 | [`c3/t/timestamp_list_update.c3`](../../../c3/t/timestamp_list_update.c3) |
| C++ | [`cpp/t/timestamp_list_update.cpp`](../../../cpp/t/timestamp_list_update.cpp) |
| Elisa | [`elisa/t/timestamp_list_update.elisa`](../../../elisa/t/timestamp_list_update.elisa) |
| Nim | [`nim/t/timestamp_list_update.nim`](../../../nim/t/timestamp_list_update.nim) |
| Odin | [`odin/t/timestamp_list_update.odin`](../../../odin/t/timestamp_list_update.odin) |
| Rust | [`rust/t/timestamp_list_update.rs`](../../../rust/t/timestamp_list_update.rs) |
| V | [`v/t/timestamp_list_update.v`](../../../v/t/timestamp_list_update.v) |
| Zig | [`zig/t/timestamp_list_update.zig`](../../../zig/t/timestamp_list_update.zig) |
