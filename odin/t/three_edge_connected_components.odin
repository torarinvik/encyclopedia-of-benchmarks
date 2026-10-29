package three_edge_connected_components

import "core:c"

Max_Vertices :: 8
Max_Edges :: 32
Max_Input_Length :: 2 + 2 * Max_Edges

Edge :: struct { u, v: int }

refine_for_removal :: proc "contextless" (edges: []Edge, vertex_count, edge_count, removed_first, removed_second: int, same: []bool) {
    var component: [Max_Vertices]int
    for vertex := 0; vertex < vertex_count; vertex += 1 { component[vertex] = -1 }
    var queue: [Max_Vertices]int
    next_component := 0
    for start := 0; start < vertex_count; start += 1 {
        if component[start] >= 0 do continue
        head, tail := 0, 0
        component[start] = next_component
        queue[tail] = start
        tail += 1
        for head < tail {
            vertex := queue[head]
            head += 1
            for edge_id := 0; edge_id < edge_count; edge_id += 1 {
                if edge_id == removed_first || edge_id == removed_second do continue
                edge := edges[edge_id]
                neighbor := -1
                if edge.u == vertex do neighbor = edge.v
                else if edge.v == vertex do neighbor = edge.u
                if neighbor >= 0 && component[neighbor] < 0 {
                    component[neighbor] = next_component
                    queue[tail] = neighbor
                    tail += 1
                }
            }
        }
        next_component += 1
    }
    for first := 0; first < vertex_count; first += 1 {
        for second := first + 1; second < vertex_count; second += 1 {
            if component[first] != component[second] {
                same[first * Max_Vertices + second] = false
                same[second * Max_Vertices + first] = false
            }
        }
    }
}

@(export)
three_edge_connected_components :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(Max_Input_Length) do return -1
    if values[0] < 1 || values[0] > i64(Max_Vertices) || values[1] < 0 || values[1] > i64(Max_Edges) do return -1
    vertex_count, edge_count := int(values[0]), int(values[1])
    if length != c.size_t(2 + 2 * edge_count) do return -1
    var edges: [Max_Edges]Edge
    for edge_id := 0; edge_id < edge_count; edge_id += 1 {
        from_value, to_value := values[2 + 2 * edge_id], values[3 + 2 * edge_id]
        if from_value < 0 || from_value >= i64(vertex_count) || to_value < 0 || to_value >= i64(vertex_count) do return -1
        edges[edge_id] = Edge{int(from_value), int(to_value)}
    }

    var same: [Max_Vertices * Max_Vertices]bool
    for pair := 0; pair < Max_Vertices * Max_Vertices; pair += 1 { same[pair] = true }
    edge_view := edges[:edge_count]
    same_view := same[0:Max_Vertices * Max_Vertices]
    refine_for_removal(edge_view, vertex_count, edge_count, -1, -1, same_view)
    for first := 0; first < edge_count; first += 1 {
        refine_for_removal(edge_view, vertex_count, edge_count, first, -1, same_view)
        for second := first + 1; second < edge_count; second += 1 {
            refine_for_removal(edge_view, vertex_count, edge_count, first, second, same_view)
        }
    }

    var labels: [Max_Vertices]int
    for vertex := 0; vertex < vertex_count; vertex += 1 { labels[vertex] = -1 }
    next_label := 0
    for first := 0; first < vertex_count; first += 1 {
        if labels[first] >= 0 do continue
        for vertex := first; vertex < vertex_count; vertex += 1 {
            if labels[vertex] < 0 && same[first * Max_Vertices + vertex] do labels[vertex] = next_label
        }
        next_label += 1
    }
    encoded, place := i64(0), i64(1)
    for vertex := 0; vertex < vertex_count; vertex += 1 {
        encoded += i64(labels[vertex]) * place
        place *= 8
    }
    return encoded
}
