#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 128
#define MAX_INPUT_LENGTH (1 + 2 * MAX_EDGES)
#define MAX_OUTPUT_BYTES (4 * MAX_VERTICES)

static int find_vertex(const int32_t *labels, size_t vertex_count, int32_t label) {
    for (size_t i = 0; i < vertex_count; ++i)
        if (labels[i] == label) return (int)i;
    return -1;
}

int64_t kahns_algorithm(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > MAX_EDGES) return -1;
    const size_t edge_count = (size_t)edge_count_value;
    if (length != 1 + 2 * edge_count) return -1;

    int32_t labels[MAX_VERTICES] = {0};
    int first_edge[MAX_VERTICES], tail_edge[MAX_VERTICES], next_edge[MAX_EDGES];
    size_t to[MAX_EDGES] = {0};
    size_t indegree[MAX_VERTICES] = {0};
    size_t vertex_count = 0;
    for (size_t vertex = 0; vertex < MAX_VERTICES; ++vertex)
        first_edge[vertex] = tail_edge[vertex] = -1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t from_value = input[1 + 2 * edge];
        const int64_t to_value = input[2 + 2 * edge];
        if (from_value < INT32_MIN || from_value > INT32_MAX ||
            to_value < INT32_MIN || to_value > INT32_MAX) return -1;
        const int32_t from_label = (int32_t)from_value;
        const int32_t to_label = (int32_t)to_value;
        int from_index = find_vertex(labels, vertex_count, from_label);
        if (from_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            from_index = (int)vertex_count;
            labels[vertex_count++] = from_label;
        }
        int to_index = find_vertex(labels, vertex_count, to_label);
        if (to_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            to_index = (int)vertex_count;
            labels[vertex_count++] = to_label;
        }
        to[edge] = (size_t)to_index;
        next_edge[edge] = -1;
        if (first_edge[(size_t)from_index] < 0) first_edge[(size_t)from_index] = (int)edge;
        else next_edge[(size_t)tail_edge[(size_t)from_index]] = (int)edge;
        tail_edge[(size_t)from_index] = (int)edge;
        ++indegree[(size_t)to_index];
    }

    size_t queue[MAX_VERTICES], order[MAX_VERTICES];
    size_t queue_head = 0, queue_tail = 0, order_count = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (indegree[vertex] == 0) queue[queue_tail++] = vertex;
    if (vertex_count > 0 && queue_tail != 1) return -1;
    while (queue_head < queue_tail) {
        if (queue_tail - queue_head != 1) return -1;
        const size_t current = queue[queue_head++];
        order[order_count++] = current;
        for (int outgoing = first_edge[current]; outgoing >= 0; outgoing = next_edge[(size_t)outgoing]) {
            const size_t adjacent = to[(size_t)outgoing];
            if (indegree[adjacent] == 0) return -1;
            --indegree[adjacent];
            if (indegree[adjacent] == 0) queue[queue_tail++] = adjacent;
        }
    }
    if (order_count != vertex_count) return -1;

    const size_t output_bytes = 4 * order_count;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < order_count; ++i) {
        uint32_t bits = (uint32_t)labels[order[i]];
        for (size_t byte = 0; byte < 4; ++byte) {
            output[4 * i + byte] = (uint8_t)(bits & UINT32_C(255));
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
