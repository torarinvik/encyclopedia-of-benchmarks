// Independent bounded subset-assignment draft; not compiled or run.
package tree_sibling_distinct_cost_coloring
import "core:c"
@(export)
tree_sibling_distinct_cost_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<3 || length>354 do return -1
    if input[0]<1 || input[0]>32 || input[1]<1 || input[1]>10 do return -1
    n,k:=int(input[0]),int(input[1])
    if length!=c.size_t(n+1+n*k) do return -1
    for v:=1; v<n; v+=1 { if input[1+v]<0 || input[1+v]>=i64(v) do return -1 }
    for i:=0; i<n*k; i+=1 { if input[n+1+i]<0 || input[n+1+i]>1000000 do return -1 }
    inf:=i64(1000000000000)
    states:=1 << uint(k)
    dp: [320]i64 = {}
    current,next: [1024]i64
    v:=n
    for v>0 {
        v-=1
        for color:=0; color<k; color+=1 {
            for mask:=0; mask<states; mask+=1 { current[mask]=inf }
            current[1 << uint(color)]=0
            for child:=v+1; child<n; child+=1 {
                if input[1+child]!=i64(v) do continue
                for mask:=0; mask<states; mask+=1 { next[mask]=inf }
                for mask:=0; mask<states; mask+=1 {
                    if current[mask]==inf do continue
                    for col:=0; col<k; col+=1 {
                        bit:=1 << uint(col)
                        if (mask & bit)!=0 || dp[10*child+col]==inf do continue
                        target:=mask | bit
                        candidate:=current[mask]+dp[10*child+col]
                        if candidate<next[target] { next[target]=candidate }
                    }
                }
                for mask:=0; mask<states; mask+=1 { current[mask]=next[mask] }
            }
            best:=inf
            for mask:=0; mask<states; mask+=1 { if current[mask]<best { best=current[mask] } }
            dp[10*v+color]=inf
            if best!=inf { dp[10*v+color]=best+input[n+1+v*k+color] }
        }
    }
    best:=inf
    for color:=0; color<k; color+=1 { if dp[color]<best { best=dp[color] } }
    if best==inf do return -2
    return best
}
