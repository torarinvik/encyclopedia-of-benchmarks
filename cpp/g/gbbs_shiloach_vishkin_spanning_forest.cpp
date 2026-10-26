// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t N = 12, M = 24, INPUT = 2 + 2 * M;

std::size_t find_root(std::array<std::size_t, N>& parent, std::size_t vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}
}

extern "C" std::int64_t gbbs_shiloach_vishkin_spanning_forest(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > INPUT) return -1;
    const auto n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(N) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(M) || length != 2 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    std::array<std::array<bool, N>, N> seen{};
    std::array<std::size_t, M> edge_u{}, edge_v{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (seen[u][v]) return -1;
        seen[u][v] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    if (output == nullptr || capacity < m) return -2;

    std::array<std::size_t, N> parent{}, previous{}, next_parent{}, best_lower{};
    std::array<std::uint8_t, M> selected{};
    for (std::size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = vertex;
    for (std::size_t round = 0; round < n; ++round) {
        for (std::size_t vertex = 0; vertex < n; ++vertex) {
            previous[vertex] = find_root(parent, vertex);
            next_parent[vertex] = previous[vertex];
            best_lower[vertex] = n;
        }
        for (std::size_t edge = 0; edge < m; ++edge) {
            const auto root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
            if (root_u == root_v) continue;
            const auto lower = (root_u < root_v) ? root_u : root_v;
            const auto higher = (root_u < root_v) ? root_v : root_u;
            if (previous[higher] == higher && lower < best_lower[higher]) best_lower[higher] = lower;
        }
        bool changed = false;
        for (std::size_t higher = 0; higher < n; ++higher) {
            const auto lower = best_lower[higher];
            if (lower == n) continue;
            next_parent[higher] = lower;
            changed = true;
            for (std::size_t edge = 0; edge < m; ++edge) {
                const auto root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
                if ((root_u == higher && root_v == lower) || (root_u == lower && root_v == higher)) {
                    selected[edge] = 1;
                    break;
                }
            }
        }
        for (std::size_t vertex = 0; vertex < n; ++vertex)
            parent[vertex] = find_root(next_parent, vertex);
        if (!changed) break;
    }
    for (std::size_t edge = 0; edge < m; ++edge) output[edge] = selected[edge];
    return static_cast<std::int64_t>(m);
}
