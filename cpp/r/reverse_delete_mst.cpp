#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_N = 8;
constexpr int MAX_M = 20;
constexpr std::size_t MAX_INPUT = 63;
struct Edge { std::int32_t u = 0, v = 0, weight = 0; };

bool graph_connected(int n, const std::array<Edge, MAX_M> &edges, int m, std::uint32_t active) {
    std::array<bool, MAX_N> seen{};
    std::array<int, MAX_N> queue{};
    int head = 0, tail = 0;
    seen[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const int vertex = queue[head++];
        for (int id = 0; id < m; ++id) {
            if (((active >> id) & 1u) == 0) continue;
            int neighbor = -1;
            if (edges[id].u == vertex) neighbor = edges[id].v;
            else if (edges[id].v == vertex) neighbor = edges[id].u;
            if (neighbor >= 0 && !seen[neighbor]) {
                seen[neighbor] = true;
                queue[tail++] = neighbor;
            }
        }
    }
    for (int vertex = 0; vertex < n; ++vertex) if (!seen[vertex]) return false;
    return true;
}

void store_i64_le(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t reverse_delete_mst(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 2 || input[0] > MAX_N || input[1] < input[0] - 1 || input[1] > MAX_M) return -1;
    const int n = static_cast<int>(input[0]);
    const int m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;

    std::array<Edge, MAX_M> edges{};
    std::array<int, MAX_M> order{};
    for (int id = 0; id < m; ++id) {
        const auto u = input[2 + 3 * id], v = input[3 + 3 * id], w = input[4 + 3 * id];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || w < 0 || w > 1000) return -1;
        edges[id] = {static_cast<std::int32_t>(u), static_cast<std::int32_t>(v), static_cast<std::int32_t>(w)};
        order[id] = id;
        const auto low = u < v ? u : v;
        const auto high = u < v ? v : u;
        for (int prior = 0; prior < id; ++prior) {
            const auto prior_low = edges[prior].u < edges[prior].v ? edges[prior].u : edges[prior].v;
            const auto prior_high = edges[prior].u < edges[prior].v ? edges[prior].v : edges[prior].u;
            if (low == prior_low && high == prior_high) return -1;
        }
    }
    for (int i = 1; i < m; ++i) {
        const int item = order[i];
        int j = i;
        while (j > 0 && (edges[order[j - 1]].weight < edges[item].weight ||
               (edges[order[j - 1]].weight == edges[item].weight && order[j - 1] < item))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = item;
    }
    std::uint32_t active = (1u << m) - 1u;
    if (!graph_connected(n, edges, m, active)) return -1;
    for (int position = 0; position < m; ++position) {
        const auto candidate = active & ~(1u << order[position]);
        if (graph_connected(n, edges, m, candidate)) active = candidate;
    }
    std::int64_t total_weight = 0;
    for (int id = 0; id < m; ++id) if ((active >> id) & 1u) total_weight += edges[id].weight;
    if (output == nullptr || capacity < 16) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(active));
    store_i64_le(output, 8, total_weight);
    return 16;
}
