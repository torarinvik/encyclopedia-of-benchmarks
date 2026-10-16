# Euler degree parity check

This benchmark ports the pinned C `hasEulerPath` helper, which checks only the vertex-degree parity condition for a proposed undirected Euler-trail start and end. Input is `[vertex_count, start, end, edge_count, u_0, v_0, ...]` for a simple graph with 1–32 vertices and at most 256 edges. The result is 1 when the proposed endpoints have the required odd degrees (both endpoints odd when distinct, every vertex even when equal), and 0 otherwise.

The helper does not test graph connectivity; the result deliberately preserves that source behavior. Malformed dimensions, invalid vertices, loops, and duplicate edges return -2. The interactive graph-building prompt in the pinned C program is omitted. See the [pinned C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/euler.c).
