#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

namespace {
using Pair = std::array<std::int64_t, 2>;
struct Edge { int u, v; std::int64_t weight; };

Pair merge(Pair a, Pair b) {
    Pair result{-1, -1};
    for (auto value : {a[0], a[1], b[0], b[1]}) {
        if (value > result[0]) { result[1] = result[0]; result[0] = value; }
        else if (value < result[0] && value > result[1]) result[1] = value;
    }
    return result;
}

int root(std::array<int, 8>& parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}
}

extern "C" std::int64_t second_best_mst_binary_lifting(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 63) return -1;
    const auto nv = input[0], mv = input[1];
    if (nv < 1 || nv > 8 || mv < nv - 1 || mv > 20 || length != static_cast<std::size_t>(2 + 3 * mv)) return -1;
    const int n = static_cast<int>(nv), m = static_cast<int>(mv);
    std::array<std::array<bool, 8>, 8> seen{};
    std::vector<Edge> edges;
    for (int i = 0; i < m; ++i) {
        const auto u = input[2 + 3 * i], v = input[3 + 3 * i], weight = input[4 + 3 * i];
        if (u < 0 || u >= v || v >= nv || weight < 0 || weight > 1000000 || seen[u][v]) return -1;
        seen[u][v] = true;
        edges.push_back({static_cast<int>(u), static_cast<int>(v), weight});
    }
    std::vector<int> order(m);
    std::iota(order.begin(), order.end(), 0);
    std::sort(order.begin(), order.end(), [&](int a, int b) {
        return std::pair{edges[a].weight, a} < std::pair{edges[b].weight, b};
    });
    std::array<int, 8> parent{};
    std::iota(parent.begin(), parent.end(), 0);
    std::array<bool, 20> selected{};
    std::array<std::vector<std::pair<int, std::int64_t>>, 8> tree;
    int count = 0;
    std::int64_t total = 0;
    for (int id : order) {
        const auto& e = edges[id];
        const int a = root(parent, e.u), b = root(parent, e.v);
        if (a == b) continue;
        parent[a] = b; selected[id] = true; ++count; total += e.weight;
        tree[e.u].emplace_back(e.v, e.weight);
        tree[e.v].emplace_back(e.u, e.weight);
    }
    if (count != n - 1) return -1;
    std::array<std::array<int, 8>, 4> up{};
    std::array<std::array<Pair, 8>, 4> best;
    for (auto& level : best) for (auto& item : level) item = {-1, -1};
    std::array<int, 8> depth;
    depth.fill(-1);
    depth[0] = 0;
    std::vector<int> queue{0};
    for (std::size_t head = 0; head < queue.size(); ++head) {
        int vertex = queue[head];
        for (auto [next, weight] : tree[vertex]) {
            if (depth[next] >= 0) continue;
            depth[next] = depth[vertex] + 1; up[0][next] = vertex;
            best[0][next] = {weight, -1}; queue.push_back(next);
        }
    }
    for (int level = 1; level < 4; ++level)
        for (int vertex = 0; vertex < n; ++vertex) {
            int mid = up[level - 1][vertex];
            up[level][vertex] = up[level - 1][mid];
            best[level][vertex] = merge(best[level - 1][vertex], best[level - 1][mid]);
        }
    std::int64_t increase = -1;
    for (int id = 0; id < m; ++id) {
        if (selected[id]) continue;
        auto [a, b, weight] = edges[id];
        if (depth[a] < depth[b]) std::swap(a, b);
        Pair path{-1, -1};
        int difference = depth[a] - depth[b];
        for (int level = 0; level < 4; ++level)
            if (difference & (1 << level)) { path = merge(path, best[level][a]); a = up[level][a]; }
        if (a != b) {
            for (int level = 3; level >= 0; --level)
                if (up[level][a] != up[level][b]) {
                    path = merge(merge(path, best[level][a]), best[level][b]);
                    a = up[level][a]; b = up[level][b];
                }
            path = merge(merge(path, best[0][a]), best[0][b]);
        }
        const auto removed = weight > path[0] ? path[0] : path[1];
        if (removed >= 0 && removed < weight) {
            const auto delta = weight - removed;
            if (increase < 0 || delta < increase) increase = delta;
        }
    }
    return increase < 0 ? 0 : total + increase + 1;
}
