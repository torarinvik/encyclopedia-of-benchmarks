#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8, max_m = 12;
constexpr std::int64_t inf = 1'000'000'000;

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;
    if (n == 1) return m == 0 ? 0 : -1;
    if (m < n - 1) return -1;
    std::array<std::array<std::int64_t, max_n>, max_n> distance{};
    std::array<std::array<bool, max_n>, max_n> seen{};
    std::array<int, max_n> degree{};
    for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) distance[u][v] = u == v ? 0 : inf;
    std::int64_t total_weight = 0;
    for (int edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 3 * edge], v_value = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight < 1 || weight > 1000) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        if (seen[u][v]) return -1;
        seen[u][v] = seen[v][u] = true;
        distance[u][v] = distance[v][u] = weight;
        ++degree[u]; ++degree[v]; total_weight += weight;
    }
    for (int middle = 0; middle < n; ++middle) for (int source = 0; source < n; ++source) for (int target = 0; target < n; ++target)
        if (distance[source][middle] + distance[middle][target] < distance[source][target])
            distance[source][target] = distance[source][middle] + distance[middle][target];
    for (int vertex = 0; vertex < n; ++vertex) if (distance[0][vertex] >= inf) return -1;
    std::array<int, max_n> odd{};
    int odd_count = 0;
    for (int vertex = 0; vertex < n; ++vertex) if (degree[vertex] & 1) odd[odd_count++] = vertex;
    std::array<std::int64_t, 1 << max_n> pairing{};
    const int state_count = 1 << odd_count;
    pairing.fill(inf); pairing[0] = 0;
    for (int mask = 1; mask < state_count; ++mask) {
        int first = 0; while ((mask & (1 << first)) == 0) ++first;
        for (int partner = first + 1; partner < odd_count; ++partner) if (mask & (1 << partner)) {
            const int remaining = mask ^ (1 << first) ^ (1 << partner);
            const auto candidate = distance[odd[first]][odd[partner]] + pairing[remaining];
            if (candidate < pairing[mask]) pairing[mask] = candidate;
        }
    }
    return total_weight + pairing[state_count - 1];
}
}

extern "C" std::int64_t undirected_chinese_postman(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
