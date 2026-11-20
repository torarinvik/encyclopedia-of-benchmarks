// Uncompiled bounded distance-k tree domination draft.
package tree_distance_k_dominating_set
import "core:c"
@(export)
tree_distance_k_dominating_set :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil || length<2 || length>66 do return -1
    nv,radius:=input[0],input[1]
    if nv<1 || nv>64 || radius<0 || radius>63 || length!=c.size_t(nv+1) do return -1
    n:=int(nv)
    parent: [64]int = {}
    depth: [64]int = {}
    first: [64]int = {}
    next: [64]int = {}
    covered: [64]bool = {}
    for v:=0; v<n; v+=1 { first[v]=-1 }
    for v:=1; v<n; v+=1 {
        raw:=input[1+v]
        if raw<0 || raw>=i64(v) do return -1
        p:=int(raw)
        parent[v]=p; depth[v]=depth[p]+1; next[v]=first[p]; first[p]=v
    }
    answer:=i64(0)
    for {
        deepest:=-1
        for v:=0; v<n; v+=1 {
            if !covered[v] && (deepest<0 || depth[v]>depth[deepest]) { deepest=v }
        }
        if deepest<0 do return answer
        center:=deepest
        for step:=i64(0); step<radius && center!=0; step+=1 { center=parent[center] }
        queue: [64]int = {}
        dist: [64]int = {}
        for v:=0; v<n; v+=1 { dist[v]=-1 }
        head,tail:=0,1; queue[0]=center; dist[center]=0
        for head<tail {
            v:=queue[head]; head+=1; covered[v]=true
            if i64(dist[v])==radius do continue
            if v!=0 && dist[parent[v]]<0 {
                u:=parent[v]; dist[u]=dist[v]+1; queue[tail]=u; tail+=1
            }
            for u:=first[v]; u>=0; u=next[u] {
                if dist[u]<0 { dist[u]=dist[v]+1; queue[tail]=u; tail+=1 }
            }
        }
        answer+=1
    }
}
