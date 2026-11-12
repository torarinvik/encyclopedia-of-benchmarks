#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 8, MAX_EDGES = 16, MAX_INPUT = 34;
using Adjacency = std::array<std::uint32_t, MAX_VERTICES>;
using Polynomial = std::array<std::int64_t, MAX_VERTICES + 1>;

Polynomial chromatic_poly(const Adjacency& adjacency, std::size_t n) {
    std::size_t edge_u = n, edge_v = n;
    for (std::size_t u = 0; u < n && edge_u == n; ++u) {
        for (std::size_t v = u + 1; v < n; ++v) {
            if (adjacency[u] & (std::uint32_t{1} << v)) { edge_u = u; edge_v = v; break; }
        }
    }
    Polynomial result{};
    if (edge_u == n) { result[n] = 1; return result; }

    Adjacency deleted = adjacency;
    deleted[edge_u] &= ~(std::uint32_t{1} << edge_v);
    deleted[edge_v] &= ~(std::uint32_t{1} << edge_u);
    const Polynomial without_edge = chromatic_poly(deleted, n);

    Adjacency contracted{};
    const auto remap = [edge_u, edge_v](std::size_t vertex) {
        if (vertex == edge_v) vertex = edge_u;
        if (vertex > edge_v) --vertex;
        return vertex;
    };
    for (std::size_t left = 0; left < n; ++left) {
        for (std::size_t right = left + 1; right < n; ++right) {
            if (!(adjacency[left] & (std::uint32_t{1} << right)) ||
                (left == edge_u && right == edge_v)) continue;
            const auto new_left = remap(left);
            const auto new_right = remap(right);
            if (new_left == new_right) continue;
            contracted[new_left] |= std::uint32_t{1} << new_right;
            contracted[new_right] |= std::uint32_t{1} << new_left;
        }
    }
    const Polynomial with_edge_contracted = chromatic_poly(contracted, n - 1);
    for (std::size_t degree = 0; degree <= n; ++degree)
        result[degree] = without_edge[degree] - with_edge_contracted[degree];
    return result;
}

void put64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t chromatic_polynomial(const std::int64_t* input, std::size_t length,
        std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(MAX_VERTICES) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(MAX_EDGES) ||
        length != 2 + 2 * static_cast<std::size_t>(m_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    Adjacency adjacency{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        const auto u = static_cast<std::size_t>(u_value), v = static_cast<std::size_t>(v_value);
        if (adjacency[u] & (std::uint32_t{1} << v)) return -1;
        adjacency[u] |= std::uint32_t{1} << v;
        adjacency[v] |= std::uint32_t{1} << u;
    }
    const auto bytes = 8 * (n + 1);
    if (!output || capacity < bytes) return -2;
    const auto coefficients = chromatic_poly(adjacency, n);
    for (std::size_t degree = 0; degree <= n; ++degree) put64(output, 8 * degree, coefficients[degree]);
    return static_cast<std::int64_t>(bytes);
}
