package prim

import "core:c"

// Dense Prim scan over a bounded packed undirected edge list.
@(export)
prim :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 12290 do return -2
    if values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096 do return -2
    vertices := int(values[0])
    edges := int(values[1])
    if length != c.size_t(2 + 3 * edges) || (vertices == 0 && edges != 0) do return -2
    if vertices == 0 do return 0

    present: [4096]bool
    weights: [4096]i64
    for slot := 0; slot < 4096; slot += 1 { present[slot] = false }
    for edge := 0; edge < edges; edge += 1 {
        u_value := values[2 + 3 * edge]
        v_value := values[3 + 3 * edge]
        cost := values[4 + 3 * edge]
        if u_value < 0 || v_value < 0 || u_value >= i64(vertices) || v_value >= i64(vertices) || cost < 0 || cost > 2147483647 do return -2
        u := int(u_value)
        v := int(v_value)
        if u != v {
            uv := u * 64 + v
            vu := v * 64 + u
            if !present[uv] || cost < weights[uv] {
                present[uv] = true
                present[vu] = true
                weights[uv] = cost
                weights[vu] = cost
            }
        }
    }

    in_tree: [64]bool
    has_best: [64]bool
    best: [64]i64
    for vertex := 0; vertex < 64; vertex += 1 {
        in_tree[vertex] = false
        has_best[vertex] = false
        best[vertex] = 0
    }
    has_best[0] = true
    total := i64(0)
    for step := 0; step < vertices; step += 1 {
        selected := vertices
        for vertex := 0; vertex < vertices; vertex += 1 {
            if !in_tree[vertex] && has_best[vertex] {
                if selected == vertices || best[vertex] < best[selected] do selected = vertex
            }
        }
        if selected == vertices do return -1
        in_tree[selected] = true
        total += best[selected]
        for vertex := 0; vertex < vertices; vertex += 1 {
            slot := selected * 64 + vertex
            if !in_tree[vertex] && present[slot] && (!has_best[vertex] || weights[slot] < best[vertex]) {
                has_best[vertex] = true
                best[vertex] = weights[slot]
            }
        }
    }
    return total
}
