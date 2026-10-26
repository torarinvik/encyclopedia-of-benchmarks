#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 16, D = 4, EDGES = 32, T = 4, R = 8, L = 8, INPUT = 330;
void put(std::uint8_t *out, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) { out[i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t sublinear_bipartiteness_walk_tester(const std::int64_t *v, std::size_t length,
    std::uint8_t *out, std::size_t capacity) {
    if (!v || length < 8 || length > INPUT || v[0] < 1 || v[0] > N || v[1] < 3 || v[1] > D || v[2] < 0 || v[2] > EDGES) return -1;
    const int n = static_cast<int>(v[0]), d = static_cast<int>(v[1]), m = static_cast<int>(v[2]);
    if (m > n * d / 2) return -1;
    bool adjacent[N][N]{}; int neighbors[N][D]{}; int degree[N]{};
    const std::size_t suffix = static_cast<std::size_t>(3 + 2 * m);
    if (length < suffix + 4 || v[suffix] < 1 || v[suffix] > T || v[suffix + 1] < 1 || v[suffix + 1] > R || v[suffix + 2] < 1 || v[suffix + 2] > L) return -1;
    const int starts_count = static_cast<int>(v[suffix]), walks = static_cast<int>(v[suffix + 1]), steps = static_cast<int>(v[suffix + 2]);
    if (length != suffix + 3 + static_cast<std::size_t>(starts_count) + static_cast<std::size_t>(starts_count * walks * steps)) return -1;
    for (int e = 0; e < m; ++e) {
        const auto a0 = v[3 + 2 * e], b0 = v[4 + 2 * e];
        if (a0 < 0 || b0 < 0 || a0 >= n || b0 >= n || a0 >= b0) return -1;
        const int a = static_cast<int>(a0), b = static_cast<int>(b0);
        if (adjacent[a][b] || degree[a] >= d || degree[b] >= d) return -1;
        adjacent[a][b] = adjacent[b][a] = true;
        int at = degree[a]++; while (at > 0 && neighbors[a][at - 1] > b) { neighbors[a][at] = neighbors[a][at - 1]; --at; } neighbors[a][at] = b;
        at = degree[b]++; while (at > 0 && neighbors[b][at - 1] > a) { neighbors[b][at] = neighbors[b][at - 1]; --at; } neighbors[b][at] = a;
    }
    const std::size_t starts_at = suffix + 3, draws_at = starts_at + static_cast<std::size_t>(starts_count);
    for (int t = 0; t < starts_count; ++t) if (v[starts_at + static_cast<std::size_t>(t)] < 0 || v[starts_at + static_cast<std::size_t>(t)] >= n) return -1;
    const std::size_t draw_count = static_cast<std::size_t>(starts_count * walks * steps);
    for (std::size_t i = 0; i < draw_count; ++i) if (v[draws_at + i] < 0 || v[draws_at + i] >= 2 * d) return -1;
    int accepted = 1; std::size_t draw = 0;
    for (int t = 0; t < starts_count && accepted; ++t) {
        bool seen[N][2]{}; const int start = static_cast<int>(v[starts_at + static_cast<std::size_t>(t)]); seen[start][0] = true;
        for (int walk = 0; walk < walks && accepted; ++walk) {
            int vertex = start, parity = 0;
            for (int step = 0; step < steps; ++step) {
                const int choice = static_cast<int>(v[draws_at + draw++]);
                if (choice < degree[vertex]) { vertex = neighbors[vertex][choice]; parity ^= 1; }
                seen[vertex][parity] = true;
                if (seen[vertex][1 - parity]) { accepted = 0; break; }
            }
        }
    }
    if (!out || capacity < 8) return -2;
    std::uint8_t staged[8]{}; put(staged, accepted);
    for (int i = 0; i < 8; ++i) out[i] = staged[i];
    return 8;
}
