# Comb List Update

This bounded profile implements the chapter's randomized Comb policy. For
each request, an independent supplied uniform draw in `0..4` selects the Bit
policy for values 0–3 (probability 0.8) or Timestamp for value 4 (probability
0.2). The Bit component has a supplied uniformly sampled initial bit for each
item and toggles that bit only when Bit is selected. Timestamp decisions use
the full request history, including requests served by the Bit branch.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,request_count,initial_order[n],request_ids[request_count],initial_bits[n],mode_draws[request_count]]`,
with 1–8 items and 0–32 requests. Each mode draw must be 0–4. Bit initialization
is supplied by item ID. Output is
`[total_access_cost,final_order[n],pre_access_positions[q],final_bits[n]]`,
as little-endian signed 64-bit words, with at most 392 bytes. Malformed input
returns `-1`; null output or insufficient capacity returns `-2` without
writes.

At every request, the selected policy sees the current shared list. Timestamp
counts intervening requests in the complete request trace; Bit state changes
only on a Bit-selected request. This makes the hybrid's mixed component state
explicit and reproducible from its supplied random tapes.
The suite source defines exhaustive small mixed Bit/Timestamp traces, compares
both references, and checks the all-Timestamp case against the Timestamp
profile. These checks are unexecuted.

For n items and q requests, the direct Timestamp history scans give this
bounded implementation an O(nq²+nq) worst-case time bound and O(n+q)
space, including its request history and output trace.

Source: Shahin Kamali, “Online List Update,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_266`](https://doi.org/10.1007/978-1-4939-2864-4_266).
This is clean-room code; no book source or prose was copied. See
[workload.json](workload.json), [RIGHTS.md](RIGHTS.md), the [primary
oracle](../../comb_list_update_oracle.py), and the [independent
verifier](../../comb_list_update_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/b/comb_list_update.c`](../../../c/b/comb_list_update.c) |
| C3 | [`c3/b/comb_list_update.c3`](../../../c3/b/comb_list_update.c3) |
| C++ | [`cpp/b/comb_list_update.cpp`](../../../cpp/b/comb_list_update.cpp) |
| Elisa | [`elisa/b/comb_list_update.elisa`](../../../elisa/b/comb_list_update.elisa) |
| Mojo | [`mojo/c/comb_list_update.mojo`](../../../mojo/c/comb_list_update.mojo) (unverified draft) |
| Nim | [`nim/b/comb_list_update.nim`](../../../nim/b/comb_list_update.nim) |
| Odin | [`odin/b/comb_list_update.odin`](../../../odin/b/comb_list_update.odin) |
| Rust | [`rust/b/comb_list_update.rs`](../../../rust/b/comb_list_update.rs) |
| V | [`v/b/comb_list_update.v`](../../../v/b/comb_list_update.v) |
| Zig | [`zig/b/comb_list_update.zig`](../../../zig/b/comb_list_update.zig) |
