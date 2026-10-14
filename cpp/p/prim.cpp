#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 4096;
}

extern "C" std::int64_t prim(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 2 + 3 * max_edges) return -2;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_vertices) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_edges)) return -2;
    const std::size_t vertices = static_cast<std::size_t>(values[0]);
    const std::size_t edges = static_cast<std::size_t>(values[1]);
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;

    bool present[max_vertices * max_vertices] = {};
    std::int64_t weight[max_vertices * max_vertices] = {};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto u_value = values[2 + 3 * edge];
        const auto v_value = values[3 + 3 * edge];
        const auto cost = values[4 + 3 * edge];
        if (u_value < 0 || v_value < 0 || static_cast<std::uint64_t>(u_value) >= vertices ||
            static_cast<std::uint64_t>(v_value) >= vertices || cost < 0 || cost > INT64_C(2147483647)) return -2;
        const auto u = static_cast<std::size_t>(u_value), v = static_cast<std::size_t>(v_value);
        if (u == v) continue;
        const auto uv = u * max_vertices + v, vu = v * max_vertices + u;
        if (!present[uv] || cost < weight[uv]) {
            present[uv] = present[vu] = true;
            weight[uv] = weight[vu] = cost;
        }
    }

    bool in_tree[max_vertices] = {};
    bool has_best[max_vertices] = {};
    std::int64_t best[max_vertices] = {};
    has_best[0] = true;
    std::int64_t total = 0;
    for (std::size_t step = 0; step < vertices; ++step) {
        std::size_t selected = vertices;
        for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
            if (!in_tree[vertex] && has_best[vertex] &&
                (selected == vertices || best[vertex] < best[selected])) selected = vertex;
        }
        if (selected == vertices) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
            const auto slot = selected * max_vertices + vertex;
            if (!in_tree[vertex] && present[slot] && (!has_best[vertex] || weight[slot] < best[vertex])) {
                has_best[vertex] = true;
                best[vertex] = weight[slot];
            }
        }
    }
    return total;
}
