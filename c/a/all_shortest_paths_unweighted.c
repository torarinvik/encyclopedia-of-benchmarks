#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 16, MAX_EDGES = 64, MAX_INPUT = 133, MAX_PATHS = 162, MAX_OUTPUT = 1296 };

typedef struct {
    int n;
    int target;
    bool (*predecessor)[MAX_VERTICES];
    bool *useful;
    int *path;
    int depth;
    uint8_t *staged;
    size_t used;
    int64_t count;
    bool overflow;
} Search;

static void enumerate(Search *search, int u)
{
    if (search->overflow) return;
    search->path[search->depth] = u;
    if (u == search->target) {
        if (search->count >= MAX_PATHS || search->used + (size_t)search->depth + 2 > MAX_OUTPUT) {
            search->overflow = true;
            return;
        }
        for (int i = 0; i <= search->depth; ++i) search->staged[search->used++] = (uint8_t)search->path[i];
        search->staged[search->used++] = UINT8_MAX;
        ++search->count;
        return;
    }
    for (int v = 0; v < search->n && !search->overflow; ++v) {
        if (search->useful[v] && search->predecessor[v][u]) {
            ++search->depth;
            enumerate(search, v);
            --search->depth;
        }
    }
}

int64_t all_shortest_paths_unweighted(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const int n = (int)input[0], m = (int)input[1];
    if (input[2] < 0 || input[2] >= n || input[3] < 0 || input[3] >= n || length != 4 + 2 * (size_t)m) return -1;
    const int source = (int)input[2], target = (int)input[3];

    bool adjacent[MAX_VERTICES][MAX_VERTICES] = {{false}};
    for (int e = 0; e < m; ++e) {
        const int64_t raw_u = input[4 + 2 * e], raw_v = input[5 + 2 * e];
        if (raw_u < 0 || raw_u >= n || raw_v < 0 || raw_v >= n || raw_u == raw_v) return -1;
        const int u = (int)raw_u, v = (int)raw_v;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }

    int distance[MAX_VERTICES];
    int queue[MAX_VERTICES];
    bool predecessor[MAX_VERTICES][MAX_VERTICES] = {{false}};
    for (int v = 0; v < n; ++v) distance[v] = -1;
    int head = 0, tail = 0;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            if (!adjacent[u][v]) continue;
            if (distance[v] < 0) {
                distance[v] = distance[u] + 1;
                queue[tail++] = v;
            }
            if (distance[v] == distance[u] + 1) predecessor[v][u] = true;
        }
    }

    bool useful[MAX_VERTICES] = {false};
    if (distance[target] >= 0) {
        int stack[MAX_VERTICES], stack_size = 0;
        useful[target] = true;
        stack[stack_size++] = target;
        while (stack_size > 0) {
            const int v = stack[--stack_size];
            for (int u = 0; u < n; ++u) {
                if (predecessor[v][u] && !useful[u]) {
                    useful[u] = true;
                    stack[stack_size++] = u;
                }
            }
        }
    }

    uint8_t staged[MAX_OUTPUT] = {0};
    int path[MAX_VERTICES] = {0};
    Search search = {n, target, predecessor, useful, path, 0, staged, 0, 0, false};
    if (distance[target] >= 0) enumerate(&search, source);
    if (search.overflow) return -2;
    if (output == NULL || capacity < search.used) return -2;
    for (size_t i = 0; i < search.used; ++i) output[i] = staged[i];
    return search.count;
}
