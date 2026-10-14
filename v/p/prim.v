module prim

// Dense Prim scan over a bounded packed undirected edge list.
@[export: 'prim']
pub fn prim(values &i64, length usize) i64 {
    if length < 2 || length > 12290 { return -2 }
    if unsafe { values[0] } < 0 || unsafe { values[0] } > 64 || unsafe { values[1] } < 0 || unsafe { values[1] } > 4096 { return -2 }
    vertices := int(unsafe { values[0] })
    edges := int(unsafe { values[1] })
    if length != usize(2 + 3 * edges) || (vertices == 0 && edges != 0) { return -2 }
    if vertices == 0 { return 0 }

    mut present := [4096]bool{}
    mut weights := [4096]i64{}
    for edge in 0 .. edges {
        u_value := unsafe { values[2 + 3 * edge] }
        v_value := unsafe { values[3 + 3 * edge] }
        cost := unsafe { values[4 + 3 * edge] }
        if u_value < 0 || v_value < 0 || u_value >= i64(vertices) || v_value >= i64(vertices) || cost < 0 || cost > 2147483647 { return -2 }
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

    mut in_tree := [64]bool{}
    mut has_best := [64]bool{}
    mut best := [64]i64{}
    has_best[0] = true
    mut total := i64(0)
    for _ in 0 .. vertices {
        mut selected := vertices
        for vertex in 0 .. vertices {
            if !in_tree[vertex] && has_best[vertex] {
                if selected == vertices || best[vertex] < best[selected] { selected = vertex }
            }
        }
        if selected == vertices { return -1 }
        in_tree[selected] = true
        total += best[selected]
        for vertex in 0 .. vertices {
            slot := selected * 64 + vertex
            if !in_tree[vertex] && present[slot] && (!has_best[vertex] || weights[slot] < best[vertex]) {
                has_best[vertex] = true
                best[vertex] = weights[slot]
            }
        }
    }
    return total
}
