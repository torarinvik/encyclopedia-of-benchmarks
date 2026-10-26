# Counting-triangle stream: uniform edge reservoir

This package isolates the uniform-edge reservoir primitive used by the
single-pass triangle-stream algorithm described in Chapter 705. It measures
the reservoir update schedule and returns the two slot contents after every
edge. It does not implement the later closed-wedge sampling or claim a
triangle-count/transitivity accuracy bound.

## Contract

The ABI is `i64_array_bytes_output`, symbol
`counting_triangles_stream_reservoir`. Input is
`[n,m,(u,v)[m],draw[2*m]]`, where edges are distinct canonical undirected
edges on vertices `0..n-1`. `n` is 2..8 and `m` is 1..28. The two draws for
stream position `t` are independent uniform-integer sample outcomes in
`0..t-1`; a draw of zero replaces that slot with the current edge. This is a
discrete bounded realization of the chapter's independent per-slot
reservoir update (`x <= 1/t`).

For each prefix, output both slots in order as `(u,v)` pairs, flattened by
prefix, in little-endian signed 64-bit words. Both slots contain the first
edge after prefix one. Success returns `16*m` bytes. Malformed input returns
`-1` before output checks; null output or capacity below `16*m` returns `-2`
without writes. Maximum input length is 114 words; maximum output is 448
bytes.

## Source and limits

Based on Madhav Jha, “Counting Triangles in Graph Streams,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_705`](https://doi.org/10.1007/978-1-4939-2864-4_705).
The chapter describes maintaining `k` independent slots, replacing a slot
with the current edge with probability `1/t`. The package fixes `k=2` and
supplies the discrete random outcomes as input so the benchmark is
reproducible. It is not the full wedge estimator. Attribution and rights
scope are in [`RIGHTS.md`](RIGHTS.md).

See [`workload.json`](workload.json), primary oracle
[`counting_triangles_stream_reservoir_oracle.py`](../../counting_triangles_stream_reservoir_oracle.py),
and independent verifier
[`counting_triangles_stream_reservoir_verifier_oracle.py`](../../counting_triangles_stream_reservoir_verifier_oracle.py).
