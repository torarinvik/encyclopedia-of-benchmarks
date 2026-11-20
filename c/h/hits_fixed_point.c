#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 64
#define SCORE_SCALE INT64_C(1000000)

int64_t hits_fixed_point(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > 132) return -1;

    const int64_t vertex_count_value = input[0];
    const int64_t edge_count_value = input[1];
    const int64_t iteration_count_value = input[2];
    if (vertex_count_value < 1 || vertex_count_value > MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES ||
        iteration_count_value < 0 || iteration_count_value > 32) return -1;

    const size_t vertex_count = (size_t)vertex_count_value;
    const size_t edge_count = (size_t)edge_count_value;
    const size_t iteration_count = (size_t)iteration_count_value;
    if (length != 3 + 2 * edge_count) return -1;

    size_t sources[MAX_EDGES];
    size_t targets[MAX_EDGES];
    unsigned char seen[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source_value = input[3 + 2 * edge];
        const int64_t target_value = input[4 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            target_value < 0 || target_value >= vertex_count_value ||
            source_value == target_value) return -1;
        const size_t source = (size_t)source_value;
        const size_t target = (size_t)target_value;
        if (seen[source][target]) return -1;
        seen[source][target] = 1;
        sources[edge] = source;
        targets[edge] = target;
    }

    int64_t hubs[MAX_VERTICES] = {0};
    int64_t authorities[MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) hubs[vertex] = SCORE_SCALE;

    for (size_t iteration = 0; iteration < iteration_count; ++iteration) {
        int64_t raw[MAX_VERTICES] = {0};
        for (size_t edge = 0; edge < edge_count; ++edge)
            raw[targets[edge]] += hubs[sources[edge]];
        int64_t total = 0;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) total += raw[vertex];
        for (size_t vertex = 0; vertex < vertex_count; ++vertex)
            authorities[vertex] = total == 0 ? 0 : raw[vertex] * SCORE_SCALE / total;

        for (size_t vertex = 0; vertex < vertex_count; ++vertex) raw[vertex] = 0;
        for (size_t edge = 0; edge < edge_count; ++edge)
            raw[sources[edge]] += authorities[targets[edge]];
        total = 0;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) total += raw[vertex];
        for (size_t vertex = 0; vertex < vertex_count; ++vertex)
            hubs[vertex] = total == 0 ? 0 : raw[vertex] * SCORE_SCALE / total;
    }

    int64_t result = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        result += (int64_t)(vertex + 1) * (authorities[vertex] + INT64_C(65537) * hubs[vertex]);
    return result;
}
