/* Traverse a connected undirected graph from vertex zero in sorted-neighbor BFS order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 40
#define MAX_EDGES 780

static void put_i64(uint8_t *output, size_t slot, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[slot * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bfs_connected_undirected_visit_order(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES || input[2] != 0) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 3 + 2 * edge_count) return -1;

    uint64_t adjacency[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_value = input[3 + 2 * edge];
        const int64_t right_value = input[4 + 2 * edge];
        if (left_value < 0 || right_value < 0 || (uint64_t)left_value >= vertices || (uint64_t)right_value >= vertices) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    uint8_t visited[MAX_VERTICES] = {0};
    size_t queue[MAX_VERTICES], order[MAX_VERTICES];
    size_t head = 0, tail = 0, count = 0;
    visited[0] = 1;
    queue[tail++] = 0;
    while (head < tail) {
        const size_t vertex = queue[head++];
        order[count++] = vertex;
        for (size_t neighbor = 0; neighbor < vertices; ++neighbor) {
            if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor]) {
                visited[neighbor] = 1;
                queue[tail++] = neighbor;
            }
        }
    }
    if (count != vertices) return -1;
    if (output == NULL || capacity < vertices * 8) return -2;
    for (size_t index = 0; index < count; ++index) put_i64(output, index, (int64_t)order[index]);
    return (int64_t)count;
}
