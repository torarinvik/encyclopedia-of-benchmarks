// Clean-room DAG-to-bipartite-matching minimum path-cover profile.
#include <array>
#include <cstddef>
#include <cstdint>
#include <queue>

namespace {
constexpr int kN = 10;
using Adj = std::array<std::uint16_t, kN>;

bool augment(const Adj& adj, int n, int left, std::uint16_t used,
             std::array<bool, kN>& seen, std::array<int, kN>& pair_right) {
    for (int right = 0; right < n; ++right) {
        const auto bit = static_cast<std::uint16_t>(1u << right);
        if (!(adj[left] & bit) || (used & bit) || seen[right]) continue;
        seen[right] = true;
        const int mate = pair_right[right];
        if (mate < 0 || augment(adj, n, mate, used, seen, pair_right)) {
            pair_right[right] = left;
            return true;
        }
    }
    return false;
}

int maximum_matching(const Adj& adj, int n, int first, std::uint16_t used) {
    std::array<int, kN> pair_right{};
    pair_right.fill(-1);
    int size = 0;
    for (int left = first; left < n; ++left) {
        std::array<bool, kN> seen{};
        if (augment(adj, n, left, used, seen, pair_right)) ++size;
    }
    return size;
}
} // namespace

extern "C" std::int64_t dag_minimum_path_cover(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > 93) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 10 || m64 < 0 || m64 > 45 || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    Adj adj{};
    std::array<int, kN> indegree{};
    for (int i = 0; i < m; ++i) {
        const auto u64 = input[2 + 2 * i], v64 = input[3 + 2 * i];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        const auto bit = static_cast<std::uint16_t>(1u << v);
        if (adj[u] & bit) return -1;
        adj[u] |= bit; ++indegree[v];
    }
    std::queue<int> queue;
    for (int v = 0; v < n; ++v) if (indegree[v] == 0) queue.push(v);
    int removed = 0;
    while (!queue.empty()) {
        const int u = queue.front(); queue.pop(); ++removed;
        for (int v = 0; v < n; ++v) if (adj[u] & (1u << v))
            if (--indegree[v] == 0) queue.push(v);
    }
    if (removed != n) return -1;
    const int maximum = maximum_matching(adj, n, 0, 0);
    std::array<int, kN> successor{};
    std::uint16_t used = 0;
    int fixed = 0;
    for (int left = 0; left < n; ++left) {
        bool chosen = false;
        for (int right = 0; right <= n; ++right) {
            const bool matched = right < n;
            if (matched && (!(adj[left] & (1u << right)) || (used & (1u << right)))) continue;
            const auto next_used = matched ? static_cast<std::uint16_t>(used | (1u << right)) : used;
            if (fixed + static_cast<int>(matched) + maximum_matching(adj, n, left + 1, next_used) == maximum) {
                successor[left] = right; used = next_used; fixed += static_cast<int>(matched);
                chosen = true; break;
            }
        }
        if (!chosen) return -1;
    }
    std::uint64_t result = static_cast<std::uint64_t>(n - maximum) << 40;
    for (int v = 0; v < n; ++v) result |= static_cast<std::uint64_t>(successor[v]) << (4 * v);
    return static_cast<std::int64_t>(result);
}
