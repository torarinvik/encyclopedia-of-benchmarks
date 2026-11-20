#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 8;
constexpr int kMaxM = 24;
constexpr int kMaxWorlds = 8;

void put_i64(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}

int reachable_count(int n, int m, int world, std::uint16_t seeds,
                    const int edge_u[kMaxM], const int edge_v[kMaxM],
                    const int masks[kMaxM]) {
    int queue[kMaxN]{};
    int head = 0;
    int tail = 0;
    auto reached = seeds;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((seeds & (1u << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        const int source = queue[head++];
        for (int edge = 0; edge < m; ++edge) {
            const int target = edge_v[edge];
            const auto bit = static_cast<std::uint16_t>(1u << target);
            if (edge_u[edge] == source && (masks[edge] & (1 << world)) != 0
                    && (reached & bit) == 0) {
                reached = static_cast<std::uint16_t>(reached | bit);
                queue[tail++] = target;
            }
        }
    }
    int count = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((reached & (1u << vertex)) != 0) ++count;
    }
    return count;
}
}  // namespace

extern "C" std::int64_t influence_maximization_greedy_live_edge(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > 77) return -1;
    const auto n0 = input[0];
    const auto m0 = input[1];
    const auto k0 = input[2];
    const auto worlds0 = input[3];
    if (n0 < 1 || n0 > kMaxN || m0 < 0 || m0 > kMaxM
            || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > kMaxWorlds
            || length != 4 + 3 * static_cast<std::size_t>(m0)) return -1;
    const int n = static_cast<int>(n0);
    const int m = static_cast<int>(m0);
    const int k = static_cast<int>(k0);
    const int worlds = static_cast<int>(worlds0);
    int edge_u[kMaxM]{};
    int edge_v[kMaxM]{};
    int masks[kMaxM]{};
    const int allowed = (1 << worlds) - 1;
    for (int edge = 0; edge < m; ++edge) {
        const auto u = input[4 + 3 * edge];
        const auto v = input[5 + 3 * edge];
        const auto mask = input[6 + 3 * edge];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v
                || mask < 0 || mask > allowed) return -1;
        for (int earlier = 0; earlier < edge; ++earlier) {
            if (edge_u[earlier] == u && edge_v[earlier] == v) return -1;
        }
        edge_u[edge] = static_cast<int>(u);
        edge_v[edge] = static_cast<int>(v);
        masks[edge] = static_cast<int>(mask);
    }

    std::uint16_t selected = 0;
    int chosen[kMaxN]{};
    int scores[kMaxN]{};
    for (int round = 0; round < k; ++round) {
        int current[kMaxWorlds]{};
        for (int world = 0; world < worlds; ++world) {
            current[world] = reachable_count(n, m, world, selected, edge_u, edge_v, masks);
        }
        int best_node = -1;
        int best_score = -1;
        for (int candidate = 0; candidate < n; ++candidate) {
            const auto bit = static_cast<std::uint16_t>(1u << candidate);
            if ((selected & bit) != 0) continue;
            int score = 0;
            for (int world = 0; world < worlds; ++world) {
                score += reachable_count(n, m, world,
                        static_cast<std::uint16_t>(selected | bit), edge_u, edge_v, masks)
                        - current[world];
            }
            if (score > best_score) {
                best_node = candidate;
                best_score = score;
            }
        }
        if (best_node < 0) return -1;
        selected = static_cast<std::uint16_t>(selected | (1u << best_node));
        chosen[round] = best_node;
        scores[round] = best_score;
    }

    const auto bytes = static_cast<std::size_t>(1 + 2 * k) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, k);
    for (int round = 0; round < k; ++round) {
        put_i64(output, 1 + 2 * round, chosen[round]);
        put_i64(output, 2 + 2 * round, scores[round]);
    }
    return static_cast<std::int64_t>(bytes);
}
