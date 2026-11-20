#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 6, MAX_EDGES = 6, MAX_LENGTH = 15 };

static int free_color(size_t vertex, int64_t color, size_t vertices,
                      const int edge_at[MAX_VERTICES][MAX_VERTICES],
                      const int64_t colors[MAX_EDGES]) {
    for (size_t other = 0; other < vertices; ++other) {
        int edge = edge_at[vertex][other];
        if (edge >= 0 && colors[edge] == color) return 0;
    }
    return 1;
}

static int in_fan(size_t vertex, const size_t fan[MAX_VERTICES], size_t count) {
    for (size_t i = 0; i < count; ++i) if (fan[i] == vertex) return 1;
    return 0;
}

int64_t misra_gries_edge_coloring(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES)
        return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    size_t left[MAX_EDGES] = {0}, right[MAX_EDGES] = {0};
    int edge_at[MAX_VERTICES][MAX_VERTICES];
    for (size_t i = 0; i < MAX_VERTICES; ++i)
        for (size_t j = 0; j < MAX_VERTICES; ++j) edge_at[i][j] = -1;
    size_t degree[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        int64_t a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || b < 0 || (uint64_t)a >= vertices || (uint64_t)b >= vertices || a == b)
            return -1;
        size_t u = (size_t)(a < b ? a : b), v = (size_t)(a < b ? b : a);
        if (edge_at[u][v] >= 0) return -1;
        left[edge] = u;
        right[edge] = v;
        edge_at[u][v] = edge_at[v][u] = (int)edge;
        ++degree[u];
        ++degree[v];
    }
    size_t delta = 0;
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        if (degree[vertex] > delta) delta = degree[vertex];
    const size_t palette = edge_count == 0 ? 0 : delta + 1;
    int64_t colors[MAX_EDGES];
    for (size_t edge = 0; edge < MAX_EDGES; ++edge) colors[edge] = -1;

    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t center = left[edge];
        size_t fan[MAX_VERTICES] = {0};
        size_t fan_count = 1;
        fan[0] = right[edge];
        for (;;) {
            const size_t tail = fan[fan_count - 1];
            int extended = 0;
            for (size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                const int candidate_edge = edge_at[center][neighbor];
                if (candidate_edge < 0 || colors[candidate_edge] < 0
                    || in_fan(neighbor, fan, fan_count)
                    || !free_color(tail, colors[candidate_edge], vertices, edge_at, colors))
                    continue;
                fan[fan_count++] = neighbor;
                extended = 1;
                break;
            }
            if (!extended) break;
        }
        int64_t color_c = 0, color_d = 0;
        while (color_c < (int64_t)palette
               && !free_color(center, color_c, vertices, edge_at, colors)) ++color_c;
        while (color_d < (int64_t)palette
               && !free_color(fan[fan_count - 1], color_d, vertices, edge_at, colors)) ++color_d;
        if (color_c >= (int64_t)palette || color_d >= (int64_t)palette) return -1;

        int path[MAX_VERTICES] = {-1};
        size_t path_count = 0, current = center;
        int64_t wanted = color_d;
        int visited[MAX_VERTICES] = {0};
        visited[current] = 1;
        for (size_t step = 0; step < vertices; ++step) {
            int path_edge = -1;
            size_t next = 0;
            for (size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                int candidate = edge_at[current][neighbor];
                if (candidate >= 0 && colors[candidate] == wanted) {
                    path_edge = candidate;
                    next = neighbor;
                    break;
                }
            }
            if (path_edge < 0 || visited[next]) break;
            path[path_count++] = path_edge;
            visited[next] = 1;
            current = next;
            wanted = wanted == color_d ? color_c : color_d;
        }
        for (size_t i = 0; i < path_count; ++i)
            colors[path[i]] = colors[path[i]] == color_d ? color_c : color_d;

        size_t prefix_end = fan_count;
        for (size_t i = 0; i < fan_count; ++i)
            if (free_color(fan[i], color_d, vertices, edge_at, colors)) {
                prefix_end = i;
                break;
            }
        if (prefix_end == fan_count) return -1;
        int64_t shifted[MAX_VERTICES] = {0};
        for (size_t i = 0; i < prefix_end; ++i)
            shifted[i] = colors[edge_at[center][fan[i + 1]]];
        for (size_t i = 0; i < prefix_end; ++i)
            colors[edge_at[center][fan[i]]] = shifted[i];
        colors[edge_at[center][fan[prefix_end]]] = color_d;
    }

    int64_t signature = 0;
    for (size_t edge = 0; edge < edge_count; ++edge)
        signature |= colors[edge] << (3 * edge);
    return (int64_t)palette * 262144 + signature;
}
