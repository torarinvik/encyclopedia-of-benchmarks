// Uncompiled weighted tree vertex-cover draft.
package tree_weighted_vertex_cover
import "core:c"
@(export)
tree_weighted_vertex_cover :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<2 || length>129 do return -1
    nv:=input[0]
    if nv<1 || nv>64 || length!=c.size_t(2*nv) do return -1
    n:=int(nv)
    for v:=1; v<n; v+=1 { if input[v]<0 || input[v]>=i64(v) do return -1 }
    included: [64]i64 = {}
    excluded: [64]i64 = {}
    for v:=0; v<n; v+=1 {
        weight:=input[n+v]
        if weight<0 || weight>1000000 do return -1
        included[v]=weight
    }
    for v:=n-1; v>0; v-=1 {
        parent:=int(input[v])
        included[parent]+=min(included[v],excluded[v])
        excluded[parent]+=included[v]
    }
    return min(included[0],excluded[0])
}
