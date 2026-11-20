// Uncompiled weighted tree dominating-set draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::int64_t inf=1000000000000LL;
std::int64_t add(std::int64_t a,std::int64_t b) { return std::min(inf,a+b); }
}
extern "C" std::int64_t tree_weighted_dominating_set(const std::int64_t* input,std::size_t length) {
    if (!input || length<2 || length>129) return -1;
    const auto nv=input[0];
    if (nv<1 || nv>64 || length!=static_cast<std::size_t>(2*nv)) return -1;
    const auto n=static_cast<std::size_t>(nv);
    for (std::size_t v=1; v<n; ++v) if (input[v]<0 || input[v]>=static_cast<std::int64_t>(v)) return -1;
    std::array<std::int64_t,64> selected{},covered{},waiting{};
    covered.fill(inf);
    for (std::size_t v=0; v<n; ++v) {
        auto weight=input[n+v]; if (weight<0 || weight>1000000) return -1;
        selected[v]=weight;
    }
    for (std::size_t v=n; v-- > 1;) {
        auto p=static_cast<std::size_t>(input[v]);
        auto a=selected[v],b=covered[v],c=waiting[v];
        auto next=std::min(add(covered[p],std::min(a,b)),add(waiting[p],a));
        selected[p]=add(selected[p],std::min({a,b,c}));
        waiting[p]=add(waiting[p],b);
        covered[p]=next;
    }
    return std::min(selected[0],covered[0]);
}
