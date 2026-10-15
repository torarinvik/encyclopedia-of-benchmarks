#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr size_t kMaxVertices = 256;
constexpr size_t kMaxEdges = 512;
void visit(size_t vertex, size_t n, const std::array<uint8_t, kMaxVertices * kMaxVertices>& adjacency,
           std::array<uint8_t, kMaxVertices>& seen) {
    seen[vertex] = 1;
    for (size_t next = 0; next < n; ++next)
        if (adjacency[vertex * kMaxVertices + next] && !seen[next]) visit(next, n, adjacency, seen);
}
}

extern "C" int64_t connected_components(const int64_t *input, size_t length) {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 256 || input[1] < 0 || input[1] > 512) return -1;
    const size_t n = static_cast<size_t>(input[0]), m = static_cast<size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::array<uint8_t, kMaxVertices * kMaxVertices> adjacency{};
    for (size_t i = 0; i < m; ++i) {
        const int64_t u = input[2 + 2 * i], v = input[3 + 2 * i];
        if (u < 1 || u > static_cast<int64_t>(n) || v < 1 || v > static_cast<int64_t>(n)) return -1;
        const size_t a = static_cast<size_t>(u - 1), b = static_cast<size_t>(v - 1);
        adjacency[a * kMaxVertices + b] = adjacency[b * kMaxVertices + a] = 1;
    }
    std::array<uint8_t, kMaxVertices> seen{};
    int64_t components = 0;
    for (size_t i = 0; i < n; ++i) if (!seen[i]) { visit(i, n, adjacency, seen); ++components; }
    return components;
}
