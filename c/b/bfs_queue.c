#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 64
#define MAX_EDGE_COUNT 2046
#define MAX_INPUT_LENGTH (4 + 2 * MAX_EDGE_COUNT)

int64_t bfs_queue(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH ||
        input[0] < 1 || input[0] > MAX_VERTEX_COUNT || input[3] < 0 || input[3] > MAX_EDGE_COUNT)
        return -1;
    const size_t vertex_count = (size_t)input[0];
    const int64_t source_arg = input[1], target_arg = input[2];
    const size_t edge_count = (size_t)input[3];
    if (source_arg < 0 || source_arg >= (int64_t)vertex_count ||
        target_arg < 0 || target_arg >= (int64_t)vertex_count ||
        length != 4 + 2 * edge_count)
        return -1;

    uint64_t adjacency[MAX_VERTEX_COUNT] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_arg = input[4 + 2 * edge], right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (int64_t)vertex_count ||
            right_arg >= (int64_t)vertex_count) return -1;
        const size_t left = (size_t)left_arg, right = (size_t)right_arg;
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    const size_t source = (size_t)source_arg, target = (size_t)target_arg;
    int64_t predecessor[MAX_VERTEX_COUNT];
    bool visited[MAX_VERTEX_COUNT] = {false};
    size_t queue[MAX_VERTEX_COUNT], head = 0, tail = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) predecessor[vertex] = -1;
    predecessor[source] = (int64_t)source;
    visited[source] = true;
    queue[tail++] = source;
    bool found = source == target;
    while (head < tail && !found) {
        const size_t current = queue[head++];
        for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
            if ((adjacency[current] & (UINT64_C(1) << neighbor)) == 0 || visited[neighbor]) continue;
            visited[neighbor] = true;
            predecessor[neighbor] = (int64_t)current;
            if (neighbor == target) { found = true; break; }
            queue[tail++] = neighbor;
        }
    }
    if (!found) {
        if (output_capacity < 1 || output == NULL) return -2;
        output[0] = 0;
        return 1;
    }

    uint8_t path[MAX_VERTEX_COUNT];
    size_t path_length = 0, current = target;
    while (current != source) {
        path[path_length++] = (uint8_t)current;
        current = (size_t)predecessor[current];
    }
    path[path_length++] = (uint8_t)source;
    if (output_capacity < path_length + 1 || output == NULL) return -2;
    output[0] = 1;
    for (size_t index = 0; index < path_length; ++index) output[index + 1] = path[index];
    return (int64_t)(path_length + 1);
}
