#include <array>
#include <cstddef>
#include <cstdint>
#include <algorithm>

extern "C" std::int64_t highest_label_push_relabel(const std::int64_t* input, std::size_t length) {
    if (!input || length<4 || length>197) return -1;
    const auto nv=input[0], mv=input[1], sv=input[2], tv=input[3];
    if (nv<2 || nv>16 || mv<0 || mv>64 || sv<1 || sv>nv || tv<1 || tv>nv || sv==tv) return -1;
    const auto n=static_cast<std::size_t>(nv), m=static_cast<std::size_t>(mv);
    const auto source=static_cast<std::size_t>(sv-1), sink=static_cast<std::size_t>(tv-1);
    if (length!=4+3*m) return -1;
    std::array<std::array<std::int64_t,16>,16> residual{};
    std::array<std::int64_t,16> excess{};
    std::array<int,16> height{};
    for (std::size_t i=0; i<m; ++i) {
        const auto u=input[4+3*i], v=input[5+3*i], capacity=input[6+3*i];
        if (u<1 || u>nv || v<1 || v>nv || u==v || capacity<0 || capacity>100) return -1;
        residual[static_cast<std::size_t>(u-1)][static_cast<std::size_t>(v-1)] += capacity;
    }
    height[source]=static_cast<int>(n);
    for (std::size_t v=0; v<n; ++v) {
        const auto amount=residual[source][v]; residual[source][v]=0;
        residual[v][source]+=amount; excess[v]+=amount; excess[source]-=amount;
    }
    for (;;) {
        int active=-1;
        for (std::size_t v=0; v<n; ++v)
            if (v!=source && v!=sink && excess[v]>0 && (active<0 || height[v]>height[active])) active=static_cast<int>(v);
        if (active<0) return excess[sink];
        const auto u=static_cast<std::size_t>(active);
        int destination=-1, minimum=static_cast<int>(2*n+1);
        for (std::size_t v=0; v<n; ++v) if (residual[u][v]>0) {
            minimum=std::min(minimum,height[v]);
            if (destination<0 && height[u]==height[v]+1) destination=static_cast<int>(v);
        }
        if (destination<0) {
            if (minimum>static_cast<int>(2*n)) return -1;
            height[u]=minimum+1;
        } else {
            const auto v=static_cast<std::size_t>(destination);
            const auto amount=std::min(excess[u],residual[u][v]);
            residual[u][v]-=amount; residual[v][u]+=amount; excess[u]-=amount; excess[v]+=amount;
        }
    }
}
