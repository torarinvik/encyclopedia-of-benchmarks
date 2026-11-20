/* Uncompiled minimum-weight tree edge-domination draft. */
#include <stddef.h>
#include <stdint.h>

static int64_t min64(int64_t a, int64_t b) { return a < b ? a : b; }

int64_t tree_weighted_edge_dominating_set(const int64_t *input, size_t length) {
    const int64_t inf = 1000000000000LL;
    if (!input || length < 1 || length > 128) return -1;
    int64_t nv = input[0];
    if (nv < 1 || nv > 64 || length != (size_t)(2 * nv - 1)) return -1;
    size_t n = (size_t)nv;
    for (size_t v = 1; v < n; ++v) {
        if (input[v] < 0 || input[v] >= (int64_t)v ||
            input[n + v - 1] < 0 || input[n + v - 1] > 1000000) return -1;
    }
    int64_t selected[64], closed[64] = {0}, pending[64] = {0};
    for (size_t v = 0; v < n; ++v) selected[v] = inf;
    for (size_t v = n; v-- > 1;) {
        size_t p = (size_t)input[v];
        int64_t skip = min64(selected[v], closed[v]);
        int64_t take = input[n + v - 1] + min64(selected[v], pending[v]);
        selected[p] = min64(inf, min64(selected[p] + min64(skip, take), pending[p] + take));
        closed[p] = min64(inf, closed[p] + selected[v]);
        pending[p] = min64(inf, pending[p] + skip);
    }
    return min64(selected[0], closed[0]);
}
