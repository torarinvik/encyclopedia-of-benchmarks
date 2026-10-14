#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 4096

static void sift_down(int64_t *keys, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) ++child;
        if (keys[root] >= keys[child]) break;
        int64_t temporary = keys[root]; keys[root] = keys[child]; keys[child] = temporary;
        root = child;
    }
}

static size_t find_root(size_t *parent, size_t node)
{
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

int64_t kruskal(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 3 * MAX_EDGES) return -2;
    if (values[0] < 0 || values[0] > MAX_VERTICES || values[1] < 0 || values[1] > MAX_EDGES) return -2;
    const size_t vertices = (size_t)values[0], edges = (size_t)values[1];
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;

    int64_t keys[MAX_EDGES];
    for (size_t edge = 0; edge < edges; ++edge) {
        int64_t u = values[2 + 3 * edge], v = values[3 + 3 * edge], weight = values[4 + 3 * edge];
        if (u < 0 || v < 0 || (uint64_t)u >= vertices || (uint64_t)v >= vertices ||
            weight < 0 || weight > INT64_C(2147483647)) return -2;
        if (u > v) { int64_t temporary = u; u = v; v = temporary; }
        keys[edge] = weight * INT64_C(4096) + u * INT64_C(64) + v;
    }
    for (size_t start = edges / 2; start > 0;) { --start; sift_down(keys, start, edges); }
    for (size_t end = edges; end > 1;) {
        --end;
        int64_t temporary = keys[0]; keys[0] = keys[end]; keys[end] = temporary;
        sift_down(keys, 0, end);
    }

    size_t parent[MAX_VERTICES], rank[MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertices; ++vertex) parent[vertex] = vertex;
    size_t selected = 0;
    int64_t total = 0;
    for (size_t edge = 0; edge < edges && selected + 1 < vertices; ++edge) {
        const int64_t key = keys[edge];
        const size_t u = (size_t)((key % INT64_C(4096)) / INT64_C(64));
        const size_t v = (size_t)(key % INT64_C(64));
        size_t root_u = find_root(parent, u), root_v = find_root(parent, v);
        if (root_u != root_v) {
            total += key / INT64_C(4096);
            ++selected;
            if (rank[root_u] < rank[root_v]) parent[root_u] = root_v;
            else if (rank[root_u] > rank[root_v]) parent[root_v] = root_u;
            else { parent[root_v] = root_u; ++rank[root_u]; }
        }
    }
    return selected + 1 == vertices ? total : -1;
}
