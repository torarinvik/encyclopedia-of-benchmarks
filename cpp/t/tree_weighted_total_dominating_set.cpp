// Uncompiled weighted total-domination tree draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::int64_t inf=1000000000000LL;
std::int64_t add(std::int64_t a,std::int64_t b) { return std::min(inf,a+b); }
}
extern "C" std::int64_t tree_weighted_total_dominating_set(const std::int64_t* input,std::size_t length) {
    if (!input || length<2 || length>129) return -1;
    const auto nv=input[0];
    if (nv<1 || nv>64 || length!=static_cast<std::size_t>(2*nv)) return -1;
    const auto n=static_cast<std::size_t>(nv);
    for (std::size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=static_cast<std::int64_t>(v)) return -1;
    std::array<std::int64_t,64> weights{};
    std::array<std::array<std::int64_t,2>,64> none{},some{};
    for (std::size_t v=0; v<n; ++v) {
        weights[v]=input[n+v];
        if (weights[v]<0 || weights[v]>1000000) return -1;
        some[v].fill(inf);
    }
    std::int64_t root=inf;
    for (std::size_t v=n; v-- > 0;) {
        std::array<std::array<std::int64_t,2>,2> dp{};
        for (int chosen=0; chosen<2; ++chosen) {
            const auto own=chosen ? weights[v] : 0;
            dp[chosen][0]=add(own,some[v][chosen]);
            dp[chosen][1]=add(own,std::min(none[v][chosen],some[v][chosen]));
        }
        if (v==0) { root=std::min(dp[0][0],dp[1][0]); break; }
        const auto p=static_cast<std::size_t>(input[v]);
        for (int chosen=0; chosen<2; ++chosen) {
            const auto a=dp[0][chosen], b=dp[1][chosen];
            const auto next=std::min(add(some[p][chosen],std::min(a,b)),add(none[p][chosen],b));
            none[p][chosen]=add(none[p][chosen],a);
            some[p][chosen]=next;
        }
    }
    return root==inf ? -2 : root;
}
