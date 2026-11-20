// Uncompiled bounded distance-k tree domination draft.
export fn tree_distance_k_dominating_set(input:[*c]const i64,length:usize) i64 {
    if (input==null or length<2 or length>66) return -1;
    const nv=input[0]; const radius=input[1];
    if (nv<1 or nv>64 or radius<0 or radius>63 or length!=@as(usize,@intCast(nv+1))) return -1;
    const n:usize=@intCast(nv);
    var parent=[_]usize{0} ** 64;
    var depth=[_]usize{0} ** 64;
    var first=[_]i32{-1} ** 64;
    var next=[_]i32{-1} ** 64;
    var covered=[_]bool{false} ** 64;
    for (1..n) |v| {
        const raw=input[1+v];
        if (raw<0 or raw>=@as(i64,@intCast(v))) return -1;
        const p:usize=@intCast(raw);
        parent[v]=p; depth[v]=depth[p]+1;
        next[v]=first[p]; first[p]=@intCast(v);
    }
    var answer:i64=0;
    while (true) {
        var deepest:usize=n;
        for (0..n) |v| if (!covered[v] and (deepest==n or depth[v]>depth[deepest])) { deepest=v; };
        if (deepest==n) return answer;
        var center=deepest;
        var step:i64=0;
        while (step<radius and center!=0) : (step+=1) center=parent[center];
        var queue=[_]usize{0} ** 64;
        var dist=[_]i32{-1} ** 64;
        var head:usize=0; var tail:usize=1;
        queue[0]=center; dist[center]=0;
        while (head<tail) {
            const v=queue[head]; head+=1; covered[v]=true;
            if (dist[v]==radius) continue;
            if (v!=0 and dist[parent[v]]<0) {
                const u=parent[v]; dist[u]=dist[v]+1; queue[tail]=u; tail+=1;
            }
            var child=first[v];
            while (child>=0) {
                const u:usize=@intCast(child);
                if (dist[u]<0) { dist[u]=dist[v]+1; queue[tail]=u; tail+=1; }
                child=next[u];
            }
        }
        answer+=1;
    }
}
