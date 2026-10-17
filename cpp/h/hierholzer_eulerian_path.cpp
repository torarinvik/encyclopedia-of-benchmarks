#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 16;
constexpr std::size_t MAX_EDGES = 48;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
constexpr std::size_t MAX_ROUTE = MAX_EDGES + 1;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t hierholzer_eulerian_path(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t vertex_count_value = input[0];
    const std::int64_t edge_count_value = input[1];
    if (vertex_count_value < 0 || vertex_count_value > static_cast<std::int64_t>(MAX_VERTICES) ||
        edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(MAX_EDGES)) return -1;
    const std::size_t vertex_count = static_cast<std::size_t>(vertex_count_value);
    const std::size_t edge_count = static_cast<std::size_t>(edge_count_value);
    if (length != 2 + 2 * edge_count) return -1;

    int adjacency[MAX_VERTICES][MAX_EDGES]{};
    std::size_t in_degree[MAX_VERTICES]{}, out_degree[MAX_VERTICES]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t source_value = input[2 + 2 * edge];
        const std::int64_t destination_value = input[3 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            destination_value < 0 || destination_value >= vertex_count_value) return -1;
        const std::size_t source = static_cast<std::size_t>(source_value);
        const std::size_t destination = static_cast<std::size_t>(destination_value);
        adjacency[source][out_degree[source]++] = static_cast<int>(destination);
        ++in_degree[destination];
    }

    int path[MAX_ROUTE];
    std::size_t path_length = 0;
    if (vertex_count == 0) {
        path_length = 0;
    } else if (edge_count == 0) {
        path[path_length++] = 0;
    } else {
        int start = -1;
        std::size_t start_count = 0, end_count = 0;
        bool degrees_valid = true;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const auto difference = static_cast<std::int64_t>(out_degree[vertex]) -
                                    static_cast<std::int64_t>(in_degree[vertex]);
            if (difference == 1) { start = static_cast<int>(vertex); ++start_count; }
            else if (difference == -1) ++end_count;
            else if (difference < -1 || difference > 1) degrees_valid = false;
        }
        if (!((start_count == 1 && end_count == 1) ||
              (start_count == 0 && end_count == 0))) degrees_valid = false;
        if (degrees_valid && start < 0) {
            for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
                if (out_degree[vertex] > 0) { start = static_cast<int>(vertex); break; }
            }
        }

        bool connected = degrees_valid;
        if (connected) {
            bool visited[MAX_VERTICES]{};
            int pending[MAX_VERTICES];
            std::size_t pending_size = 1;
            pending[0] = start;
            visited[static_cast<std::size_t>(start)] = true;
            while (pending_size > 0) {
                const int current = pending[--pending_size];
                for (std::size_t edge = 0; edge < out_degree[static_cast<std::size_t>(current)]; ++edge) {
                    const std::size_t next = static_cast<std::size_t>(adjacency[static_cast<std::size_t>(current)][edge]);
                    if (!visited[next]) { visited[next] = true; pending[pending_size++] = static_cast<int>(next); }
                }
                for (std::size_t source = 0; source < vertex_count; ++source) {
                    if (visited[source]) continue;
                    for (std::size_t edge = 0; edge < out_degree[source]; ++edge) {
                        if (adjacency[source][edge] == current) {
                            visited[source] = true;
                            pending[pending_size++] = static_cast<int>(source);
                            break;
                        }
                    }
                }
            }
            for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
                if (in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex]) connected = false;
        }

        if (connected) {
            std::size_t next_position[MAX_VERTICES]{};
            int stack[MAX_ROUTE], reverse_path[MAX_ROUTE];
            std::size_t stack_size = 1, reverse_length = 0;
            stack[0] = start;
            while (stack_size > 0) {
                const int current = stack[stack_size - 1];
                if (next_position[static_cast<std::size_t>(current)] < out_degree[static_cast<std::size_t>(current)]) {
                    const int next = adjacency[static_cast<std::size_t>(current)][next_position[static_cast<std::size_t>(current)]++];
                    stack[stack_size++] = next;
                } else {
                    reverse_path[reverse_length++] = stack[--stack_size];
                }
            }
            if (reverse_length == edge_count + 1) {
                path_length = reverse_length;
                for (std::size_t i = 0; i < path_length; ++i)
                    path[i] = reverse_path[path_length - 1 - i];
                // The chosen start is already the first nonempty vertex row.
            }
        }
    }

    const std::size_t output_bytes = 8 * (path_length + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    write_i64_le(output, 0, static_cast<std::int64_t>(path_length));
    for (std::size_t index = 0; index < path_length; ++index)
        write_i64_le(output, 8 * (index + 1), path[index]);
    return static_cast<std::int64_t>(output_bytes);
}
