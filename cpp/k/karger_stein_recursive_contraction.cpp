// Independently authored draft; not compiled or run.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
struct Graph {
    int n, m;
    std::array<int, 32> from{}, to{};
    const std::int64_t* tape;
    std::size_t size, position = 0;
};
using Parents = std::array<int, 12>;

int root(const Parents& parent, int v) {
    while (parent[v] != v) v = parent[v];
    return v;
}

int solve(Graph& graph, const Parents& parent, int components) {
    if (components <= 6) {
        std::array<int, 12> index{};
        int used = 0;
        for (int i = 0; i < graph.n; ++i) if (parent[i] == i) index[i] = used++;
        int best = graph.m + 1;
        for (unsigned mask = 0; mask < (1u << (components - 1)) - 1; ++mask) {
            const unsigned side = (mask << 1) | 1u;
            int cut = 0;
            for (int e = 0; e < graph.m; ++e) {
                const int a = index[root(parent, graph.from[e])];
                const int b = index[root(parent, graph.to[e])];
                cut += ((side >> a) & 1u) != ((side >> b) & 1u);
            }
            best = std::min(best, cut);
        }
        return best;
    }
    constexpr std::array<int, 13> target{0,0,0,0,0,0,0,6,7,8,9,9,10};
    int best = graph.m + 1;
    for (int branch = 0; branch < 2; ++branch) {
        auto next = parent;
        for (int count = components; count > target[components]; --count) {
            int live = 0;
            for (int e = 0; e < graph.m; ++e)
                if (root(next, graph.from[e]) != root(next, graph.to[e])) ++live;
            if (graph.position >= graph.size) return -1;
            auto rank = graph.tape[graph.position++];
            if (rank < 0 || rank >= live) return -1;
            for (int e = 0; e < graph.m; ++e) {
                const int a = root(next, graph.from[e]), b = root(next, graph.to[e]);
                if (a == b) continue;
                if (rank-- == 0) { next[b] = a; break; }
            }
        }
        const int result = solve(graph, next, target[components]);
        if (result < 0) return -1;
        best = std::min(best, result);
    }
    return best;
}
}

extern "C" std::int64_t karger_stein_recursive_contraction(
        const std::int64_t* input, std::size_t length) {
    if (!input || length < 3 || length > 132) return -1;
    if (input[0] < 2 || input[0] > 12 || input[1] < 1 || input[1] > 32
        || input[2] < 0 || input[2] > 64) return -1;
    Graph graph{};
    graph.n = static_cast<int>(input[0]); graph.m = static_cast<int>(input[1]);
    graph.size = static_cast<std::size_t>(input[2]);
    if (length != 3 + 2 * static_cast<std::size_t>(graph.m) + graph.size) return -1;
    Parents parent{};
    for (int i = 0; i < 12; ++i) parent[i] = i;
    for (int i = 0; i < graph.m; ++i) {
        const auto u = input[3+2*i], v = input[4+2*i];
        if (u < 0 || v < 0 || u >= graph.n || v >= graph.n || u == v) return -1;
        graph.from[i] = static_cast<int>(u); graph.to[i] = static_cast<int>(v);
        parent[root(parent, graph.to[i])] = root(parent, graph.from[i]);
    }
    for (int i = 1; i < graph.n; ++i) if (root(parent, i) != root(parent, 0)) return -1;
    for (int i = 0; i < 12; ++i) parent[i] = i;
    graph.tape = input + 3 + 2*graph.m;
    const int result = solve(graph, parent, graph.n);
    return result < 0 || graph.position != graph.size ? -1 : result;
}
