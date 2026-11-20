// Uncompiled chordal-graph optimal coloring draft.
@[export: 'chordal_graph_optimal_coloring']
pub fn chordal_graph_optimal_coloring(input &i64, length usize) i64 {
    if length < 2 || length > 18 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nv := input[0]
        if nv < 1 || nv > 16 || length != usize(nv+1) { return -1 }
        n := int(nv)
        mut rows := [16]int{}
        mut weight := [16]int{}
        mut colors := [16]int{}
        mut order := [16]int{}
        for v in 0 .. n {
            if input[v+1] < 0 || input[v+1] >= i64(1 << n) || (input[v+1] & i64(1 << v)) != 0 { return -1 }
            rows[v] = int(input[v+1]); colors[v] = -1
        }
        for v in 0 .. n { for u in 0 .. v { if ((rows[v] >> u) & 1) != ((rows[u] >> v) & 1) { return -1 } } }
        mut selected := 0
        for i in 0 .. n {
            mut vertex := -1
            for u in 0 .. n {
                if (selected & (1 << u)) == 0 {
                    if vertex < 0 { vertex = u } else if weight[u] > weight[vertex] { vertex = u }
                }
            }
            earlier := rows[vertex] & selected
            for j in 0 .. i {
                u := order[j]
                if (earlier & (1 << u)) != 0 && (earlier & ~(rows[u] | (1 << u))) != 0 { return -2 }
            }
            order[i] = vertex; selected |= 1 << vertex
            for u in 0 .. n { if (selected & (1 << u)) == 0 && (rows[vertex] & (1 << u)) != 0 { weight[u]++ } }
        }
        mut maximum := 0
        for i in 0 .. n {
            v := order[i]
            mut used := 0
            for u in 0 .. n { if (rows[v] & (1 << u)) != 0 && colors[u] >= 0 { used |= 1 << colors[u] } }
            mut color := 0
            for (used & (1 << color)) != 0 { color++ }
            colors[v] = color
            if color+1 > maximum { maximum = color+1 }
        }
        return i64(maximum)
    }
}
