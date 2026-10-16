#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 14

int64_t greedy_graph_coloring(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_VERTICES + 1) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_VERTICES || length != (size_t)(count_value + 1)) return -1;
    const int count = (int)count_value;
    const int64_t limit = (INT64_C(1) << count) - 1;
    int64_t adjacency[MAX_VERTICES] = {0};
    int degree[MAX_VERTICES] = {0};
    int order[MAX_VERTICES] = {0};
    int colors[MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < count; ++vertex) {
        const int64_t mask = values[1 + (size_t)vertex];
        if (mask < 0 || mask > limit || (mask & (INT64_C(1) << vertex)) != 0) return -1;
        adjacency[vertex] = mask;
        int remaining = (int)mask;
        while (remaining != 0) { remaining &= remaining - 1; ++degree[vertex]; }
        order[vertex] = vertex;
    }
    for (int vertex = 0; vertex < count; ++vertex)
        for (int other = 0; other < count; ++other)
            if (((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1)) return -1;
    for (int index = 1; index < count; ++index) {
        const int current = order[index];
        int position = index;
        while (position > 0 && degree[order[position - 1]] < degree[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    int color_count = 0;
    for (int position = 0; position < count; ++position) {
        const int vertex = order[position];
        int used[MAX_VERTICES + 1] = {0};
        for (int other = 0; other < count; ++other)
            if ((adjacency[vertex] & (INT64_C(1) << other)) != 0 && colors[other] != 0) used[colors[other]] = 1;
        int color = 1;
        while (used[color]) ++color;
        colors[vertex] = color;
        if (color > color_count) color_count = color;
    }
    int64_t packed = color_count;
    for (int vertex = 0; vertex < count; ++vertex)
        packed |= (int64_t)colors[vertex] << (4 * (vertex + 1));
    return packed;
}
