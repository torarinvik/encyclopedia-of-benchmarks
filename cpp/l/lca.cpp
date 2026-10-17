#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 64, max_input = 129;
std::size_t find_root(std::size_t *parent, std::size_t v) {
    while (parent[v] != v) { parent[v] = parent[parent[v]]; v = parent[v]; }
    return v;
}
}

extern "C" std::int64_t lca(const std::int64_t *input, std::size_t length) {
    if (!input || length < 3 || length > max_input || input[0] < 1 || input[0] > (std::int64_t)max_nodes) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 2*n+1) return -1;
    std::size_t dsu[max_nodes], degree[max_nodes] = {};
    std::size_t adjacency[max_nodes][max_nodes];
    for (std::size_t i=0;i<n;++i) dsu[i]=i;
    std::size_t pos=1;
    for (std::size_t e=0;e+1<n;++e) {
        const auto u64=input[pos], v64=input[pos+1]; pos+=2;
        if (u64<0 || u64>=static_cast<std::int64_t>(n) || v64<0 || v64>=static_cast<std::int64_t>(n) || u64==v64) return -1;
        const auto u=static_cast<std::size_t>(u64), v=static_cast<std::size_t>(v64);
        const auto ru=find_root(dsu,u), rv=find_root(dsu,v);
        if (ru==rv) return -1;
        dsu[ru]=rv; adjacency[u][degree[u]++]=v; adjacency[v][degree[v]++]=u;
    }
    const auto qa64=input[pos], qb64=input[pos+1];
    if (qa64<0 || qa64>=static_cast<std::int64_t>(n) || qb64<0 || qb64>=static_cast<std::int64_t>(n)) return -1;
    const auto component=find_root(dsu,0);
    for (std::size_t i=1;i<n;++i) if (find_root(dsu,i)!=component) return -1;
    std::size_t parent[max_nodes], depth[max_nodes], stack[max_nodes], stack_size=0;
    bool seen[max_nodes]={};
    parent[0]=0; depth[0]=0; seen[0]=true; stack[stack_size++]=0;
    while (stack_size) {
        const auto v=stack[--stack_size];
        for (std::size_t i=0;i<degree[v];++i) {
            const auto next=adjacency[v][i];
            if (!seen[next]) { seen[next]=true; parent[next]=v; depth[next]=depth[v]+1; stack[stack_size++]=next; }
        }
    }
    auto a=static_cast<std::size_t>(qa64), b=static_cast<std::size_t>(qb64);
    if (depth[a]<depth[b]) { const auto t=a; a=b; b=t; }
    while (depth[a]!=depth[b]) a=parent[a];
    if (a==b) return static_cast<std::int64_t>(a);
    while (a!=b) { a=parent[a]; b=parent[b]; }
    return static_cast<std::int64_t>(a);
}
