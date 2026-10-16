/* Recursive reachability search in a bounded undirected graph. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH 518

static int reachable(const int64_t *adjacency, const size_t *degree, size_t current,
                     int64_t target, uint8_t *visited)
{
    if ((int64_t)current == target) return 1;
    visited[current] = 1;
    for (size_t position = 0; position < degree[current]; ++position) {
        const size_t neighbor = (size_t)adjacency[current * MAX_VERTICES + position];
        if (!visited[neighbor] && reachable(adjacency, degree, neighbor, target, visited)) return 1;
    }
    return 0;
}

int64_t depth_first_search_recursive(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_count = input[0];
    const int64_t edge_count_value = input[1];
    const int64_t source = input[2];
    const int64_t target = input[3];
    if (vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count_value < 0
        || edge_count_value > MAX_EDGES || source < 0 || source >= vertex_count) return -1;
    const size_t edge_count = (size_t)edge_count_value;
    if (length != 4 + 2 * edge_count) return -1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = input[4 + 2 * edge];
        const int64_t right = input[5 + 2 * edge];
        if (left < 0 || left >= vertex_count || right < 0 || right >= vertex_count) return -1;
    }

    int64_t adjacency[MAX_VERTICES * MAX_VERTICES];
    size_t degree[MAX_VERTICES] = {0};
    uint64_t seen[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t left = (size_t)input[4 + 2 * edge];
        const size_t right = (size_t)input[5 + 2 * edge];
        const uint64_t right_bit = UINT64_C(1) << right;
        if ((seen[left] & right_bit) == 0) {
            seen[left] |= right_bit;
            adjacency[left * MAX_VERTICES + degree[left]++] = (int64_t)right;
        }
        const uint64_t left_bit = UINT64_C(1) << left;
        if ((seen[right] & left_bit) == 0) {
            seen[right] |= left_bit;
            adjacency[right * MAX_VERTICES + degree[right]++] = (int64_t)left;
        }
    }
    uint8_t visited[MAX_VERTICES] = {0};
    return reachable(adjacency, degree, (size_t)source, target, visited) ? 1 : 0;
}
