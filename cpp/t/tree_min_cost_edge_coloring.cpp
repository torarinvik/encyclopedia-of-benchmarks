// Uncompiled matching-sensitivity tree edge-coloring draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
using Matrix = std::array<std::array<std::int64_t,16>,16>;
constexpr std::int64_t inf = 1000000000000000LL;

bool assignment(int d, int width, const Matrix& cost, std::int64_t& base,
                std::array<std::int64_t,16>& deletion) {
    std::array<std::int64_t,17> row_dual{}, col_dual{};
    std::array<int,17> owner{};
    for (int row=1; row<=d; ++row) {
        std::array<int,17> previous{};
        std::array<bool,17> used{};
        std::array<std::int64_t,17> slack; slack.fill(inf);
        owner[0]=row;
        int col=0;
        for (;;) {
            used[col]=true;
            const int active=owner[col];
            auto step=inf; int next_col=0;
            for (int c=1; c<=width; ++c) {
                if (used[c]) continue;
                const auto reduced=cost[active-1][c-1]-row_dual[active]-col_dual[c];
                if (reduced<slack[c]) { slack[c]=reduced; previous[c]=col; }
                if (slack[c]<step) { step=slack[c]; next_col=c; }
            }
            if (!next_col) return false;
            for (int c=0; c<=width; ++c) {
                if (used[c]) { row_dual[owner[c]]+=step; col_dual[c]-=step; }
                else if (c) slack[c]-=step;
            }
            col=next_col;
            if (!owner[col]) break;
        }
        while (col) { const int parent=previous[col]; owner[col]=owner[parent]; col=parent; }
    }
    base=0; int free_col=-1;
    for (int col=0; col<width; ++col) {
        if (owner[col+1]) base+=cost[owner[col+1]-1][col];
        else free_col=col;
    }
    if (width==d) return true;
    if (free_col<0) return false;
    std::array<std::int64_t,16> distance; distance.fill(inf); distance[free_col]=0;
    for (int pass=0; pass<d; ++pass) {
        auto next=distance;
        for (int col=0; col<width; ++col) {
            const int row=owner[col+1]-1;
            if (row<0) continue;
            for (int dest=0; dest<width; ++dest) if (distance[dest]!=inf)
                next[col]=std::min(next[col],cost[row][dest]-cost[row][col]+distance[dest]);
        }
        distance=next;
    }
    for (int col=0; col<width; ++col) {
        if (distance[col]==inf) return false;
        deletion[col]=base+distance[col];
    }
    return true;
}
}

extern "C" std::int64_t tree_min_cost_edge_coloring(const std::int64_t* input, std::size_t length) {
    if (!input || length<2 || length>82) return -1;
    const auto nv=input[0], kv=input[1];
    if (nv<1 || nv>64 || kv<1 || kv>16) return -1;
    const int n=static_cast<int>(nv), k=static_cast<int>(kv);
    if (length!=static_cast<std::size_t>(n+1+k)) return -1;
    std::array<int,64> parents{}, degree{}, child_count{};
    for (int v=1; v<n; ++v) {
        const auto parent=input[1+v];
        if (parent<0 || parent>=v) return -1;
        parents[v]=static_cast<int>(parent); ++degree[parents[v]]; ++degree[v];
    }
    std::array<std::int64_t,16> prices{};
    for (int c=0; c<k; ++c) {
        const auto value=input[n+1+c];
        if (value<0 || value>1000000) return -1;
        prices[c]=value;
    }
    for (int v=0; v<n; ++v) if (degree[v]>k) return -2;
    std::sort(prices.begin(),prices.begin()+k);
    std::array<std::array<int,16>,64> children{};
    for (int v=1; v<n; ++v) { const int p=parents[v]; children[p][child_count[p]++]=v; }
    std::array<std::array<std::int64_t,16>,64> tables{};
    for (int v=n-1; v>=0; --v) {
        const int d=child_count[v];
        if (!d) continue;
        const bool saturated_root=v==0 && d==k;
        const int width=saturated_root ? d : d+1;
        Matrix cost{};
        for (int row=0; row<d; ++row) {
            const int child=children[v][row];
            for (int col=0; col<width; ++col)
                cost[row][col]=prices[col]+tables[child][std::min(col,child_count[child])];
        }
        std::array<std::int64_t,16> deletion{}; std::int64_t base=0;
        if (!assignment(d,width,cost,base,deletion)) return -1;
        if (saturated_root) tables[v][0]=base;
        else std::copy_n(deletion.begin(),width,tables[v].begin());
    }
    return child_count[0]==k ? tables[0][0] : tables[0][child_count[0]];
}
