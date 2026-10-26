# DC-Tree k-server on a path

This package implements the chapter's DC-Tree request rule on the special
case of a unit-edge path. For each request, one lowest-index server at every
occupied location is active. All active servers move continuously toward the
request at equal unit speed until the first one arrives; collisions at the
request leave co-located servers for the next request, where the lowest index
is active. With integer initial positions and integer requests on the path,
the first-arrival time and resulting positions remain integral.

## Contract

The ABI is `i64_array_bytes_output`, symbol `dc_tree_k_server_path`. Input is
`[k,q,initial_position[k],request[q]]`, with `k` in 2..4, `q` in 1..12, and
all coordinates in 0..15. Each request produces `[movement_cost,
position_0,...,position_(k-1)]`. Movement cost is the sum of distances moved
by all active servers in that request. Output is little-endian signed 64-bit
words; success returns `8*q*(k+1)` bytes. Malformed input returns `-1`
before output checks. Null output or insufficient capacity returns `-2`
without writes. Maximum input is 18 words and maximum output is 480 bytes.

The path restriction preserves the chapter's simultaneous equal-speed
movement rule while avoiding arbitrary branch geometry. It does not implement
the competitive-analysis proof. [`work_function_k_server`](../work_function_k_server/README.md)
uses a finite-metric work-function strategy, which is a different algorithm.

## Source and rights

Based on Marek Chrobak, “Algorithm DC-Tree for k-Servers on Trees,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_7`](https://doi.org/10.1007/978-1-4939-2864-4_7).
The chapter defines the active-server rule and equal-speed motion toward each
request. These ports independently implement the bounded path profile and
contain no copied book prose or code. See [`RIGHTS.md`](RIGHTS.md).

Fixtures are in [`workload.json`](workload.json), with primary oracle
[`dc_tree_k_server_path_oracle.py`](../../dc_tree_k_server_path_oracle.py)
and independent verifier
[`dc_tree_k_server_path_verifier_oracle.py`](../../dc_tree_k_server_path_verifier_oracle.py).

Language ports: `c/d/dc_tree_k_server_path.c`,
`c3/d/dc_tree_k_server_path.c3`, `cpp/d/dc_tree_k_server_path.cpp`,
`elisa/d/dc_tree_k_server_path.elisa`, `nim/d/dc_tree_k_server_path.nim`,
`odin/d/dc_tree_k_server_path.odin`, `rust/d/dc_tree_k_server_path.rs`,
`v/d/dc_tree_k_server_path.v`, and `zig/d/dc_tree_k_server_path.zig`.
