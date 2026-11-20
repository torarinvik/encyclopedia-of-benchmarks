#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 120, MAX_PARSEABLE_INPUT = 246 };

int64_t lovasz_toggle_defective_coloring_trace(const int64_t *input, size_t length) {
    if (input == NULL || length < 5 || length > MAX_PARSEABLE_INPUT) return -1;
    const int64_t n64 = input[0], r64 = input[1], b64 = input[2];
    const int64_t initial_mask = input[3], m64 = input[4];
    if (n64 < 0 || n64 > MAX_N || r64 < 1 || r64 > 8 || b64 < 1 || b64 > 8 ||
        m64 < 0 || m64 > MAX_M) return -1;
    const int n = (int)n64, red_limit = (int)r64, blue_limit = (int)b64;
    const int m = (int)m64;
    const int64_t all_mask = (INT64_C(1) << n) - 1;
    if (initial_mask < 0 || (initial_mask & ~all_mask) != 0 ||
        length != 5 + 2 * (size_t)m) return -1;

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int degree[MAX_N] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[5 + 2 * (size_t)edge];
        const int64_t v64 = input[6 + 2 * (size_t)edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        if (++degree[u] > red_limit + blue_limit + 1 ||
            ++degree[v] > red_limit + blue_limit + 1) return -1;
    }

    int64_t red_mask = initial_mask;
    int toggle_count = 0;
    for (;;) {
        int bad = -1;
        for (int v = 0; v < n; ++v) {
            int red_degree = 0;
            for (int u = 0; u < n; ++u)
                if (adjacent[v][u] && ((red_mask >> u) & 1) != 0) ++red_degree;
            const int blue_degree = degree[v] - red_degree;
            const int is_red = (int)((red_mask >> v) & 1);
            if ((is_red && red_degree > red_limit) ||
                (!is_red && blue_degree > blue_limit)) {
                bad = v;
                break;
            }
        }
        if (bad < 0) break;
        red_mask ^= INT64_C(1) << bad;
        ++toggle_count;
    }
    return ((int64_t)toggle_count << n) | red_mask;
}
