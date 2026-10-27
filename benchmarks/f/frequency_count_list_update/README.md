# Frequency Count List Update

This bounded profile implements the chapter's Frequency Count (`Fc`) policy.
It maintains each item's request count and moves a requested item toward the
front past items with strictly lower counts. Equal-count items keep their
current relative order, giving deterministic stable ties.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,request_count,initial_order[n],request_ids[request_count]]`, with 1–8 items
and 0–32 requests. The initial order must be a permutation of item IDs
`0..n-1`, and requests must use those IDs. Before updating the count/order,
each request records its 1-based access position and adds that position to the
total cost. Reorganization uses free exchanges under the list-update model.

Output is `[total_access_cost,final_order[n],pre_access_positions[q]]`, encoded
as little-endian signed 64-bit words, with at most 328 bytes. Malformed input
returns `-1`; null output or insufficient capacity returns `-2` without
writes. The primary oracle bubbles by frequency; the independent verifier
rebuilds the order with a stable frequency sort after each request.

Source: Shahin Kamali, “Online List Update,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_266`](https://doi.org/10.1007/978-1-4939-2864-4_266).
This is a clean-room profile; no book code or prose was copied. See
[workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the [primary
oracle](../../frequency_count_list_update_oracle.py), and the [independent
verifier](../../frequency_count_list_update_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/f/frequency_count_list_update.c`](../../../c/f/frequency_count_list_update.c) |
| C3 | [`c3/f/frequency_count_list_update.c3`](../../../c3/f/frequency_count_list_update.c3) |
| C++ | [`cpp/f/frequency_count_list_update.cpp`](../../../cpp/f/frequency_count_list_update.cpp) |
| Elisa | [`elisa/f/frequency_count_list_update.elisa`](../../../elisa/f/frequency_count_list_update.elisa) |
| Nim | [`nim/f/frequency_count_list_update.nim`](../../../nim/f/frequency_count_list_update.nim) |
| Odin | [`odin/f/frequency_count_list_update.odin`](../../../odin/f/frequency_count_list_update.odin) |
| Rust | [`rust/f/frequency_count_list_update.rs`](../../../rust/f/frequency_count_list_update.rs) |
| V | [`v/f/frequency_count_list_update.v`](../../../v/f/frequency_count_list_update.v) |
| Zig | [`zig/f/frequency_count_list_update.zig`](../../../zig/f/frequency_count_list_update.zig) |
