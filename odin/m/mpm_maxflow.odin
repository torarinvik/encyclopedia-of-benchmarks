package mpm_maxflow

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 24
MAX_INPUT_VALUES :: 4 + 3*MAX_EDGES + 1
FLOW_INFINITY :: i64(2401)

minimum :: proc(a, b: i64) -> i64 { if a < b { return a }; return b }

push_forward :: proc(vertex, sink: int, amount: i64, n: int,
    residual: ^[8][8]i64, active: ^[8][8]bool,
    incoming, outgoing: ^[8]i64) -> i64 {
    if vertex == sink { return amount }
    remaining := amount
    for next := 0; next < n && remaining > 0; next += 1 {
        if !active[vertex][next] || residual[vertex][next] == 0 { continue }
        limit := minimum(remaining, residual[vertex][next])
        pushed := push_forward(next, sink, limit, n, residual, active, incoming, outgoing)
        if pushed == 0 { continue }
        residual[vertex][next] -= pushed
        residual[next][vertex] += pushed
        outgoing[vertex] -= pushed
        incoming[next] -= pushed
        remaining -= pushed
        if residual[vertex][next] == 0 { active[vertex][next] = false }
    }
    return amount - remaining
}

push_backward :: proc(vertex, source: int, amount: i64, n: int,
    residual: ^[8][8]i64, active: ^[8][8]bool,
    incoming, outgoing: ^[8]i64) -> i64 {
    if vertex == source { return amount }
    remaining := amount
    for previous := 0; previous < n && remaining > 0; previous += 1 {
        if !active[previous][vertex] || residual[previous][vertex] == 0 { continue }
        limit := minimum(remaining, residual[previous][vertex])
        pushed := push_backward(previous, source, limit, n, residual, active, incoming, outgoing)
        if pushed == 0 { continue }
        residual[previous][vertex] -= pushed
        residual[vertex][previous] += pushed
        incoming[vertex] -= pushed
        outgoing[previous] -= pushed
        remaining -= pushed
        if residual[previous][vertex] == 0 { active[previous][vertex] = false }
    }
    return amount - remaining
}

remove_vertex :: proc(vertex, n: int, residual: ^[8][8]i64,
    active: ^[8][8]bool, incoming, outgoing: ^[8]i64, alive: ^[8]bool) {
    for other := 0; other < n; other += 1 {
        if active[other][vertex] {
            capacity := residual[other][vertex]
            outgoing[other] -= capacity
            incoming[vertex] -= capacity
            active[other][vertex] = false
        }
        if active[vertex][other] {
            capacity := residual[vertex][other]
            outgoing[vertex] -= capacity
            incoming[other] -= capacity
            active[vertex][other] = false
        }
    }
    alive[vertex] = false
}

@(export)
mpm_maxflow :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(MAX_INPUT_VALUES) { return -1 }
    n_value, edge_count_value := input[0], input[1]
    source_value, sink_value := input[2], input[3]
    if n_value < 2 || n_value > MAX_VERTICES || edge_count_value < 0 ||
        edge_count_value > MAX_EDGES || source_value < 1 || source_value > n_value ||
        sink_value < 1 || sink_value > n_value || source_value == sink_value { return -1 }
    n, edge_count := int(n_value), int(edge_count_value)
    source, sink := int(source_value - 1), int(sink_value - 1)
    if length != c.size_t(4 + 3*edge_count) { return -1 }

    residual: [8][8]i64
    for edge := 0; edge < edge_count; edge += 1 {
        from_value, to_value, capacity := input[4 + 3*edge], input[5 + 3*edge], input[6 + 3*edge]
        if from_value < 1 || from_value > n_value || to_value < 1 || to_value > n_value ||
            from_value == to_value || capacity < 0 || capacity > 100 { return -1 }
        residual[int(from_value - 1)][int(to_value - 1)] += capacity
    }

    total_flow: i64
    for {
        level: [8]int
        for vertex := 0; vertex < n; vertex += 1 { level[vertex] = -1 }
        queue: [8]int
        head, tail := 0, 0
        level[source] = 0
        queue[tail] = source
        tail += 1
        for head < tail {
            vertex := queue[head]
            head += 1
            for next := 0; next < n; next += 1 {
                if residual[vertex][next] > 0 && level[next] < 0 {
                    level[next] = level[vertex] + 1
                    queue[tail] = next
                    tail += 1
                }
            }
        }
        if level[sink] < 0 { break }

        incoming, outgoing: [8]i64
        active: [8][8]bool
        alive: [8]bool
        for vertex := 0; vertex < n; vertex += 1 {
            alive[vertex] = level[vertex] >= 0 && level[vertex] <= level[sink]
        }
        for from := 0; from < n; from += 1 {
            for to := 0; to < n; to += 1 {
                if level[from] >= 0 && level[from] < level[sink] &&
                    level[to] == level[from] + 1 && residual[from][to] > 0 {
                    active[from][to] = true
                    outgoing[from] += residual[from][to]
                    incoming[to] += residual[from][to]
                }
            }
        }
        incoming[source] = FLOW_INFINITY
        outgoing[sink] = FLOW_INFINITY

        for {
            reference := -1
            least_potential := FLOW_INFINITY + 1
            for vertex := 0; vertex < n; vertex += 1 {
                if !alive[vertex] { continue }
                potential := minimum(incoming[vertex], outgoing[vertex])
                if potential < least_potential {
                    least_potential = potential
                    reference = vertex
                }
            }
            if reference < 0 { break }
            if least_potential > 0 {
                total_flow += least_potential
                _ = push_backward(reference, source, least_potential, n, &residual, &active, &incoming, &outgoing)
                _ = push_forward(reference, sink, least_potential, n, &residual, &active, &incoming, &outgoing)
            }
            remove_vertex(reference, n, &residual, &active, &incoming, &outgoing, &alive)
        }
    }
    return total_flow
}
