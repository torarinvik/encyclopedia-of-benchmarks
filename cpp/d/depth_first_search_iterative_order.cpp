#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 10;
constexpr int max_edges = 64;
constexpr int max_degree = 2 * max_edges;
void put_i64(std::uint8_t *output, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t depth_first_search_iterative_order(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3) return -1;
    const auto n_value = input[0], edge_value = input[1];
    if (n_value < 1 || n_value > max_vertices || edge_value < 0 || edge_value > max_edges ||
        length != 3 + 2 * static_cast<std::size_t>(edge_value)) return -1;
    const int n = static_cast<int>(n_value);
    int adjacency[max_vertices + 1][max_degree]{};
    int degree[max_vertices + 1]{};
    for (int edge = 0; edge < edge_value; ++edge) {
        const auto left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 1 || left_value > n || right_value < 1 || right_value > n) return -1;
        const int left = static_cast<int>(left_value), right = static_cast<int>(right_value);
        adjacency[left][degree[left]++] = right;
        adjacency[right][degree[right]++] = left;
    }
    const auto start_value = input[length - 1];
    if (start_value < 1 || start_value > n) return -1;
    const int start = static_cast<int>(start_value);
    int stack[max_vertices]{}, order[max_vertices]{}, order_count = 0, stack_size = 0;
    bool visited[max_vertices + 1]{};
    visited[start] = true;
    stack[stack_size++] = start;
    while (stack_size > 0) {
        const int vertex = stack[--stack_size];
        order[order_count++] = vertex;
        for (int edge = 0; edge < degree[vertex]; ++edge) {
            const int neighbor = adjacency[vertex][edge];
            if (!visited[neighbor]) {
                visited[neighbor] = true;
                stack[stack_size++] = neighbor;
            }
        }
    }
    const auto words = static_cast<std::size_t>(order_count) + 1;
    if (output == nullptr || capacity < words * 8) return -2;
    put_i64(output, 0, order_count);
    for (int index = 0; index < order_count; ++index) put_i64(output, static_cast<std::size_t>(index) + 1, order[index]);
    return static_cast<std::int64_t>(words * 8);
}
