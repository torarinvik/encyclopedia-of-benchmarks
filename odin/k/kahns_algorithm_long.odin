package kahns_algorithm_long

import "core:c"

@(export)
kahns_algorithm_long :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 258 do return -1
    vertex_count := values[0]
    edge_count := values[1]
    if vertex_count < 1 || vertex_count > 32 || edge_count < 0 || edge_count > 128 do return -1
    if length != c.size_t(2 + 2 * edge_count) do return -1

    multiplicity: [1024]i64 = {}
    indegree: [32]i64 = {}
    distance: [32]i64 = {}
    queue: [32]i64 = {}
    for vertex := 0; vertex < int(vertex_count); vertex += 1 do distance[vertex] = 1
    for edge := 0; edge < int(edge_count); edge += 1 {
        source := values[2 + 2 * edge]
        destination := values[3 + 2 * edge]
        if source < 0 || source >= vertex_count || destination < 0 || destination >= vertex_count do return -1
        multiplicity[int(source * 32 + destination)] += 1
        indegree[destination] += 1
    }

    head := 0
    tail := 0
    for vertex := 0; vertex < int(vertex_count); vertex += 1 {
        if indegree[vertex] == 0 { queue[tail] = i64(vertex); tail += 1 }
    }
    processed: i64 = 0
    maximum: i64 = 1
    for head < tail {
        source := int(queue[head])
        head += 1
        processed += 1
        if distance[source] > maximum do maximum = distance[source]
        for destination := 0; destination < int(vertex_count); destination += 1 {
            copies := multiplicity[source * 32 + destination]
            if copies == 0 do continue
            candidate := distance[source] + 1
            if candidate > distance[destination] do distance[destination] = candidate
            for copy := 0; copy < int(copies); copy += 1 {
                indegree[destination] -= 1
                if indegree[destination] == 0 { queue[tail] = i64(destination); tail += 1 }
            }
        }
    }
    if processed != vertex_count do return -1
    for vertex := 0; vertex < int(vertex_count); vertex += 1 {
        if distance[vertex] > maximum do maximum = distance[vertex]
    }
    return maximum
}
