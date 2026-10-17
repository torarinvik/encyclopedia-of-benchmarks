#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 4096;
constexpr std::size_t max_input_length = 2 + 3 * max_edges;

struct Edge {
    std::int64_t u;
    std::int64_t v;
    std::int64_t weight;
    std::size_t input_order;
};

std::size_t find_root(std::array<std::size_t, max_vertices>& parent, std::size_t node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t minimum_spanning_tree_kruskal(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto raw_vertices = input[0];
    const auto raw_edges = input[1];
    if (raw_vertices < 0 || raw_vertices > static_cast<std::int64_t>(max_vertices) ||
        raw_edges < 0 || raw_edges > static_cast<std::int64_t>(max_edges)) return -1;
    const auto vertex_count = static_cast<std::size_t>(raw_vertices);
    const auto edge_count = static_cast<std::size_t>(raw_edges);
    if (length != 2 + 3 * edge_count) return -1;

    std::array<Edge, max_edges> edges{};
    for (std::size_t index = 0; index < edge_count; ++index) {
        const auto offset = 2 + 3 * index;
        const auto u = input[offset];
        const auto v = input[offset + 1];
        if (u < 0 || u >= raw_vertices || v < 0 || v >= raw_vertices) return -1;
        edges[index] = {u, v, input[offset + 2], index};
    }
    std::sort(edges.begin(), edges.begin() + static_cast<std::ptrdiff_t>(edge_count),
              [](const Edge& left, const Edge& right) {
                  if (left.weight != right.weight) return left.weight < right.weight;
                  return left.input_order < right.input_order;
              });

    std::array<std::size_t, max_vertices> parent{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    std::array<Edge, max_vertices> accepted{};
    std::size_t accepted_count = 0;
    for (std::size_t index = 0; index < edge_count; ++index) {
        const auto left_root = find_root(parent, static_cast<std::size_t>(edges[index].u));
        const auto right_root = find_root(parent, static_cast<std::size_t>(edges[index].v));
        if (left_root != right_root) {
            accepted[accepted_count++] = edges[index];
            parent[left_root] = right_root;
        }
    }

    const auto byte_count = accepted_count * 24;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t index = 0; index < accepted_count; ++index) {
        const auto offset = index * 24;
        put_i64_le(output, offset, accepted[index].u);
        put_i64_le(output, offset + 8, accepted[index].v);
        put_i64_le(output, offset + 16, accepted[index].weight);
    }
    return static_cast<std::int64_t>(byte_count);
}
