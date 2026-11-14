#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
using Matrix = std::array<std::array<std::int64_t, 16>, 16>;
std::int64_t send(std::size_t u, std::size_t sink, std::int64_t amount, Matrix& residual,
                  const std::array<int, 16>& level, std::array<std::size_t, 16>& cursor,
                  std::size_t n, std::int64_t threshold) {
    if (u == sink) return amount;
    while (cursor[u] < n) {
        const auto v = cursor[u];
        if (level[v] == level[u]+1 && residual[u][v] >= threshold) {
            const auto pushed = send(v, sink, std::min(amount, residual[u][v]), residual, level, cursor, n, threshold);
            if (pushed) { residual[u][v] -= pushed; residual[v][u] += pushed; return pushed; }
        }
        ++cursor[u];
    }
    return 0;
}
}

extern "C" std::int64_t dinic_capacity_scaling(const std::int64_t* input, std::size_t length) {
    if (!input || length < 4 || length > 197) return -1;
    const auto nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    const auto n=static_cast<std::size_t>(nv), m=static_cast<std::size_t>(mv);
    const auto source=static_cast<std::size_t>(sv-1), sink=static_cast<std::size_t>(tv-1);
    if (length != 4+3*m) return -1;
    Matrix residual{};
    for (std::size_t i=0; i<m; ++i) {
        const auto u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[static_cast<std::size_t>(u-1)][static_cast<std::size_t>(v-1)] += capacity;
    }
    std::int64_t greatest=0, threshold=1, flow=0;
    for (std::size_t u=0; u<n; ++u) for (std::size_t v=0; v<n; ++v) greatest=std::max(greatest,residual[u][v]);
    while (threshold <= greatest/2) threshold *= 2;
    if (!greatest) threshold=0;
    for (; threshold; threshold/=2) {
        for (;;) {
            std::array<int,16> level; level.fill(-1);
            std::array<std::size_t,16> queue{};
            std::size_t head=0, tail=0; level[source]=0; queue[tail++]=source;
            while (head<tail) {
                const auto u=queue[head++];
                for (std::size_t v=0; v<n; ++v) if (level[v]<0 && residual[u][v]>=threshold) {
                    level[v]=level[u]+1; queue[tail++]=v;
                }
            }
            if (level[sink]<0) break;
            std::array<std::size_t,16> cursor{};
            for (;;) {
                const auto pushed=send(source,sink,6401,residual,level,cursor,n,threshold);
                if (!pushed) break;
                flow+=pushed;
            }
        }
    }
    return flow;
}
