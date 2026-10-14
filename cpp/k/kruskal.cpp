#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64, max_edges = 4096;
void sift_down(std::int64_t *keys, std::size_t root, std::size_t end) noexcept {
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) ++child;
        if (keys[root] >= keys[child]) break;
        const auto temporary = keys[root]; keys[root] = keys[child]; keys[child] = temporary;
        root = child;
    }
}
std::size_t find_root(std::size_t *parent, std::size_t node) noexcept {
    while (parent[node] != node) { parent[node] = parent[parent[node]]; node = parent[node]; }
    return node;
}
}

extern "C" std::int64_t kruskal(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 2 + 3 * max_edges) return -2;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_vertices) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_edges)) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edges = static_cast<std::size_t>(values[1]);
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;
    std::int64_t keys[max_edges];
    for (std::size_t edge = 0; edge < edges; ++edge) {
        auto u = values[2 + 3 * edge], v = values[3 + 3 * edge];
        const auto weight = values[4 + 3 * edge];
        if (u < 0 || v < 0 || static_cast<std::uint64_t>(u) >= vertices ||
            static_cast<std::uint64_t>(v) >= vertices || weight < 0 || weight > INT64_C(2147483647)) return -2;
        if (u > v) { const auto temporary = u; u = v; v = temporary; }
        keys[edge] = weight * INT64_C(4096) + u * INT64_C(64) + v;
    }
    for (std::size_t start = edges / 2; start > 0;) { --start; sift_down(keys, start, edges); }
    for (std::size_t end = edges; end > 1;) {
        --end; const auto temporary = keys[0]; keys[0] = keys[end]; keys[end] = temporary; sift_down(keys, 0, end);
    }
    std::size_t parent[max_vertices], rank[max_vertices] = {};
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) parent[vertex] = vertex;
    std::size_t selected = 0;
    std::int64_t total = 0;
    for (std::size_t edge = 0; edge < edges && selected + 1 < vertices; ++edge) {
        const auto key = keys[edge];
        const auto u = static_cast<std::size_t>((key % INT64_C(4096)) / INT64_C(64));
        const auto v = static_cast<std::size_t>(key % INT64_C(64));
        auto root_u = find_root(parent, u), root_v = find_root(parent, v);
        if (root_u != root_v) {
            total += key / INT64_C(4096); ++selected;
            if (rank[root_u] < rank[root_v]) parent[root_u] = root_v;
            else if (rank[root_u] > rank[root_v]) parent[root_v] = root_u;
            else { parent[root_v] = root_u; ++rank[root_u]; }
        }
    }
    return selected + 1 == vertices ? total : -1;
}
