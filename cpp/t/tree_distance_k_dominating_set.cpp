// Uncompiled bounded distance-k tree domination draft.
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t tree_distance_k_dominating_set(const std::int64_t* input,std::size_t length) {
    if (!input || length<2 || length>66) return -1;
    const auto nv=input[0], radius=input[1];
    if (nv<1 || nv>64 || radius<0 || radius>63 || length!=static_cast<std::size_t>(nv+1)) return -1;
    const int n=static_cast<int>(nv);
    std::array<int,64> parent{},depth{},first{},next{};
    std::array<bool,64> covered{};
    first.fill(-1);
    for (int v=1; v<n; ++v) {
        const auto p=input[1+v];
        if (p<0 || p>=v) return -1;
        parent[v]=static_cast<int>(p); depth[v]=depth[parent[v]]+1;
        next[v]=first[parent[v]]; first[parent[v]]=v;
    }
    int answer=0;
    for (;;) {
        int deepest=-1;
        for (int v=0; v<n; ++v) if (!covered[v] && (deepest<0 || depth[v]>depth[deepest])) deepest=v;
        if (deepest<0) return answer;
        int center=deepest;
        for (int step=0; step<radius && center!=0; ++step) center=parent[center];
        std::array<int,64> queue{},dist{}; dist.fill(-1);
        int head=0,tail=1; queue[0]=center; dist[center]=0;
        while (head<tail) {
            const int v=queue[head++]; covered[v]=true;
            if (dist[v]==radius) continue;
            if (v!=0 && dist[parent[v]]<0) {
                const int u=parent[v]; dist[u]=dist[v]+1; queue[tail++]=u;
            }
            for (int u=first[v]; u>=0; u=next[u]) if (dist[u]<0) {
                dist[u]=dist[v]+1; queue[tail++]=u;
            }
        }
        ++answer;
    }
}
