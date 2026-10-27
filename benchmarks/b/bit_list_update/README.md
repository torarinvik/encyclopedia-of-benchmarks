# Bit List Update

This bounded profile implements the chapter's randomized Bit policy. Each
item starts with a supplied bit representing one fixed sample from the
source's independent uniform initialization. On access, the item bit is
complemented; if it becomes 1, that item moves to the front using free
exchanges.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,request_count,initial_order[n],request_ids[request_count],initial_bits[n]]`,
with 1–8 items and 0–32 requests. Bits are listed by item ID and must be 0 or
1. Output is
`[total_access_cost,final_order[n],pre_access_positions[q],final_bits[n]]`,
encoded as little-endian signed 64-bit words, with at most 392 bytes. Access
cost is the 1-based position before the bit toggle. Malformed input returns
`-1`; null output or insufficient capacity returns `-2` without writes.

The supplied initial bit vector makes each randomized initialization
reproducible; uniformly sampled vectors preserve the source's initialization
distribution. The primary oracle moves an item to the front when its toggled
bit becomes 1. The independent verifier tracks item positions explicitly.

Source: Shahin Kamali, “Online List Update,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_266`](https://doi.org/10.1007/978-1-4939-2864-4_266).
This is clean-room code; no book source or prose was copied. See
[workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the [primary
oracle](../../bit_list_update_oracle.py), and the [independent
verifier](../../bit_list_update_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/b/bit_list_update.c`](../../../c/b/bit_list_update.c) |
| C3 | [`c3/b/bit_list_update.c3`](../../../c3/b/bit_list_update.c3) |
| C++ | [`cpp/b/bit_list_update.cpp`](../../../cpp/b/bit_list_update.cpp) |
| Elisa | [`elisa/b/bit_list_update.elisa`](../../../elisa/b/bit_list_update.elisa) |
| Nim | [`nim/b/bit_list_update.nim`](../../../nim/b/bit_list_update.nim) |
| Odin | [`odin/b/bit_list_update.odin`](../../../odin/b/bit_list_update.odin) |
| Rust | [`rust/b/bit_list_update.rs`](../../../rust/b/bit_list_update.rs) |
| V | [`v/b/bit_list_update.v`](../../../v/b/bit_list_update.v) |
| Zig | [`zig/b/bit_list_update.zig`](../../../zig/b/bit_list_update.zig) |
