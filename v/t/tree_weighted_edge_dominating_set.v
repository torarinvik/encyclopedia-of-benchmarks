// Uncompiled minimum-weight tree edge-domination draft.
fn tweds_min(a i64, b i64) i64 { return if a < b { a } else { b } }

@[export: 'tree_weighted_edge_dominating_set']
pub fn tree_weighted_edge_dominating_set(input &i64, length usize) i64 {
    if length < 1 || length > 128 { return -1 }
    unsafe {
        if input == nil { return -1 }
        nv := input[0]
        if nv < 1 || nv > 64 || length != usize(2*nv-1) { return -1 }
        n := int(nv)
        for v in 1 .. n {
            if input[v] < 0 || input[v] >= i64(v) || input[n+v-1] < 0 || input[n+v-1] > 1000000 { return -1 }
        }
        inf := i64(1000000000000)
        mut selected := [64]i64{}
        mut closed := [64]i64{}
        mut pending := [64]i64{}
        for v in 0 .. n { selected[v] = inf }
        mut v := n-1
        for v > 0 {
            p := int(input[v])
            skip := tweds_min(selected[v], closed[v])
            take := input[n+v-1] + tweds_min(selected[v], pending[v])
            selected[p] = tweds_min(inf, tweds_min(selected[p] + tweds_min(skip, take), pending[p] + take))
            closed[p] = tweds_min(inf, closed[p] + selected[v])
            pending[p] = tweds_min(inf, pending[p] + skip)
            v--
        }
        return tweds_min(selected[0], closed[0])
    }
}
