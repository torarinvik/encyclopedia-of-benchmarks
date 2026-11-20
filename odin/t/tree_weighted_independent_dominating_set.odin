// Uncompiled weighted independent tree domination draft.
package tree_weighted_independent_dominating_set
import "core:c"
inf :: i64(1000000000000)
twid_add :: proc(a,b:i64)->i64 { return min(inf,a+b) }
@(export)
tree_weighted_independent_dominating_set :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil || length<2 || length>129 do return -1
    nv:=input[0]
    if nv<1 || nv>64 || length!=c.size_t(2*nv) do return -1
    n:=int(nv)
    for v:=1; v<n; v+=1 { if input[v]<0 || input[v]>=i64(v) do return -1 }
    selected: [64]i64 = {}
    covered: [64]i64 = {}
    waiting: [64]i64 = {}
    for v:=0; v<n; v+=1 {
        weight:=input[n+v]
        if weight<0 || weight>1000000 do return -1
        selected[v]=weight; covered[v]=inf
    }
    for v:=n-1; v>0; v-=1 {
        p:=int(input[v])
        a,b,c:=selected[v],covered[v],waiting[v]
        next:=min(twid_add(covered[p],min(a,b)),twid_add(waiting[p],a))
        selected[p]=twid_add(selected[p],min(b,c))
        waiting[p]=twid_add(waiting[p],b); covered[p]=next
    }
    return min(selected[0],covered[0])
}
