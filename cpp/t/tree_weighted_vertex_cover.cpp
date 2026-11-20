// Uncompiled weighted tree vertex-cover draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t tree_weighted_vertex_cover(const std::int64_t* input, std::size_t length) {
    if (!input || length<2 || length>129) return -1;
    const auto nv=input[0];
    if (nv<1 || nv>64 || length!=static_cast<std::size_t>(2*nv)) return -1;
    const auto n=static_cast<std::size_t>(nv);
    for (std::size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=static_cast<std::int64_t>(v)) return -1;
    std::array<std::int64_t,64> included{}, excluded{};
    for (std::size_t v=0; v<n; ++v) {
        const auto weight=input[n+v]; if (weight<0 || weight>1000000) return -1;
        included[v]=weight;
    }
    for (std::size_t v=n; v-- > 1;) {
        const auto p=static_cast<std::size_t>(input[v]);
        included[p]+=std::min(included[v],excluded[v]); excluded[p]+=included[v];
    }
    return std::min(included[0],excluded[0]);
}
