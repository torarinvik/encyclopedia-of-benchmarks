/* Uncompiled bounded distance-k tree domination draft. */
#include <stddef.h>
#include <stdint.h>
int64_t tree_distance_k_dominating_set(const int64_t *input,size_t length) {
    if (!input || length<2 || length>66) return -1;
    int64_t nv=input[0], radius=input[1];
    if (nv<1 || nv>64 || radius<0 || radius>63 || length!=(size_t)(nv+1)) return -1;
    int n=(int)nv, parent[64]={0}, depth[64]={0}, first_child[64], next_sibling[64];
    unsigned char covered[64]={0};
    for (int v=0; v<n; ++v) first_child[v]=-1;
    for (int v=1; v<n; ++v) {
        int64_t p=input[1+v];
        if (p<0 || p>=v) return -1;
        parent[v]=(int)p; depth[v]=depth[p]+1;
        next_sibling[v]=first_child[p]; first_child[p]=v;
    }
    int answer=0;
    for (;;) {
        int deepest=-1;
        for (int v=0; v<n; ++v)
            if (!covered[v] && (deepest<0 || depth[v]>depth[deepest])) deepest=v;
        if (deepest<0) return answer;
        int center=deepest;
        for (int step=0; step<radius && center!=0; ++step) center=parent[center];
        int queue[64], dist[64];
        for (int v=0; v<n; ++v) dist[v]=-1;
        int head=0, tail=0;
        queue[tail++]=center; dist[center]=0;
        while (head<tail) {
            int v=queue[head++]; covered[v]=1;
            if (dist[v]==radius) continue;
            if (v!=0 && dist[parent[v]]<0) {
                int u=parent[v]; dist[u]=dist[v]+1; queue[tail++]=u;
            }
            for (int u=first_child[v]; u>=0; u=next_sibling[u]) if (dist[u]<0) {
                dist[u]=dist[v]+1; queue[tail++]=u;
            }
        }
        ++answer;
    }
}
