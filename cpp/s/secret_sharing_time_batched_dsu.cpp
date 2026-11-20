#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 16;
int find_root(std::array<int, kMaxN>& parent, int node) noexcept {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}
void join_sets(std::array<int, kMaxN>& parent, std::array<int, kMaxN>& size,
               int left, int right) noexcept {
    int a = find_root(parent, left), b = find_root(parent, right);
    if (a == b) return;
    if (size[a] < size[b]) { const int swap = a; a = b; b = swap; }
    parent[b] = a;
    size[a] += size[b];
}
}

extern "C" std::int64_t secret_sharing_time_batched_dsu(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 64) return -1;
    const auto n_value = input[0], first_value = input[1], m_value = input[2];
    if (n_value < 2 || n_value > 16 || first_value < 1 || first_value >= n_value
        || m_value < 0 || m_value > 20) return -1;
    const int n = static_cast<int>(n_value), first = static_cast<int>(first_value);
    const int m = static_cast<int>(m_value);
    if (length != static_cast<std::size_t>(3 + 3 * m)) return -1;
    std::array<int, kMaxN> parent{}, size{};
    for (int i = 0; i < n; ++i) { parent[i] = i; size[i] = 1; }
    for (int i = 0; i < m; ++i) {
        const auto u = input[3 + 3 * i], v = input[4 + 3 * i], time = input[5 + 3 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || time < 1 || time > 20) return -1;
    }
    join_sets(parent, size, 0, first);
    for (int time = 1; time <= 20; ++time) {
        std::array<bool, kMaxN> touched{};
        for (int i = 0; i < m; ++i) {
            const int u = static_cast<int>(input[3 + 3 * i]);
            const int v = static_cast<int>(input[4 + 3 * i]);
            if (input[5 + 3 * i] == time) {
                join_sets(parent, size, u, v);
                touched[u] = touched[v] = true;
            }
        }
        const int known_root = find_root(parent, 0);
        for (int node = 0; node < n; ++node) {
            if (touched[node] && find_root(parent, node) != known_root) {
                parent[node] = node;
                size[node] = 1;
            }
        }
    }
    const int known_root = find_root(parent, 0);
    std::int64_t result = 0;
    for (int node = 0; node < n; ++node)
        if (find_root(parent, node) == known_root) result |= std::int64_t{1} << node;
    return result;
}
