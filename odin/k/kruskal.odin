package kruskal

import "core:c"

sift_down :: proc "contextless"(keys: [^]i64, start_root, end: int) {
    root := start_root
    for root < end / 2 {
        child := root * 2 + 1
        if child + 1 < end && keys[child] < keys[child + 1] do child += 1
        if keys[root] >= keys[child] do break
        temporary := keys[root]; keys[root] = keys[child]; keys[child] = temporary
        root = child
    }
}
find_root :: proc "contextless"(parent: [^]c.size_t, start_node: c.size_t) -> c.size_t {
    node := start_node
    for parent[node] != node {
        parent[node] = parent[parent[node]]
        node = parent[node]
    }
    return node
}

// Heapsort packed undirected edges, then union their components by rank.
@(export)
kruskal :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 12290 do return -2
    if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 do return -2
    vertices := int(values[0]); edges := int(values[1])
    if length != c.size_t(2 + 3 * edges) || (vertices == 0 && edges != 0) do return -2
    if vertices == 0 do return 0
    keys: [4096]i64
    for edge := 0; edge < edges; edge += 1 {
        u := values[2 + 3 * edge]; v := values[3 + 3 * edge]; weight := values[4 + 3 * edge]
        if u < 0 || v < 0 || u >= i64(vertices) || v >= i64(vertices) || weight < 0 || weight > 2147483647 do return -2
        if u > v { temporary := u; u = v; v = temporary }
        keys[edge] = weight * 4096 + u * 64 + v
    }
    start := edges / 2
    for start > 0 { start -= 1; sift_down(&keys[0], start, edges) }
    end := edges
    for end > 1 {
        end -= 1
        temporary := keys[0]; keys[0] = keys[end]; keys[end] = temporary
        sift_down(&keys[0], 0, end)
    }
    parent: [64]c.size_t
    ranks: [64]c.size_t
    for vertex := 0; vertex < vertices; vertex += 1 { parent[vertex] = c.size_t(vertex); ranks[vertex] = 0 }
    selected := 0
    total := i64(0)
    for edge := 0; edge < edges && selected + 1 < vertices; edge += 1 {
        key := keys[edge]
        u := c.size_t((key % 4096) / 64); v := c.size_t(key % 64)
        root_u := find_root(&parent[0], u); root_v := find_root(&parent[0], v)
        if root_u != root_v {
            total += key / 4096; selected += 1
            if ranks[root_u] < ranks[root_v] do parent[root_u] = root_v
            else if ranks[root_u] > ranks[root_v] do parent[root_v] = root_u
            else { parent[root_v] = root_u; ranks[root_u] += 1 }
        }
    }
    if selected + 1 == vertices do return total
    return -1
}
