#include <stddef.h>
#include <stdint.h>

#define MAX_N 12
#define MAX_M 24
#define MAX_INPUT 98

int64_t kkt_mst_sampling_filter(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (!input || length < 6 || length > MAX_INPUT) return -1;
    int64_t n64=input[0], m64=input[1];
    if (n64 < 2 || n64 > MAX_N || m64 < 1 || m64 > MAX_M ||
        length != 2 + 4*(size_t)m64) return -1;
    size_t n=(size_t)n64, m=(size_t)m64;
    int64_t u[MAX_M], v[MAX_M], weight[MAX_M], sampled[MAX_M];
    for (size_t i=0;i<m;++i) {
        u[i]=input[2+4*i]; v[i]=input[3+4*i];
        weight[i]=input[4+4*i]; sampled[i]=input[5+4*i];
        if (u[i]<0 || u[i]>=v[i] || v[i]>=n64 || weight[i]<1 ||
            weight[i]>1024 || (sampled[i]!=0 && sampled[i]!=1)) return -1;
        for (size_t j=0;j<i;++j)
            if ((u[i]==u[j] && v[i]==v[j]) || weight[i]==weight[j]) return -1;
    }
    if (!output || capacity<m) return -2;

    size_t order[MAX_M];
    for (size_t i=0;i<m;++i) order[i]=i;
    for (size_t i=0;i<m;++i) {
        size_t best=i;
        for (size_t j=i+1;j<m;++j) if (weight[order[j]]<weight[order[best]]) best=j;
        size_t tmp=order[i]; order[i]=order[best]; order[best]=tmp;
    }
    size_t parent[MAX_N];
    uint8_t in_forest[MAX_M]={0}, staged[MAX_M]={0};
    for (size_t i=0;i<n;++i) parent[i]=i;
    for (size_t pos=0;pos<m;++pos) {
        size_t e=order[pos]; if (!sampled[e]) continue;
        size_t a=(size_t)u[e], b=(size_t)v[e];
        while (parent[a]!=a) a=parent[a];
        while (parent[b]!=b) b=parent[b];
        if (a!=b) { parent[b]=a; in_forest[e]=1; }
    }
    for (size_t e=0;e<m;++e) {
        if (in_forest[e]) { staged[e]=1; continue; }
        int64_t path_max[MAX_N]; size_t queue[MAX_N]; uint8_t visited[MAX_N]={0};
        for (size_t i=0;i<n;++i) path_max[i]=-1;
        size_t head=0,tail=0,start=(size_t)u[e],target=(size_t)v[e];
        queue[tail++]=start; visited[start]=1; path_max[start]=0;
        while (head<tail && !visited[target]) {
            size_t current=queue[head++];
            for (size_t k=0;k<m;++k) if (in_forest[k]) {
                int64_t next=-1;
                if ((size_t)u[k]==current) next=v[k];
                else if ((size_t)v[k]==current) next=u[k];
                if (next>=0 && !visited[(size_t)next]) {
                    visited[(size_t)next]=1;
                    int64_t edge_weight=weight[k];
                    path_max[(size_t)next]=path_max[current]>edge_weight?path_max[current]:edge_weight;
                    queue[tail++]=(size_t)next;
                }
            }
        }
        staged[e]=(uint8_t)(!visited[target] || weight[e]<path_max[target]);
    }
    for (size_t i=0;i<m;++i) output[i]=staged[i];
    return (int64_t)m;
}
