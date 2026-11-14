// Uncompiled bounded minimum-cost proper tree coloring draft.
package tree_min_cost_proper_coloring
import "core:c"
@(export)
tree_min_cost_proper_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<2 || length>1090 do return -1
    nv,kv:=input[0],input[1]
    if nv<1 || nv>64 || kv<1 || kv>16 do return -1
    n,k:=int(nv),int(kv)
    if length!=c.size_t(n+1+n*k) do return -1
    for v:=1; v<n; v+=1 { if input[1+v]<0 || input[1+v]>=i64(v) do return -1 }
    dp: [1024]i64 = {}
    for v:=0; v<n; v+=1 { for color:=0; color<k; color+=1 {
        value:=input[n+1+v*k+color]
        if value<0 || value>1000000 do return -1
        dp[16*v+color]=value
    } }
    if n>1 && k==1 do return -2
    for child:=n-1; child>0; child-=1 {
        parent:=int(input[1+child])
        least,second:=i64(64000001),i64(64000001)
        best_color:=0
        for color:=0; color<k; color+=1 {
            value:=dp[16*child+color]
            if value<least { second=least; least=value; best_color=color } else if value<second { second=value }
        }
        for color:=0; color<k; color+=1 {
            addition:=least
            if color==best_color { addition=second }
            dp[16*parent+color]+=addition
        }
    }
    best:=dp[0]
    for color:=1; color<k; color+=1 { if dp[color]<best { best=dp[color] } }
    return best
}
