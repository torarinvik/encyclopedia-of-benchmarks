// Uncompiled weighted total-domination tree draft.
package tree_weighted_total_dominating_set
import "core:c"
inf :: i64(1000000000000)
twt_add :: proc(a,b:i64)->i64 { return min(inf,a+b) }
@(export)
tree_weighted_total_dominating_set :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil || length<2 || length>129 do return -1
    nv:=input[0]
    if nv<1 || nv>64 || length!=c.size_t(2*nv) do return -1
    n:=int(nv)
    for v:=1; v<n; v+=1 { if input[v]<0 || input[v]>=i64(v) do return -1 }
    weights: [64]i64 = {}
    none: [128]i64 = {}
    some: [128]i64 = {}
    for v:=0; v<n; v+=1 {
        weights[v]=input[n+v]
        if weights[v]<0 || weights[v]>1000000 do return -1
        some[2*v]=inf; some[2*v+1]=inf
    }
    root:=inf
    for v:=n-1; v>=0; v-=1 {
        dp: [4]i64 = {}
        for chosen:=0; chosen<2; chosen+=1 {
            own:=i64(0)
            if chosen==1 { own=weights[v] }
            dp[2*chosen]=twt_add(own,some[2*v+chosen])
            dp[2*chosen+1]=twt_add(own,min(none[2*v+chosen],some[2*v+chosen]))
        }
        if v==0 { root=min(dp[0],dp[2]); break }
        p:=int(input[v])
        for chosen:=0; chosen<2; chosen+=1 {
            a,b:=dp[chosen],dp[2+chosen]
            index:=2*p+chosen
            next:=min(twt_add(some[index],min(a,b)),twt_add(none[index],b))
            none[index]=twt_add(none[index],a); some[index]=next
        }
    }
    if root==inf do return -2
    return root
}
