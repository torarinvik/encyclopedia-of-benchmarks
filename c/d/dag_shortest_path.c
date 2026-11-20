#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 12, MAX_EDGES = 66, MAX_LENGTH = 203 };
static const int64_t DISTANCE_OFFSET = 100000;
static const int64_t INFINITY_DISTANCE = INT64_C(1) << 60;

int64_t dag_shortest_path(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 4 + 3 * edge_count || input[2] < 0 || input[2] >= (int64_t)vertex_count
            || input[3] < 0 || input[3] >= (int64_t)vertex_count) return -1;
    int64_t from[MAX_EDGES], to[MAX_EDGES], weight[MAX_EDGES];
    int64_t indegree[MAX_VERTICES] = {0}, queue[MAX_VERTICES], order[MAX_VERTICES];
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t start = input[4 + 3 * edge];
        const int64_t end = input[5 + 3 * edge];
        const int64_t cost = input[6 + 3 * edge];
        if (start < 0 || start >= (int64_t)vertex_count || end < 0 || end >= (int64_t)vertex_count
                || start == end || cost < -1000 || cost > 1000) return -1;
        for (size_t previous = 0; previous < edge; ++previous)
            if (from[previous] == start && to[previous] == end) return -1;
        from[edge] = start; to[edge] = end; weight[edge] = cost;
        indegree[end]++;
    }
    size_t head = 0, tail = 0, order_count = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = (int64_t)vertex;
    while (head < tail) {
        const int64_t vertex = queue[head++];
        order[order_count++] = vertex;
        for (size_t edge = 0; edge < edge_count; ++edge) if (from[edge] == vertex) {
            indegree[to[edge]]--;
            if (indegree[to[edge]] == 0) queue[tail++] = to[edge];
        }
    }
    if (order_count != vertex_count) return -1;
    int64_t distance[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) distance[vertex] = INFINITY_DISTANCE;
    distance[input[2]] = 0;
    for (size_t position = 0; position < vertex_count; ++position) {
        const int64_t vertex = order[position];
        if (distance[vertex] == INFINITY_DISTANCE) continue;
        for (size_t edge = 0; edge < edge_count; ++edge) if (from[edge] == vertex) {
            const int64_t candidate = distance[vertex] + weight[edge];
            if (candidate < distance[to[edge]]) distance[to[edge]] = candidate;
        }
    }
    const int64_t answer = distance[input[3]];
    return answer == INFINITY_DISTANCE ? 0 : DISTANCE_OFFSET + answer;
}
