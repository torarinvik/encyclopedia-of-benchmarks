#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_edge_count = 64;
constexpr std::int64_t max_vertex_id = 63;
constexpr std::size_t max_node_count = 128;
constexpr std::size_t max_input_length = 1 + 2 * max_edge_count;

std::size_t find_last_node(std::int64_t label,
                           const std::array<std::int64_t, max_node_count> &labels,
                           std::size_t node_count) {
    std::size_t found = max_node_count;
    for (std::size_t node = 0; node < node_count; ++node)
        if (labels[node] == label) found = node;
    return found;
}

void visit(std::size_t current, std::size_t edge_count,
           const std::array<std::size_t, max_edge_count> &edge_starts,
           const std::array<std::size_t, max_edge_count> &edge_ends,
           std::array<bool, max_node_count> &visited) {
    visited[current] = true;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::size_t destination = edge_ends[edge];
        if (edge_starts[edge] == current && !visited[destination])
            visit(destination, edge_count, edge_starts, edge_ends, visited);
    }
}
}

extern "C" std::int64_t directed_dfs_forest_count(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length + 1) return -1;
    const auto edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(max_edge_count)) return -1;
    const auto edge_count = static_cast<std::size_t>(edge_count_value);
    if (length != 1 + 2 * edge_count) return -1;

    std::array<std::int64_t, max_node_count> labels{};
    std::array<std::size_t, max_edge_count> edge_starts{}, edge_ends{};
    std::size_t node_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto start_label = input[1 + 2 * edge];
        const auto end_label = input[2 + 2 * edge];
        if (start_label < 0 || start_label > max_vertex_id || end_label < 0 || end_label > max_vertex_id)
            return -1;

        auto start = find_last_node(start_label, labels, node_count);
        std::size_t end;
        if (start_label == end_label) {
            if (start == max_node_count) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            end = node_count;
            labels[node_count++] = end_label;
        } else {
            end = find_last_node(end_label, labels, node_count);
            if (start == max_node_count) {
                start = node_count;
                labels[node_count++] = start_label;
            }
            if (end == max_node_count) {
                end = node_count;
                labels[node_count++] = end_label;
            }
        }
        edge_starts[edge] = start;
        edge_ends[edge] = end;
    }

    std::array<bool, max_node_count> marked{};
    std::int64_t roots = 0;
    for (std::size_t root = 0; root < node_count; ++root) {
        if (marked[root]) continue;
        std::array<bool, max_node_count> visited{};
        visit(root, edge_count, edge_starts, edge_ends, visited);
        for (std::size_t node = 0; node < node_count; ++node)
            if (visited[node]) marked[node] = true;
        ++roots;
    }
    return roots;
}
