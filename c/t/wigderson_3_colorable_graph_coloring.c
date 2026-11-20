#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { WIG_MAX_VERTICES = 32, WIG_MAX_EDGES = 128,
       WIG_MAX_INPUT = 2 + 2 * WIG_MAX_EDGES };

int64_t wigderson_3_colorable_graph_coloring(const int64_t *input,
        size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > WIG_MAX_INPUT + 1) return -1;
    if (input[0] < 0 || input[0] > WIG_MAX_VERTICES ||
        input[1] < 0 || input[1] > WIG_MAX_EDGES) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    bool adjacent[WIG_MAX_VERTICES][WIG_MAX_VERTICES] = {{false}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t raw_u = input[2 + 2 * edge];
        const int64_t raw_v = input[3 + 2 * edge];
        if (raw_u < 0 || raw_v < 0 || raw_u >= raw_v ||
            (uint64_t)raw_v >= n) return -1;
        const size_t u = (size_t)raw_u;
        const size_t v = (size_t)raw_v;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
    }

    bool active[WIG_MAX_VERTICES] = {false};
    uint8_t color[WIG_MAX_VERTICES] = {0};
    for (size_t v = 0; v < n; ++v) active[v] = true;
    size_t threshold = 0;
    while ((threshold + 1) * (threshold + 1) <= n) ++threshold;
    int64_t next_color = 1;

    for (;;) {
        size_t chosen = n;
        size_t maximum_degree = 0;
        for (size_t v = 0; v < n; ++v) {
            if (!active[v]) continue;
            size_t degree = 0;
            for (size_t w = 0; w < n; ++w)
                if (active[w] && adjacent[v][w]) ++degree;
            if (chosen == n || degree > maximum_degree) {
                chosen = v;
                maximum_degree = degree;
            }
        }
        if (chosen == n || maximum_degree < threshold) break;

        bool in_neighborhood[WIG_MAX_VERTICES] = {false};
        int8_t side[WIG_MAX_VERTICES];
        size_t queue[WIG_MAX_VERTICES];
        for (size_t v = 0; v < n; ++v) {
            side[v] = -1;
            in_neighborhood[v] = active[v] && adjacent[chosen][v];
        }
        for (size_t root = 0; root < n; ++root) {
            if (!in_neighborhood[root] || side[root] >= 0) continue;
            size_t head = 0, tail = 0;
            side[root] = 0;
            queue[tail++] = root;
            while (head < tail) {
                const size_t u = queue[head++];
                for (size_t v = 0; v < n; ++v) {
                    if (!in_neighborhood[v] || !adjacent[u][v]) continue;
                    if (side[v] < 0) {
                        side[v] = (int8_t)(1 - side[u]);
                        queue[tail++] = v;
                    } else if (side[v] == side[u]) {
                        return -1;
                    }
                }
            }
        }
        for (size_t v = 0; v < n; ++v)
            if (in_neighborhood[v]) color[v] = (uint8_t)(next_color + side[v]);
        color[chosen] = (uint8_t)(next_color + 2);
        active[chosen] = false;
        for (size_t v = 0; v < n; ++v)
            if (adjacent[chosen][v]) active[v] = false;
        next_color += 2;
    }

    for (size_t v = 0; v < n; ++v) {
        if (!active[v]) continue;
        bool used[WIG_MAX_VERTICES + 2] = {false};
        for (size_t w = 0; w < n; ++w)
            if (adjacent[v][w] && color[w] < WIG_MAX_VERTICES + 2)
                used[color[w]] = true;
        int64_t candidate = next_color;
        while (candidate < WIG_MAX_VERTICES + 2 && used[candidate]) ++candidate;
        if (candidate >= WIG_MAX_VERTICES + 2) return -1;
        color[v] = (uint8_t)candidate;
    }

    uint8_t palette_size = 0;
    for (size_t v = 0; v < n; ++v)
        if (color[v] > palette_size) palette_size = color[v];
    const size_t output_bytes = n + 1;
    if (output == NULL || capacity < output_bytes) return -2;
    output[0] = palette_size;
    for (size_t v = 0; v < n; ++v) output[v + 1] = color[v];
    return (int64_t)output_bytes;
}
