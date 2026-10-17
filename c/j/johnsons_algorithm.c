/* Bounded Johnson all-pairs distances for the pinned Java matrix contract. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_INPUT_LENGTH (1 + MAX_VERTICES * MAX_VERTICES)
#define MAX_WEIGHT 32
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

int64_t johnsons_algorithm(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_value = input[0];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES) return -1;
    const size_t vertices = (size_t)vertex_value;
    if (length != 1 + vertices * vertices) return -1;

    int64_t weight[MAX_VERTICES][MAX_VERTICES] = {{0}};
    bool edge[MAX_VERTICES][MAX_VERTICES] = {{false}};
    bool reachable[MAX_VERTICES][MAX_VERTICES] = {{false}};
    for (size_t from = 0; from < vertices; ++from) {
        reachable[from][from] = true;
        for (size_t to = 0; to < vertices; ++to) {
            const int64_t value = input[1 + from * vertices + to];
            if (value < -MAX_WEIGHT || value > MAX_WEIGHT) return -1;
            if (from != to && value != 0) {
                edge[from][to] = true;
                weight[from][to] = value;
                reachable[from][to] = true;
            }
        }
    }
    for (size_t intermediate = 0; intermediate < vertices; ++intermediate)
        for (size_t from = 0; from < vertices; ++from)
            for (size_t to = 0; to < vertices; ++to)
                reachable[from][to] = reachable[from][to] ||
                    (reachable[from][intermediate] && reachable[intermediate][to]);
    for (size_t from = 0; from < vertices; ++from)
        for (size_t to = 0; to < vertices; ++to)
            if (!reachable[from][to]) return -1;

    int64_t potential[MAX_VERTICES] = {0};
    for (size_t iteration = 1; iteration < vertices; ++iteration) {
        bool updated = false;
        for (size_t from = 0; from < vertices; ++from) {
            for (size_t to = 0; to < vertices; ++to) {
                if (!edge[from][to]) continue;
                const int64_t candidate = potential[from] + weight[from][to];
                if (candidate < potential[to]) {
                    potential[to] = candidate;
                    updated = true;
                }
            }
        }
        if (!updated) break;
    }
    for (size_t from = 0; from < vertices; ++from) {
        for (size_t to = 0; to < vertices; ++to) {
            if (!edge[from][to]) continue;
            if (potential[from] + weight[from][to] < potential[to]) return -1;
            if (weight[from][to] + potential[from] - potential[to] <= 0) return -1;
        }
    }

    int64_t reweighted[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t from = 0; from < vertices; ++from)
        for (size_t to = 0; to < vertices; ++to)
            if (edge[from][to])
                reweighted[from][to] = weight[from][to] + potential[from] - potential[to];

    uint64_t result = FNV_OFFSET_BASIS;
    for (size_t source = 0; source < vertices; ++source) {
        int64_t distance[MAX_VERTICES];
        bool visited[MAX_VERTICES] = {false};
        for (size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = UNREACHABLE;
        distance[source] = 0;
        for (size_t step = 0; step < vertices; ++step) {
            size_t current = vertices;
            for (size_t vertex = 0; vertex < vertices; ++vertex)
                if (!visited[vertex] && (current == vertices || distance[vertex] <= distance[current]))
                    current = vertex;
            if (current == vertices || distance[current] == UNREACHABLE) break;
            visited[current] = true;
            for (size_t next = 0; next < vertices; ++next) {
                if (!edge[current][next] || visited[next]) continue;
                const int64_t candidate = distance[current] + reweighted[current][next];
                if (candidate < distance[next]) distance[next] = candidate;
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
