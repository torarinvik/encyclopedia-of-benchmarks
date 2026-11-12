package min_cost_max_flow_blocking_paths
import "core:c"

MAX_N :: 8
MAX_M :: 16
MAX_INPUT :: 69
INF :: i64(1) << 60

Edge :: struct { from: int, to: int, rev: int, cap: i64, cost: i64 }

send_tight_level_flow :: proc "contextless" (u, sink: int, limit: i64,
        edges: ^[32]Edge, arc_count: int, dist: ^[8]i64,
        level: ^[8]int, current: ^[8]int) -> i64 {
    if u == sink do return limit
    for current[u] < arc_count {
        e := current[u]
        if edges[e].from != u || edges[e].cap <= 0 { current[u] += 1; continue }
        v := edges[e].to
        if dist[v] == INF || dist[v] != dist[u] + edges[e].cost || level[v] != level[u] + 1 {
            current[u] += 1; continue
        }
        amount := min(limit, edges[e].cap)
        sent := send_tight_level_flow(v, sink, amount, edges, arc_count, dist, level, current)
        if sent > 0 {
            reverse := edges[e].rev
            edges[e].cap -= sent
            edges[reverse].cap += sent
            if edges[e].cap == 0 { current[u] += 1 }
            return sent
        }
        current[u] += 1
    }
    return 0
}

@(export)
min_cost_max_flow_blocking_paths :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 5 || input_length > c.size_t(MAX_INPUT) do return -1
    n_value, m_value, source_value, sink_value, flow_limit := input[0], input[1], input[2], input[3], input[4]
    if n_value < 2 || n_value > MAX_N || m_value < 0 || m_value > MAX_M || input_length != c.size_t(5 + 4*m_value) do return -1
    if source_value < 0 || source_value >= n_value || sink_value < 0 || sink_value >= n_value || source_value == sink_value || flow_limit < 0 || flow_limit > 16 do return -1
    n, m, source, sink := int(n_value), int(m_value), int(source_value), int(sink_value)
    edges: [32]Edge
    for i := 0; i < m; i += 1 {
        u, v, cap, cost := input[5+4*i], input[6+4*i], input[7+4*i], input[8+4*i]
        if u < 0 || u >= n_value || v < 0 || v >= n_value || cap < 0 || cap > 5 || cost < 0 || cost > 20 do return -1
        e := 2*i
        edges[e] = Edge{int(u), int(v), e+1, cap, cost}
        edges[e+1] = Edge{int(v), int(u), e, 0, -cost}
    }
    if output == nil || output_capacity < 16 do return -2
    total_flow, total_cost: i64 = 0, 0
    for total_flow < flow_limit {
        dist: [8]i64
        queue: [8]int
        in_queue: [8]bool
        for i := 0; i < n; i += 1 { dist[i] = INF; in_queue[i] = false }
        dist[source] = 0
        head, tail, queued := 0, 0, 0
        queue[tail] = source; tail = (tail+1)%n; queued += 1; in_queue[source] = true
        for queued > 0 {
            u := queue[head]; head = (head+1)%n; queued -= 1; in_queue[u] = false
            for e := 0; e < 2*m; e += 1 {
                if edges[e].from != u || edges[e].cap <= 0 do continue
                v := edges[e].to
                candidate := dist[u] + edges[e].cost
                if candidate < dist[v] {
                    dist[v] = candidate
                    if !in_queue[v] { queue[tail] = v; tail = (tail+1)%n; queued += 1; in_queue[v] = true }
                }
            }
        }
        if dist[sink] == INF do break
        for total_flow < flow_limit {
            level: [8]int; breadth: [8]int; current: [8]int
            for i := 0; i < n; i += 1 { level[i] = -1; current[i] = 0 }
            first, last := 0, 0
            level[source] = 0; breadth[last] = source; last += 1
            for first < last {
                u := breadth[first]; first += 1
                for e := 0; e < 2*m; e += 1 {
                    if edges[e].from != u || edges[e].cap <= 0 do continue
                    v := edges[e].to
                    if dist[v] == dist[u]+edges[e].cost && level[v] < 0 { level[v] = level[u]+1; breadth[last] = v; last += 1 }
                }
            }
            if level[sink] < 0 do break
            amount := send_tight_level_flow(source,sink,flow_limit-total_flow,&edges,2*m,&dist,&level,&current)
            if amount == 0 do break
            total_flow += amount
            total_cost += amount*dist[sink]
        }
    }
    flow_bits, cost_bits := u64(total_flow), u64(total_cost)
    for i := 0; i < 8; i += 1 { output[i] = u8(flow_bits >> (8*i)); output[8+i] = u8(cost_bits >> (8*i)) }
    return 16
}
