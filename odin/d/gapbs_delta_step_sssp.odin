// Clean-room bounded GAPBS delta-stepping profile; see package LICENSE.txt.
package gapbs_delta_step_sssp

import "core:c"

MAX_N :: 16
MAX_M :: 64
MAX_BUCKETS :: 481
MAX_EVENTS :: 8192
INF_DISTANCE :: i64(1_073_741_823)

append_event :: proc(bucket, vertex: int, heads, tails: ^[MAX_BUCKETS]int,
    event_vertex, event_next: ^[MAX_EVENTS]int, used: ^int) -> bool {
    if bucket < 0 || bucket >= MAX_BUCKETS || used^ >= MAX_EVENTS do return false
    event := used^
    used^ += 1
    event_vertex^[event] = vertex
    event_next^[event] = -1
    if heads^[bucket] < 0 do heads^[bucket] = event
    else do event_next^[tails^[bucket]] = event
    tails^[bucket] = event
    return true
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
gapbs_delta_step_sssp :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 196 do return -1
    n64, m64, source64, delta := input[0], input[1], input[2], input[3]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || source64 < 0 ||
        source64 >= n64 || delta < 1 || delta > 16 || length != c.size_t(4+3*m64) do return -1
    n, m, source := int(n64), int(m64), int(source64)
    edge_from: [MAX_M]int
    edge_to: [MAX_M]int
    edge_weight: [MAX_M]i64
    for edge := 0; edge < m; edge += 1 {
        from, to, weight := input[4+3*edge], input[5+3*edge], input[6+3*edge]
        if from < 0 || from >= n64 || to < 0 || to >= n64 || weight < 0 || weight > 32 do return -1
        edge_from[edge], edge_to[edge], edge_weight[edge] = int(from), int(to), weight
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2

    distance: [MAX_N]i64
    for vertex := 0; vertex < n; vertex += 1 { distance[vertex] = INF_DISTANCE }
    distance[source] = 0
    heads: [MAX_BUCKETS]int
    tails: [MAX_BUCKETS]int
    for bucket := 0; bucket < MAX_BUCKETS; bucket += 1 { heads[bucket], tails[bucket] = -1, -1 }
    event_vertex: [MAX_EVENTS]int
    event_next: [MAX_EVENTS]int
    used := 0
    if !append_event(0, source, &heads, &tails, &event_vertex, &event_next, &used) do return -1

    for bucket := 0; bucket < MAX_BUCKETS; bucket += 1 {
        for heads[bucket] >= 0 {
            event := heads[bucket]
            heads[bucket] = event_next[event]
            if heads[bucket] < 0 do tails[bucket] = -1
            u := event_vertex[event]
            if distance[u] < delta*i64(bucket) do continue
            for edge := 0; edge < m; edge += 1 {
                if edge_from[edge] != u do continue
                v := edge_to[edge]
                candidate := distance[u] + edge_weight[edge]
                if candidate < distance[v] {
                    distance[v] = candidate
                    destination := int(candidate/delta)
                    if !append_event(destination, v, &heads, &tails, &event_vertex, &event_next, &used) do return -1
                }
            }
        }
    }
    for vertex := 0; vertex < n; vertex += 1 { store_i64_le(output, 8*vertex, distance[vertex]) }
    return i64(output_bytes)
}
