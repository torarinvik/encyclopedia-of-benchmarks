#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 8;
constexpr int kMaxM = 24;
constexpr int kMaxWorlds = 8;
constexpr int kWeightScale = 256;
constexpr std::size_t kMaxInput = 141;

void put_i64(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}

int reachable_count(int n, const std::array<int, kMaxN>& parent, std::uint16_t seeds) {
    std::array<int, kMaxN> queue{};
    int head = 0, tail = 0;
    auto reached = seeds;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((seeds & (std::uint16_t(1) << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        const int source = queue[head++];
        for (int target = 0; target < n; ++target) {
            const auto bit = static_cast<std::uint16_t>(std::uint16_t(1) << target);
            if (parent[target] == source && (reached & bit) == 0) {
                reached |= bit;
                queue[tail++] = target;
            }
        }
    }
    int count = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((reached & (std::uint16_t(1) << vertex)) != 0) ++count;
    }
    return count;
}
} // namespace

extern "C" std::int64_t influence_maximization_greedy_linear_threshold(
        const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > kMaxInput) return -1;
    const auto n0 = input[0], m0 = input[1], k0 = input[2], worlds0 = input[3];
    if (n0 < 1 || n0 > kMaxN || m0 < 0 || m0 > kMaxM
            || k0 < 0 || k0 > n0 || worlds0 < 1 || worlds0 > kMaxWorlds) return -1;
    const int n = static_cast<int>(n0), m = static_cast<int>(m0);
    const int k = static_cast<int>(k0), worlds = static_cast<int>(worlds0);
    const auto expected = std::size_t(4) + std::size_t(3) * m + std::size_t(worlds) * n;
    if (length != expected) return -1;

    std::array<int, kMaxM> edge_u{}, edge_v{}, edge_weight{};
    std::array<int, kMaxN> incoming_sum{};
    for (int edge = 0; edge < m; ++edge) {
        const auto u0 = input[4 + 3 * edge], v0 = input[5 + 3 * edge];
        const auto weight0 = input[6 + 3 * edge];
        if (u0 < 0 || u0 >= n || v0 < 0 || v0 >= n || u0 == v0
                || weight0 < 0 || weight0 > kWeightScale) return -1;
        const int u = static_cast<int>(u0), v = static_cast<int>(v0);
        for (int prior = 0; prior < edge; ++prior) {
            if (edge_u[prior] == u && edge_v[prior] == v) return -1;
        }
        incoming_sum[v] += static_cast<int>(weight0);
        if (incoming_sum[v] > kWeightScale) return -1;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = static_cast<int>(weight0);
    }

    std::array<std::array<int, kMaxN>, kMaxWorlds> draws{};
    const std::size_t draws_start = 4 + 3 * std::size_t(m);
    for (int world = 0; world < worlds; ++world) {
        for (int vertex = 0; vertex < n; ++vertex) {
            const auto draw = input[draws_start + std::size_t(world) * n + vertex];
            if (draw < 0 || draw >= kWeightScale) return -1;
            draws[world][vertex] = static_cast<int>(draw);
        }
    }

    std::array<std::array<int, kMaxN>, kMaxWorlds> parents{};
    for (int world = 0; world < worlds; ++world) {
        for (int target = 0; target < n; ++target) {
            parents[world][target] = -1;
            int offset = 0;
            for (int edge = 0; edge < m; ++edge) {
                if (edge_v[edge] != target) continue;
                const int next = offset + edge_weight[edge];
                if (offset <= draws[world][target] && draws[world][target] < next) {
                    parents[world][target] = edge_u[edge];
                    break;
                }
                offset = next;
            }
        }
    }

    std::uint16_t selected = 0;
    std::array<int, kMaxN> chosen{}, scores{};
    for (int round = 0; round < k; ++round) {
        std::array<int, kMaxWorlds> current{};
        for (int world = 0; world < worlds; ++world) {
            current[world] = reachable_count(n, parents[world], selected);
        }
        int best_node = -1, best_score = -1;
        for (int candidate = 0; candidate < n; ++candidate) {
            const auto bit = static_cast<std::uint16_t>(std::uint16_t(1) << candidate);
            if ((selected & bit) != 0) continue;
            int score = 0;
            for (int world = 0; world < worlds; ++world) {
                score += reachable_count(n, parents[world], selected | bit) - current[world];
            }
            if (score > best_score) {
                best_node = candidate;
                best_score = score;
            }
        }
        if (best_node < 0) return -1;
        selected |= static_cast<std::uint16_t>(std::uint16_t(1) << best_node);
        chosen[round] = best_node;
        scores[round] = best_score;
    }

    const std::size_t bytes = std::size_t(1 + 2 * k) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    put_i64(output, 0, k);
    for (int round = 0; round < k; ++round) {
        put_i64(output, std::size_t(1 + 2 * round), chosen[round]);
        put_i64(output, std::size_t(2 + 2 * round), scores[round]);
    }
    return static_cast<std::int64_t>(bytes);
}
