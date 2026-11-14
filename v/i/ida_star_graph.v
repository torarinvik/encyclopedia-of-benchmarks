module ida_star_graph

@[export: 'ida_star_graph']
pub fn ida_star_graph(values &i64, length usize) i64 {
    invalid := i64(-9223372036854775807) - 1
    if unsafe { values == nil } || length < 5 || length > 112 { return invalid }
    unsafe {
        nv := values[0]; mv := values[1]; sv := values[2]; gv := values[3]
        if nv < 1 || nv > 12 || mv < 0 || mv > 48 || sv < 0 || sv >= nv || gv < 0 || gv >= nv { return invalid }
        n := int(nv); m := int(mv); start := int(sv); goal := int(gv)
        if length != usize(4+n+2*m) { return invalid }
        mut h := [12]int{}
        mut edges := [12]u16{}
        for i in 0 .. n {
            if values[4+i] < 0 || values[4+i] >= nv { return invalid }
            h[i] = int(values[4+i])
        }
        if h[goal] != 0 { return invalid }
        for i in 0 .. m {
            uv := values[4+n+2*i]; vv := values[5+n+2*i]
            if uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv { return invalid }
            u := int(uv); v := int(vv); bit := u16(1) << v
            if edges[u] & bit != 0 || h[u] > h[v]+1 { return invalid }
            edges[u] |= bit
        }
        mut bound := h[start]
        for {
            mut next_bound := 1000
            mut vertices := [12]int{}
            mut next_neighbor := [12]int{}
            mut depth := 0
            mut path := u16(1) << start
            vertices[0] = start
            for depth >= 0 {
                u := vertices[depth]
                if u == goal { return i64(depth) }
                mut v := next_neighbor[depth]
                for v < n && (edges[u] & (u16(1) << v) == 0 || path & (u16(1) << v) != 0) { v++ }
                if v == n {
                    path &= ~(u16(1) << u)
                    depth--
                    continue
                }
                next_neighbor[depth] = v+1
                score := depth+1+h[v]
                if score > bound {
                    if score < next_bound { next_bound = score }
                } else {
                    depth++
                    vertices[depth] = v
                    next_neighbor[depth] = 0
                    path |= u16(1) << v
                }
            }
            if next_bound == 1000 { return -1 }
            bound = next_bound
        }
    }
    return -1
}
