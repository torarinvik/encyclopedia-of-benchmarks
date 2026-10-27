# Transit-node routing table query

This bounded profile implements the chapter's far-query transit-node table
lookup. It accepts a query already classified as nonlocal by the source's
locality filter and evaluates the source formula
`min_{u∈A⁺(s),v∈A⁻(t)} d(s,u)+d(u,v)+d(v,t)`.

Input is a signed-i64 array:

```text
[transit_count, source_id, target_id, far_flag,
 forward_count, (forward_access_id,d(source,access))...,
 backward_count, (backward_access_id,d(access,target))...,
 transit_count*transit_count directed distances in row-major order]
```

There are 1–8 transit nodes, 1–4 access nodes in each direction, and all IDs
are in `[0,transit_count)`. `far_flag` must be 1, meaning the supplied locality
filter result is `¬L(s,t)`. Distances are bounded nonnegative integers at most
1,000,000; diagonal transit distances must be zero. The profile consumes
precomputed access sets and distance tables and does not construct the road
network, transit hierarchy, or locality filter.

Output is little-endian signed-i64 `[distance,forward_access_id,backward_access_id]`.
Minimum distance wins; equal-distance witnesses choose the lexicographically
smallest `(forward_id,backward_id)`. Input is bounded to 86 words; output is 24
bytes; fixed workspace is 4096 bytes. Invalid input returns `-1`; null output
or insufficient capacity returns `-2` without writes.

Source: Dominik Schultes, “Routing in Road Networks with Transit Nodes,”
Encyclopedia of Algorithms, DOI 10.1007/978-1-4939-2864-4_353,
`OEBPS/AChap353.html`, Key Results. The chapter defines the access-node table
formula and says it is exact when the locality filter rejects the query. It
does not specify one canonical locality filter; the profile accepts its
far/local decision as input. No source-code license is asserted; these are
clean-room implementations.

Primary and independent verifier oracles:
`benchmarks/transit_node_routing_table_query_oracle.py` and
`benchmarks/transit_node_routing_table_query_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/t/transit_node_routing_table_query.c` |
| C3 | `c3/t/transit_node_routing_table_query.c3` |
| C++ | `cpp/t/transit_node_routing_table_query.cpp` |
| Elisa | `elisa/t/transit_node_routing_table_query.elisa` |
| Nim | `nim/t/transit_node_routing_table_query.nim` |
| Odin | `odin/t/transit_node_routing_table_query.odin` |
| Rust | `rust/t/transit_node_routing_table_query.rs` |
| V | `v/t/transit_node_routing_table_query.v` |
| Zig | `zig/t/transit_node_routing_table_query.zig` |
