// Uncompiled weighted tree vertex-cover draft.
@[export: 'tree_weighted_vertex_cover']
pub fn tree_weighted_vertex_cover(input &i64, length usize) i64 {
    if length<2 || length>129 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv:=input[0]
        if nv<1 || nv>64 || length!=usize(2*nv) { return -1 }
        n:=int(nv)
        for v in 1 .. n { if input[v]<0 || input[v]>=i64(v) { return -1 } }
        mut included:=[64]i64{}
        mut excluded:=[64]i64{}
        for v in 0 .. n {
            weight:=input[n+v]
            if weight<0 || weight>1000000 { return -1 }
            included[v]=weight
        }
        mut v:=n-1
        for v>0 {
            parent:=int(input[v])
            included[parent]+=if included[v]<excluded[v] { included[v] } else { excluded[v] }
            excluded[parent]+=included[v]
            v--
        }
        return if included[0]<excluded[0] { included[0] } else { excluded[0] }
    }
}
