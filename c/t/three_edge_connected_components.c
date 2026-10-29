#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 32, MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES };

static void refine_for_removal(const int64_t *from, const int64_t *to,
                               size_t vertex_count, size_t edge_count,
                               int removed_first, int removed_second,
                               uint8_t same_component[MAX_VERTICES * MAX_VERTICES])
{
    int component[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) component[vertex] = -1;
    int next_component = 0;
    int queue[MAX_VERTICES];

    for (size_t start = 0; start < vertex_count; ++start) {
        if (component[start] >= 0) continue;
        int head = 0;
        int tail = 0;
        component[start] = next_component;
        queue[tail++] = (int)start;
        while (head < tail) {
            int vertex = queue[head++];
            for (size_t edge = 0; edge < edge_count; ++edge) {
                if ((int)edge == removed_first || (int)edge == removed_second) continue;
                int neighbor = -1;
                if (from[edge] == vertex) neighbor = (int)to[edge];
                else if (to[edge] == vertex) neighbor = (int)from[edge];
                if (neighbor >= 0 && component[neighbor] < 0) {
                    component[neighbor] = next_component;
                    queue[tail++] = neighbor;
                }
            }
        }
        ++next_component;
    }

    for (size_t first = 0; first < vertex_count; ++first) {
        for (size_t second = first + 1; second < vertex_count; ++second) {
            if (component[first] != component[second]) {
                same_component[first * MAX_VERTICES + second] = 0;
                same_component[second * MAX_VERTICES + first] = 0;
            }
        }
    }
}

int64_t three_edge_connected_components(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 || values[0] > MAX_VERTICES
        || values[1] < 0 || values[1] > MAX_EDGES) return -1;
    size_t vertex_count = (size_t)values[0];
    size_t edge_count = (size_t)values[1];
    if (length != 2 + 2 * edge_count) return -1;

    int64_t from[MAX_EDGES];
    int64_t to[MAX_EDGES];
    for (size_t edge = 0; edge < edge_count; ++edge) {
        from[edge] = values[2 + 2 * edge];
        to[edge] = values[3 + 2 * edge];
        if (from[edge] < 0 || from[edge] >= (int64_t)vertex_count
            || to[edge] < 0 || to[edge] >= (int64_t)vertex_count) return -1;
    }

    uint8_t same_component[MAX_VERTICES * MAX_VERTICES];
    for (size_t index = 0; index < MAX_VERTICES * MAX_VERTICES; ++index) same_component[index] = 1;
    refine_for_removal(from, to, vertex_count, edge_count, -1, -1, same_component);
    for (size_t first = 0; first < edge_count; ++first) {
        refine_for_removal(from, to, vertex_count, edge_count, (int)first, -1, same_component);
        for (size_t second = first + 1; second < edge_count; ++second)
            refine_for_removal(from, to, vertex_count, edge_count, (int)first, (int)second, same_component);
    }

    int labels[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) labels[vertex] = -1;
    int next_label = 0;
    for (size_t first = 0; first < vertex_count; ++first) {
        if (labels[first] >= 0) continue;
        for (size_t vertex = first; vertex < vertex_count; ++vertex) {
            if (labels[vertex] < 0 && same_component[first * MAX_VERTICES + vertex])
                labels[vertex] = next_label;
        }
        ++next_label;
    }

    int64_t encoded = 0;
    int64_t place = 1;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        encoded += labels[vertex] * place;
        place *= 8;
    }
    return encoded;
}
