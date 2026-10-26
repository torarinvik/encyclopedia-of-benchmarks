package gbbs_maximal_matching

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_INPUT :: 194

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gbbs_maximal_matching :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT do return -1
    n64, m64 := input[0], input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != c.size_t(2+3*m64) do return -1
    m := int(m64)
    edge_start := 2+m
    rank_seen: [MAX_M]bool
    order: [MAX_M]int
    for edge := 0; edge < m; edge += 1 {
        rank64 := input[2+edge]
        if rank64 < 0 || rank64 >= m64 do return -1
        rank := int(rank64)
        if rank_seen[rank] do return -1
        rank_seen[rank] = true
        order[rank] = edge
        u64, v64 := input[edge_start+2*edge], input[edge_start+2*edge+1]
        if u64 < 0 || v64 <= u64 || v64 >= n64 do return -1
        for prior := 0; prior < edge; prior += 1 do
            if input[edge_start+2*prior] == u64 &&
                input[edge_start+2*prior+1] == v64 do return -1
    }
    output_bytes := 8*m
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    matched: [MAX_N]bool
    selected: [MAX_M]i64
    for rank := 0; rank < m; rank += 1 {
        edge := order[rank]
        u, v := int(input[edge_start+2*edge]), int(input[edge_start+2*edge+1])
        if !matched[u] && !matched[v] {
            selected[edge] = 1
            matched[u] = true
            matched[v] = true
        }
    }
    for edge := 0; edge < m; edge += 1 do store_i64_le(output, 8*edge, selected[edge])
    return i64(output_bytes)
}
