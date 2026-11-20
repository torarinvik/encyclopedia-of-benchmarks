// Uncompiled bounded distance-k tree domination draft.
module tree_distance_k_dominating_set;
fn long tree_distance_k_dominating_set(long* input,usz length) @export("tree_distance_k_dominating_set") {
    if (input==null || length<2 || length>66) return -1;
    long nv=input[0], radius=input[1];
    if (nv<1 || nv>64 || radius<0 || radius>63 || length!=(usz)(nv+1)) return -1;
    int n=(int)nv;
    int[64] parent=zeroed, depth=zeroed, first, next;
    bool[64] covered=zeroed;
    for (int v=0; v<n; v++) first[v]=-1;
    for (int v=1; v<n; v++) {
        long raw=input[1+v];
        if (raw<0 || raw>=v) return -1;
        int p=(int)raw;
        parent[v]=p; depth[v]=depth[p]+1; next[v]=first[p]; first[p]=v;
    }
    long answer=0;
    while (true) {
        int deepest=-1;
        for (int v=0; v<n; v++) if (!covered[v] && (deepest<0 || depth[v]>depth[deepest])) deepest=v;
        if (deepest<0) return answer;
        int center=deepest;
        for (int step=0; step<radius && center!=0; step++) center=parent[center];
        int[64] queue, dist;
        for (int v=0; v<n; v++) dist[v]=-1;
        int head=0,tail=1; queue[0]=center; dist[center]=0;
        while (head<tail) {
            int v=queue[head++]; covered[v]=true;
            if (dist[v]==radius) continue;
            if (v!=0 && dist[parent[v]]<0) {
                int u=parent[v]; dist[u]=dist[v]+1; queue[tail++]=u;
            }
            for (int u=first[v]; u>=0; u=next[u]) if (dist[u]<0) {
                dist[u]=dist[v]+1; queue[tail++]=u;
            }
        }
        answer++;
    }
}
