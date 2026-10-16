/* Bounded Johnson all-pairs shortest paths for the pinned R contract. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH (2 + 3 * MAX_EDGES)
#define MAX_QUEUE (MAX_EDGES + 1)
#define UNREACHABLE INT64_MAX
#define UNREACHABLE_SENTINEL (INT64_C(1) << 62)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t fnv_word(uint64_t hash, int64_t word)
{
    const uint64_t bits = (uint64_t)word;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int64_t johnson_shortest_paths(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_value = input[0];
    const int64_t edge_value = input[1];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES) return -1;
    const size_t vertices = (size_t)vertex_value;
    const size_t edges = (size_t)edge_value;
    if (length != 2 + 3 * edges) return -1;

    size_t edge_from[MAX_EDGES];
    size_t edge_to[MAX_EDGES];
    int64_t edge_weight[MAX_EDGES];
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t from = input[2 + 3 * edge];
        const int64_t to = input[3 + 3 * edge];
        const int64_t weight = input[4 + 3 * edge];
        if (from < 1 || from > vertex_value || to < 1 || to > vertex_value || weight < -32 || weight > 32) return -1;
        edge_from[edge] = (size_t)(from - 1);
        edge_to[edge] = (size_t)(to - 1);
        edge_weight[edge] = weight;
    }

    int64_t potential[MAX_VERTICES] = {0};
    for (size_t iteration = 1; iteration < vertices; ++iteration) {
        bool updated = false;
        for (size_t edge = 0; edge < edges; ++edge) {
            const size_t from = edge_from[edge], to = edge_to[edge];
            const int64_t candidate = potential[from] + edge_weight[edge];
            if (candidate < potential[to]) {
                potential[to] = candidate;
                updated = true;
            }
        }
        if (!updated) break;
    }
    for (size_t edge = 0; edge < edges; ++edge)
        if (potential[edge_from[edge]] + edge_weight[edge] < potential[edge_to[edge]]) return -1;

    uint64_t result = FNV_OFFSET_BASIS;
    for (size_t source = 0; source < vertices; ++source) {
        int64_t distance[MAX_VERTICES];
        bool visited[MAX_VERTICES] = {false};
        for (size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = UNREACHABLE;
        distance[source] = 0;

        size_t queue_vertices[MAX_QUEUE];
        int64_t queue_distances[MAX_QUEUE];
        size_t queue_length = 1;
        queue_vertices[0] = source;
        queue_distances[0] = 0;
        while (queue_length > 0) {
            size_t minimum = 0;
            for (size_t index = 1; index < queue_length; ++index)
                if (queue_distances[index] < queue_distances[minimum]) minimum = index;
            const size_t current = queue_vertices[minimum];
            for (size_t index = minimum + 1; index < queue_length; ++index) {
                queue_vertices[index - 1] = queue_vertices[index];
                queue_distances[index - 1] = queue_distances[index];
            }
            --queue_length;
            if (visited[current]) continue;
            visited[current] = true;

            for (size_t edge = 0; edge < edges; ++edge) {
                if (edge_from[edge] != current) continue;
                const size_t next = edge_to[edge];
                const int64_t reweighted = edge_weight[edge] + potential[current] - potential[next];
                const int64_t candidate = distance[current] + reweighted;
                if (!visited[next] && candidate < distance[next]) {
                    distance[next] = candidate;
                    queue_vertices[queue_length] = next;
                    queue_distances[queue_length] = candidate;
                    ++queue_length;
                }
            }
        }

        for (size_t destination = 0; destination < vertices; ++destination) {
            const int64_t output = distance[destination] == UNREACHABLE
                ? UNREACHABLE_SENTINEL
                : distance[destination] - potential[source] + potential[destination];
            result = fnv_word(result, output);
        }
    }
    return (int64_t)(result & INT64_MAX);
}
