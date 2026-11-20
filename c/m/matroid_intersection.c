#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES INT64_C(10)
#define MAX_EDGES INT64_C(20)
#define MAX_COLORS INT64_C(8)
#define MAX_LENGTH ((size_t)72)
#define NO_EDGE INT64_C(20)

static bool mi_is_forest(const int64_t *input, int64_t vertices, int64_t edges,
                         int64_t edge_start, const bool *chosen,
                         int64_t removed, int64_t added) {
    int64_t parent[10];
    for (int64_t v = 0; v < vertices; ++v) parent[v] = v;
    for (int64_t edge = 0; edge < edges; ++edge) {
        if (edge != added && (!chosen[edge] || edge == removed)) continue;
        int64_t a = input[edge_start + 3 * edge];
        int64_t b = input[edge_start + 3 * edge + 1];
        while (parent[a] != a) a = parent[a];
        while (parent[b] != b) b = parent[b];
        if (a == b) return false;
        parent[b] = a;
    }
    return true;
}

static bool mi_within_quotas(const int64_t *input, int64_t colors,
                            int64_t edges, int64_t edge_start,
                            const bool *chosen, int64_t removed, int64_t added) {
    int64_t counts[8] = {0};
    for (int64_t edge = 0; edge < edges; ++edge) {
        if (edge != added && (!chosen[edge] || edge == removed)) continue;
        int64_t color = input[edge_start + 3 * edge + 2];
        if (++counts[color] > input[3 + color]) return false;
    }
    return true;
}

int64_t matroid_intersection(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_LENGTH) return -1;
    int64_t vertices = input[0], edges = input[1], colors = input[2];
    if (vertices < 1 || vertices > MAX_VERTICES || edges < 0 || edges > MAX_EDGES
            || colors < 1 || colors > MAX_COLORS
            || length != (size_t)(3 + colors + 3 * edges)) return -1;
    for (int64_t color = 0; color < colors; ++color) {
        if (input[3 + color] < 0 || input[3 + color] > MAX_EDGES) return -1;
    }
    int64_t edge_start = 3 + colors;
    for (int64_t edge = 0; edge < edges; ++edge) {
        int64_t u = input[edge_start + 3 * edge];
        int64_t v = input[edge_start + 3 * edge + 1];
        int64_t color = input[edge_start + 3 * edge + 2];
        if (u < 0 || u >= vertices || v < 0 || v >= vertices
                || color < 0 || color >= colors) return -1;
    }

    bool chosen[20] = {false};
    for (;;) {
        int64_t predecessor[20];
        int64_t queue[20];
        for (int64_t edge = 0; edge < edges; ++edge) predecessor[edge] = -2;
        int64_t head = 0, tail = 0;
        for (int64_t edge = 0; edge < edges; ++edge) {
            if (!chosen[edge] && mi_is_forest(input, vertices, edges, edge_start,
                                              chosen, -1, edge)) {
                predecessor[edge] = -1;
                queue[tail++] = edge;
            }
        }
        int64_t terminal = -1;
        while (head < tail && terminal < 0) {
            int64_t current = queue[head++];
            if (!chosen[current]) {
                if (mi_within_quotas(input, colors, edges, edge_start,
                                     chosen, -1, current)) {
                    terminal = current;
                    break;
                }
                for (int64_t inside = 0; inside < edges; ++inside) {
                    if (chosen[inside] && predecessor[inside] == -2
                            && mi_within_quotas(input, colors, edges, edge_start,
                                                chosen, inside, current)) {
                        predecessor[inside] = current;
                        queue[tail++] = inside;
                    }
                }
            } else {
                for (int64_t outside = 0; outside < edges; ++outside) {
                    if (!chosen[outside] && predecessor[outside] == -2
                            && mi_is_forest(input, vertices, edges, edge_start,
                                            chosen, current, outside)) {
                        predecessor[outside] = current;
                        queue[tail++] = outside;
                    }
                }
            }
        }
        if (terminal < 0) break;
        for (int64_t edge = terminal; edge >= 0; edge = predecessor[edge]) {
            chosen[edge] = !chosen[edge];
        }
    }

    int64_t answer = 0;
    for (int64_t edge = 0; edge < edges; ++edge) answer += chosen[edge];
    return answer;
}
