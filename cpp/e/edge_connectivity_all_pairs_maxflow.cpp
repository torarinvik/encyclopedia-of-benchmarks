#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 10;
constexpr std::size_t kMaxEdges = 45;
constexpr std::size_t kMaxParseable = 93;

int pair_flow(const std::array<std::array<std::uint8_t, kMaxVertices>, kMaxVertices>& adjacency,
              std::size_t n, std::size_t source, std::size_t sink, int limit) {
    std::array<std::array<int, kMaxVertices>, kMaxVertices> residual{};
    for (std::size_t u = 0; u < n; ++u)
        for (std::size_t v = 0; v < n; ++v)
            residual[u][v] = adjacency[u][v];

    int flow = 0;
    while (flow < limit) {
        std::array<int, kMaxVertices> parent;
        parent.fill(-1);
        std::array<std::size_t, kMaxVertices> queue{};
        parent[source] = static_cast<int>(source);
        std::size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            const auto u = queue[head++];
            for (std::size_t v = 0; v < n; ++v) {
                if (parent[v] < 0 && residual[u][v] > 0) {
                    parent[v] = static_cast<int>(u);
                    queue[tail++] = v;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        int amount = limit - flow;
        for (auto v = sink; v != source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            if (residual[u][v] < amount) amount = residual[u][v];
        }
        for (auto v = sink; v != source; v = static_cast<std::size_t>(parent[v])) {
            const auto u = static_cast<std::size_t>(parent[v]);
            residual[u][v] -= amount;
            residual[v][u] += amount;
        }
        flow += amount;
    }
    return flow;
}
}

extern "C" std::int64_t edge_connectivity_all_pairs_maxflow(const std::int64_t* input,
                                                               std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxParseable) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxVertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxEdges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<std::uint8_t, kMaxVertices>, kMaxVertices> adjacency{};
    for (std::size_t e = 0; e < m; ++e) {
        const auto left = input[2 + 2 * e], right = input[3 + 2 * e];
        if (left < 0 || right < 0 || left >= static_cast<std::int64_t>(n) ||
            right >= static_cast<std::int64_t>(n) || left == right) return -1;
        const auto u = static_cast<std::size_t>(left), v = static_cast<std::size_t>(right);
        if (adjacency[u][v] != 0) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }

    int best = static_cast<int>(n) - 1;
    for (std::size_t source = 0; source < n; ++source) {
        for (std::size_t sink = source + 1; sink < n; ++sink) {
            const int flow = pair_flow(adjacency, n, source, sink, best);
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
