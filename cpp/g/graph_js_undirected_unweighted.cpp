#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 26, max_edges = 256;
constexpr std::size_t max_degree = 2 * max_edges, max_input_length = 541;
constexpr std::size_t max_output_values = 645, max_queue = 1 + 2 * max_edges;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}

void dfs_visit(std::size_t vertex, const std::uint8_t adjacency[max_vertices][max_degree],
               const std::size_t degree[max_vertices], bool visited[max_vertices],
               std::int64_t result[max_output_values], std::size_t &position, std::size_t &count) {
    if (visited[vertex]) return;
    visited[vertex] = true;
    result[position++] = static_cast<std::int64_t>(97 + vertex);
    ++count;
    for (std::size_t edge = 0; edge < degree[vertex]; ++edge)
        dfs_visit(adjacency[vertex][edge], adjacency, degree, visited, result, position, count);
}
}

extern "C" std::int64_t graph_js_undirected_unweighted(const std::int64_t *input, std::size_t length,
                                                        std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    if (length < 1 + vertex_count + 2) return -1;
    std::uint8_t vertices[max_vertices];
    bool declared[max_vertices] = {};
    for (std::size_t index = 0; index < vertex_count; ++index) {
        const auto value = input[1 + index];
        if (value < 'a' || value > 'z') return -1;
        const auto vertex = static_cast<std::size_t>(value - 'a');
        if (declared[vertex]) return -1;
        declared[vertex] = true;
        vertices[index] = static_cast<std::uint8_t>(vertex);
    }
    const auto edge_count_offset = 1 + vertex_count;
    const auto raw_edge_count = input[edge_count_offset];
    if (raw_edge_count < 0 || raw_edge_count > static_cast<std::int64_t>(max_edges)) return -1;
    const auto edge_count = static_cast<std::size_t>(raw_edge_count);
    if (length != 1 + vertex_count + 1 + 2 * edge_count + 1) return -1;

    std::uint8_t adjacency[max_vertices][max_degree] = {};
    std::size_t degree[max_vertices] = {};
    auto position = edge_count_offset + 1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_value = input[position++], right_value = input[position++];
        if (left_value < 'a' || left_value > 'z' || right_value < 'a' || right_value > 'z') return -1;
        const auto left = static_cast<std::size_t>(left_value - 'a');
        const auto right = static_cast<std::size_t>(right_value - 'a');
        if (declared[left] && declared[right]) {
            if (degree[left] >= max_degree || degree[right] >= max_degree) return -1;
            adjacency[left][degree[left]++] = static_cast<std::uint8_t>(right);
            adjacency[right][degree[right]++] = static_cast<std::uint8_t>(left);
        }
    }
    const auto start_value = input[position];
    if (start_value < 'a' || start_value > 'z') return -1;
    const auto start = static_cast<std::size_t>(start_value - 'a');
    if (!declared[start]) return -1;

    std::int64_t result[max_output_values];
    std::size_t result_length = 0;
    result[result_length++] = static_cast<std::int64_t>(vertex_count);
    for (std::size_t index = 0; index < vertex_count; ++index) {
        const auto vertex = static_cast<std::size_t>(vertices[index]);
        result[result_length++] = static_cast<std::int64_t>(97 + vertex);
        result[result_length++] = static_cast<std::int64_t>(degree[vertex]);
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge)
            result[result_length++] = static_cast<std::int64_t>(97 + adjacency[vertex][edge]);
    }

    bool visited[max_vertices] = {};
    std::uint8_t queue[max_queue], levels[max_queue];
    std::size_t head = 0, tail = 0, bfs_count = 0;
    const auto bfs_count_slot = result_length++;
    queue[tail] = static_cast<std::uint8_t>(start); levels[tail++] = 0;
    while (head < tail) {
        const auto vertex = static_cast<std::size_t>(queue[head]);
        const auto level = static_cast<std::size_t>(levels[head++]);
        if (visited[vertex]) continue;
        visited[vertex] = true;
        result[result_length++] = static_cast<std::int64_t>(97 + vertex);
        result[result_length++] = static_cast<std::int64_t>(level);
        ++bfs_count;
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge) {
            queue[tail] = adjacency[vertex][edge]; levels[tail++] = static_cast<std::uint8_t>(level + 1);
        }
    }
    result[bfs_count_slot] = static_cast<std::int64_t>(bfs_count);
    for (std::size_t index = 0; index < max_vertices; ++index) visited[index] = false;
    const auto dfs_count_slot = result_length++;
    std::size_t dfs_count = 0;
    dfs_visit(start, adjacency, degree, visited, result, result_length, dfs_count);
    result[dfs_count_slot] = static_cast<std::int64_t>(dfs_count);

    const auto output_bytes = result_length * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < result_length; ++index) store_i64_le(output, index * 8, result[index]);
    return static_cast<std::int64_t>(output_bytes);
}
