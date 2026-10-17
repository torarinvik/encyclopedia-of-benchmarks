#include <stddef.h>
#include <stdint.h>

#define KAL_MAX_VERTICES 32
#define KAL_MAX_EDGES 128
#define KAL_EDGE_TABLE_SIZE (KAL_MAX_VERTICES * KAL_MAX_VERTICES)
#define KAL_MAX_INPUT_LENGTH (2 + 2 * KAL_MAX_EDGES)

int64_t kahns_algorithm_long(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > KAL_MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_count = values[0];
    const int64_t edge_count = values[1];
    if (vertex_count < 1 || vertex_count > KAL_MAX_VERTICES || edge_count < 0 || edge_count > KAL_MAX_EDGES ||
        length != (size_t)(2 + 2 * edge_count)) return -1;

    int64_t edge_multiplicity[KAL_EDGE_TABLE_SIZE] = {0};
    int64_t indegree[KAL_MAX_VERTICES] = {0};
    int64_t distance[KAL_MAX_VERTICES];
    int64_t queue[KAL_MAX_VERTICES];
    for (int64_t vertex = 0; vertex < vertex_count; ++vertex) distance[vertex] = 1;
    for (int64_t edge = 0; edge < edge_count; ++edge) {
        const int64_t source = values[2 + 2 * edge];
        const int64_t destination = values[3 + 2 * edge];
        if (source < 0 || source >= vertex_count || destination < 0 || destination >= vertex_count) return -1;
        ++edge_multiplicity[source * KAL_MAX_VERTICES + destination];
        ++indegree[destination];
    }

    size_t head = 0, tail = 0;
    for (int64_t vertex = 0; vertex < vertex_count; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    int64_t processed = 0, maximum = 1;
    while (head < tail) {
        const int64_t source = queue[head++];
        ++processed;
        if (distance[source] > maximum) maximum = distance[source];
        for (int64_t destination = 0; destination < vertex_count; ++destination) {
            const int64_t copies = edge_multiplicity[source * KAL_MAX_VERTICES + destination];
            if (copies == 0) continue;
            const int64_t candidate = distance[source] + 1;
            if (candidate > distance[destination]) distance[destination] = candidate;
            for (int64_t copy = 0; copy < copies; ++copy)
                if (--indegree[destination] == 0) queue[tail++] = destination;
        }
    }
    if (processed != vertex_count) return -1;
    for (int64_t vertex = 0; vertex < vertex_count; ++vertex)
        if (distance[vertex] > maximum) maximum = distance[vertex];
    return maximum;
}
