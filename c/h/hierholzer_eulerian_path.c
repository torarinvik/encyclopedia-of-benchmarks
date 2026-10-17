#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 48
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES)
#define MAX_ROUTE (MAX_EDGES + 1)
#define MAX_OUTPUT_BYTES (8 * (MAX_EDGES + 2))

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t hierholzer_eulerian_path(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_count_value = input[0];
    const int64_t edge_count_value = input[1];
    if (vertex_count_value < 0 || vertex_count_value > MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES) return -1;
    const size_t vertex_count = (size_t)vertex_count_value;
    const size_t edge_count = (size_t)edge_count_value;
    if (length != 2 + 2 * edge_count) return -1;

    int adjacency[MAX_VERTICES][MAX_EDGES] = {{0}};
    size_t in_degree[MAX_VERTICES] = {0}, out_degree[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source_value = input[2 + 2 * edge];
        const int64_t destination_value = input[3 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            destination_value < 0 || destination_value >= vertex_count_value) return -1;
        const size_t source = (size_t)source_value;
        const size_t destination = (size_t)destination_value;
        adjacency[source][out_degree[source]++] = (int)destination;
        ++in_degree[destination];
    }

    int path[MAX_ROUTE];
    size_t path_length = 0;
    if (vertex_count == 0) {
        path_length = 0;
    } else if (edge_count == 0) {
        path[path_length++] = 0;
    } else {
        int start = -1;
        size_t start_count = 0, end_count = 0;
        int degrees_valid = 1;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            const int64_t difference = (int64_t)out_degree[vertex] - (int64_t)in_degree[vertex];
            if (difference == 1) { start = (int)vertex; ++start_count; }
            else if (difference == -1) ++end_count;
            else if (difference < -1 || difference > 1) degrees_valid = 0;
        }
        if (!((start_count == 1 && end_count == 1) ||
              (start_count == 0 && end_count == 0))) degrees_valid = 0;
        if (degrees_valid && start < 0) {
            for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
                if (out_degree[vertex] > 0) { start = (int)vertex; break; }
            }
        }

        int connected = degrees_valid;
        if (connected) {
            uint8_t visited[MAX_VERTICES] = {0};
            int pending[MAX_VERTICES];
            size_t pending_size = 1;
            pending[0] = start;
            visited[(size_t)start] = 1;
            while (pending_size > 0) {
                const int current = pending[--pending_size];
                for (size_t edge = 0; edge < out_degree[(size_t)current]; ++edge) {
                    const size_t next = (size_t)adjacency[(size_t)current][edge];
                    if (!visited[next]) { visited[next] = 1; pending[pending_size++] = (int)next; }
                }
                for (size_t source = 0; source < vertex_count; ++source) {
                    if (visited[source]) continue;
                    for (size_t edge = 0; edge < out_degree[source]; ++edge) {
                        if (adjacency[source][edge] == current) {
                            visited[source] = 1;
                            pending[pending_size++] = (int)source;
                            break;
                        }
                    }
                }
            }
            for (size_t vertex = 0; vertex < vertex_count; ++vertex)
                if (in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex]) connected = 0;
        }

        if (connected) {
            size_t next_position[MAX_VERTICES] = {0};
            int stack[MAX_ROUTE], reverse_path[MAX_ROUTE];
            size_t stack_size = 1, reverse_length = 0;
            stack[0] = start;
            while (stack_size > 0) {
                const int current = stack[stack_size - 1];
                if (next_position[(size_t)current] < out_degree[(size_t)current]) {
                    const int next = adjacency[(size_t)current][next_position[(size_t)current]++];
                    stack[stack_size++] = next;
                } else {
                    reverse_path[reverse_length++] = stack[--stack_size];
                }
            }
            if (reverse_length == edge_count + 1) {
                path_length = reverse_length;
                for (size_t i = 0; i < path_length; ++i)
                    path[i] = reverse_path[path_length - 1 - i];
                /* For a circuit, start is already the first nonempty row. */
            }
        }
    }

    const size_t output_bytes = 8 * (path_length + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    write_i64_le(output, 0, (int64_t)path_length);
    for (size_t index = 0; index < path_length; ++index)
        write_i64_le(output, 8 * (index + 1), path[index]);
    return (int64_t)output_bytes;
}
