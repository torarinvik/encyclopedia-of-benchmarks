#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t undirected_cycle_check_bfs(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 514 || input[0] < 0 || input[0] > 32 ||
        input[1] < 0 || input[1] > 256) return -1;
    auto n = static_cast<std::size_t>(input[0]);
    auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::array<std::array<bool, 32>, 32> adjacent{};
    std::array<bool, 32> visited{};
    for (std::size_t i = 0; i < m; ++i) {
        auto a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= static_cast<std::int64_t>(n) ||
            b >= static_cast<std::int64_t>(n) || adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = true;
    }
    std::array<std::size_t, 32> queue{}, parent{};
    for (std::size_t root = 0; root < n; ++root) {
        if (visited[root]) continue;
        std::size_t head = 0, tail = 0;
        queue[tail++] = root; parent[root] = n; visited[root] = true;
        while (head < tail) {
            auto u = queue[head++];
            for (std::size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
                if (!visited[v]) { visited[v] = true; parent[v] = u; queue[tail++] = v; }
                else if (v != parent[u]) return 1;
            }
        }
    }
    return 0;
}
