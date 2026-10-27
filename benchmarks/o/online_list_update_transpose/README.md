# Online List Update by Transposition

This bounded profile implements the chapter's Transpose (`Trans`) list-update
algorithm: after accessing an item, swap it with its predecessor so it moves
one position closer to the front. This is distinct from Move-to-Front, which
moves the item to the front using a free exchange.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,request_count,initial_order[n],request_ids[request_count]]`, with 1–8
items and 0–32 requests. The initial order must be a permutation of item IDs
`0..n-1`, and every requested ID must be in that range.

For each request, the access cost is the item's 1-based position before the
update. If it is not already first, the algorithm swaps it with the preceding
item and adds one paid adjacent-exchange cost. An item already at the front
does not move and incurs no exchange cost. The output is
`[total_cost,final_order[n],pre_swap_access_positions[request_count]]` in
little-endian signed 64-bit words, with at most 328 bytes. Malformed input
returns `-1`; a null output or insufficient capacity returns `-2` without
writes.

The primary oracle simulates the list directly. The independent verifier
tracks each item's current position and updates only the two positions
affected by a paid exchange. The workload includes an access at the front
without exchange and repeated accesses that advance one position per request.

The chapter also discusses Frequency Count, Timestamp, and randomized Bit
and Comb policies; those policies are not part of this package. The local
[Move-to-Front profile](../m/move_to_front/README.md) covers the chapter's MTF
algorithm, while this package covers Transpose.

## Workload and ports

See [workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the
[primary oracle](../../online_list_update_transpose_oracle.py), and the
[independent verifier](../../online_list_update_transpose_verifier_oracle.py).

| Language | Port |
| --- | --- |
| C | [`c/o/online_list_update_transpose.c`](../../../c/o/online_list_update_transpose.c) |
| C3 | [`c3/o/online_list_update_transpose.c3`](../../../c3/o/online_list_update_transpose.c3) |
| C++ | [`cpp/o/online_list_update_transpose.cpp`](../../../cpp/o/online_list_update_transpose.cpp) |
| Elisa | [`elisa/o/online_list_update_transpose.elisa`](../../../elisa/o/online_list_update_transpose.elisa) |
| Nim | [`nim/o/online_list_update_transpose.nim`](../../../nim/o/online_list_update_transpose.nim) |
| Odin | [`odin/o/online_list_update_transpose.odin`](../../../odin/o/online_list_update_transpose.odin) |
| Rust | [`rust/o/online_list_update_transpose.rs`](../../../rust/o/online_list_update_transpose.rs) |
| V | [`v/o/online_list_update_transpose.v`](../../../v/o/online_list_update_transpose.v) |
| Zig | [`zig/o/online_list_update_transpose.zig`](../../../zig/o/online_list_update_transpose.zig) |
