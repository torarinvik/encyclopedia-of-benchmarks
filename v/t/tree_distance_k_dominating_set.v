// Uncompiled bounded distance-k tree domination draft.
@[export: 'tree_distance_k_dominating_set']
pub fn tree_distance_k_dominating_set(input &i64,length usize) i64 {
    if length<2 || length>66 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv,radius:=input[0],input[1]
        if nv<1 || nv>64 || radius<0 || radius>63 || length!=usize(nv+1) { return -1 }
        n:=int(nv)
        mut parent:=[64]int{}
        mut depth:=[64]int{}
        mut first:=[64]int{}
        mut next:=[64]int{}
        mut covered:=[64]bool{}
        for v in 0 .. n { first[v]=-1 }
        for v in 1 .. n {
            raw:=input[1+v]
            if raw<0 || raw>=i64(v) { return -1 }
            p:=int(raw)
            parent[v]=p; depth[v]=depth[p]+1; next[v]=first[p]; first[p]=v
        }
        mut answer:=i64(0)
        for {
            mut deepest:=-1
            for v in 0 .. n { if !covered[v] && (deepest<0 || depth[v]>depth[deepest]) { deepest=v } }
            if deepest<0 { return answer }
            mut center:=deepest
            mut step:=i64(0)
            for step<radius && center!=0 { center=parent[center]; step++ }
            mut queue:=[64]int{}
            mut dist:=[64]int{}
            for v in 0 .. n { dist[v]=-1 }
            mut head:=0
            mut tail:=1
            queue[0]=center; dist[center]=0
            for head<tail {
                v:=queue[head]; head++; covered[v]=true
                if i64(dist[v])==radius { continue }
                if v!=0 && dist[parent[v]]<0 {
                    u:=parent[v]; dist[u]=dist[v]+1; queue[tail]=u; tail++
                }
                mut u:=first[v]
                for u>=0 {
                    if dist[u]<0 { dist[u]=dist[v]+1; queue[tail]=u; tail++ }
                    u=next[u]
                }
            }
            answer++
        }
    }
}
