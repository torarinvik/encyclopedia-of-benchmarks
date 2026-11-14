// Uncompiled bounded minimum-cost proper tree coloring draft.
#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <algorithm>
extern "C" std::int64_t tree_min_cost_proper_coloring(const std::int64_t* input, std::size_t length) {
    if (!input || length<2 || length>1090) return -1;
    const auto nv=input[0], kv=input[1];
    if (nv<1 || nv>64 || kv<1 || kv>16) return -1;
    const auto n=static_cast<std::size_t>(nv), k=static_cast<std::size_t>(kv);
    if (length!=n+1+n*k) return -1;
    for (std::size_t v=1; v<n; ++v) if (input[1+v]<0 || input[1+v]>=static_cast<std::int64_t>(v)) return -1;
    std::array<std::array<std::int64_t,16>,64> dp{};
    for (std::size_t v=0; v<n; ++v) for (std::size_t c=0; c<k; ++c) {
        auto cost=input[n+1+v*k+c]; if (cost<0 || cost>1000000) return -1; dp[v][c]=cost;
    }
    if (n>1 && k==1) return -2;
    for (std::size_t child=n; child-- > 1;) {
        const auto parent=static_cast<std::size_t>(input[1+child]);
        auto least=std::numeric_limits<std::int64_t>::max(), second=least;
        std::size_t best_color=0;
        for (std::size_t c=0; c<k; ++c) {
            auto value=dp[child][c];
            if (value<least) { second=least; least=value; best_color=c; }
            else if (value<second) second=value;
        }
        for (std::size_t c=0; c<k; ++c) dp[parent][c]+=c==best_color ? second : least;
    }
    return *std::min_element(dp[0].begin(),dp[0].begin()+k);
}
