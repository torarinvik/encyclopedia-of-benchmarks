// Based on AtCoder Library mcf_graph::flow (CC0 1.0); see benchmarks/m/min_cost_max_flow/LICENSE.txt.
package min_cost_max_flow
import "core:c"

MAX_N :: 8
MAX_M :: 16
MAX_INPUT :: 69
INF :: i64(1) << 60

Edge :: struct { from: int, to: int, rev: int, cap: i64, cost: i64 }

@(export)
min_cost_max_flow :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 5 || input_length > c.size_t(MAX_INPUT) do return -1
    n_value, m_value, source_value, sink_value, flow_limit := input[0], input[1], input[2], input[3], input[4]
    if n_value < 2 || n_value > MAX_N || m_value < 0 || m_value > MAX_M || input_length != c.size_t(5 + 4*m_value) do return -1
    if source_value < 0 || source_value >= n_value || sink_value < 0 || sink_value >= n_value || source_value == sink_value || flow_limit < 0 || flow_limit > 16 do return -1
    n, m, source, sink := int(n_value), int(m_value), int(source_value), int(sink_value)
    edges: [2*MAX_M]Edge
    for i := 0; i < m; i += 1 {
        u, v, cap, cost := input[5+4*i], input[6+4*i], input[7+4*i], input[8+4*i]
        if u < 0 || u >= n_value || v < 0 || v >= n_value || cap < 0 || cap > 5 || cost < 0 || cost > 20 do return -1
        e := 2*i
        edges[e] = Edge{int(u), int(v), e+1, cap, cost}
        edges[e+1] = Edge{int(v), int(u), e, 0, -cost}
    }
    if output == nil || output_capacity < 16 do return -2
    potential: [MAX_N]i64
    for i := 0; i < n; i += 1 { potential[i] = 0 }
    total_flow, total_cost: i64 = 0, 0
    for total_flow < flow_limit {
        dist: [MAX_N]i64
        parent: [MAX_N]int
        used: [MAX_N]bool
        for i := 0; i < n; i += 1 { dist[i] = INF; parent[i] = -1; used[i] = false }
        dist[source] = 0
        for _ := 0; _ < n; _ += 1 {
            chosen := -1
            for v := 0; v < n; v += 1 {
                if !used[v] && dist[v] != INF && (chosen < 0 || dist[v] < dist[chosen]) { chosen = v }
            }
            if chosen < 0 do break
            used[chosen] = true
            for e := 0; e < 2*m; e += 1 {
                if edges[e].from != chosen || edges[e].cap <= 0 do continue
                v := edges[e].to
                candidate := dist[chosen] + edges[e].cost + potential[chosen] - potential[v]
                if !used[v] && candidate < dist[v] { dist[v] = candidate; parent[v] = e }
            }
        }
        if dist[sink] == INF do break
        for v := 0; v < n; v += 1 { if dist[v] != INF { potential[v] += dist[v] } }
        amount := flow_limit - total_flow
        vertex := sink
        for vertex != source {
            e := parent[vertex]
            if e < 0 do return -1
            if amount > edges[e].cap { amount = edges[e].cap }
            vertex = edges[e].from
        }
        vertex = sink
        for vertex != source {
            e := parent[vertex]
            edges[e].cap -= amount
            edges[edges[e].rev].cap += amount
            vertex = edges[e].from
        }
        total_flow += amount
        total_cost += amount * (potential[sink] - potential[source])
    }
    flow_bits, cost_bits := u64(total_flow), u64(total_cost)
    for i := 0; i < 8; i += 1 { output[i] = u8(flow_bits >> (8*i)); output[8+i] = u8(cost_bits >> (8*i)) }
    return 16
}
