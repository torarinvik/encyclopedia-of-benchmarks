/* Clean-room vertex-split max-flow for undirected global vertex connectivity. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 10, MAX_M = 45, MAX_INPUT = 92, MAX_DN = 20;

int pair_vertex_flow(const std::uint64_t adjacency[MAX_N], std::size_t n,
                     std::size_t source_vertex, std::size_t target_vertex, int limit) noexcept {
    int residual[MAX_DN][MAX_DN]{};
    const std::size_t nodes = 2*n;
    for (std::size_t v=0; v<n; ++v)
        residual[2*v][2*v+1]=(v==source_vertex || v==target_vertex) ? static_cast<int>(n) : 1;
    for (std::size_t u=0; u<n; ++u)
        for (std::size_t v=u+1; v<n; ++v)
            if ((adjacency[u] & (std::uint64_t{1}<<v))!=0) {
                residual[2*u+1][2*v]=1; residual[2*v+1][2*u]=1;
            }
    const std::size_t source=2*source_vertex+1, sink=2*target_vertex;
    int flow=0;
    while (flow<limit) {
        int parent[MAX_DN]; std::size_t queue[MAX_DN];
        for (std::size_t v=0; v<nodes; ++v) parent[v]=-1;
        parent[source]=static_cast<int>(source);
        std::size_t head=0, tail=0; queue[tail++]=source;
        while (head<tail && parent[sink]<0) {
            const std::size_t u=queue[head++];
            for (std::size_t v=0; v<nodes; ++v)
                if (parent[v]<0 && residual[u][v]>0) {
                    parent[v]=static_cast<int>(u); queue[tail++]=v;
                    if (v==sink) break;
                }
        }
        if (parent[sink]<0) break;
        int amount=limit-flow;
        for (std::size_t v=sink; v!=source; v=static_cast<std::size_t>(parent[v])) {
            const auto u=static_cast<std::size_t>(parent[v]);
            if (residual[u][v]<amount) amount=residual[u][v];
        }
        for (std::size_t v=sink; v!=source; v=static_cast<std::size_t>(parent[v])) {
            const auto u=static_cast<std::size_t>(parent[v]);
            residual[u][v]-=amount; residual[v][u]+=amount;
        }
        flow+=amount;
    }
    return flow;
}
}

extern "C" std::int64_t vertex_connectivity(const std::int64_t* input,
                                              std::size_t length) noexcept {
    if (!input || length<2 || length>MAX_INPUT) return -1;
    if (input[0]<0 || input[0]>static_cast<std::int64_t>(MAX_N) ||
        input[1]<0 || input[1]>static_cast<std::int64_t>(MAX_M)) return -1;
    const auto n=static_cast<std::size_t>(input[0]), m=static_cast<std::size_t>(input[1]);
    if (length!=2+2*m) return -1;
    std::uint64_t adjacency[MAX_N]{};
    for (std::size_t e=0; e<m; ++e) {
        const auto left=input[2+2*e], right=input[3+2*e];
        if (left<0 || right<0 || left>=static_cast<std::int64_t>(n) ||
            right>=static_cast<std::int64_t>(n)) return -1;
        if (left!=right) {
            adjacency[static_cast<std::size_t>(left)] |= std::uint64_t{1}<<static_cast<std::size_t>(right);
            adjacency[static_cast<std::size_t>(right)] |= std::uint64_t{1}<<static_cast<std::size_t>(left);
        }
    }
    if (n<=1) return 0;
    std::uint64_t reached=1; std::size_t queue[MAX_N], head=0, tail=0; queue[tail++]=0;
    while (head<tail) {
        const auto u=queue[head++];
        for (std::size_t v=0; v<n; ++v) {
            const auto bit=std::uint64_t{1}<<v;
            if ((adjacency[u]&bit)!=0 && (reached&bit)==0) { reached|=bit; queue[tail++]=v; }
        }
    }
    if (reached!=((std::uint64_t{1}<<n)-1)) return 0;
    int best=static_cast<int>(n)-1;
    for (std::size_t source=0; source<n; ++source)
        for (std::size_t target=source+1; target<n; ++target) {
            if ((adjacency[source]&(std::uint64_t{1}<<target))!=0) continue;
            const int flow=pair_vertex_flow(adjacency,n,source,target,best);
            if (flow<best) best=flow;
            if (best==0) return 0;
        }
    return best;
}
