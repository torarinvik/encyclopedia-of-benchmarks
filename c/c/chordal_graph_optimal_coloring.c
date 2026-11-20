/* Uncompiled chordal-graph optimal coloring draft. */
#include <stddef.h>
#include <stdint.h>
int64_t chordal_graph_optimal_coloring(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 18) return -1;
    int64_t nv = input[0];
    if (nv < 1 || nv > 16 || length != (size_t)nv + 1) return -1;
    int n = (int)nv, limit = 1 << n;
    int rows[16], weight[16] = {0}, colors[16], order[16], selected = 0, maximum = 0;
    for (int v = 0; v < n; ++v) {
        if (input[v+1] < 0 || input[v+1] >= limit || (input[v+1] & (1 << v))) return -1;
        rows[v] = (int)input[v+1]; colors[v] = -1;
    }
    for (int v = 0; v < n; ++v) for (int u = 0; u < v; ++u)
        if (!!(rows[v] & (1 << u)) != !!(rows[u] & (1 << v))) return -1;
    for (int i = 0; i < n; ++i) {
        int v = -1;
        for (int u = 0; u < n; ++u)
            if (!(selected & (1 << u)) && (v < 0 || weight[u] > weight[v])) v = u;
        int earlier = rows[v] & selected;
        for (int j = 0; j < i; ++j) {
            int u = order[j];
            if ((earlier & (1 << u)) && (earlier & ~(rows[u] | (1 << u)))) return -2;
        }
        order[i] = v; selected |= 1 << v;
        for (int u = 0; u < n; ++u) if (!(selected & (1 << u)) && (rows[v] & (1 << u))) ++weight[u];
    }
    for (int i = 0; i < n; ++i) {
        int v = order[i], used = 0;
        for (int u = 0; u < n; ++u) if ((rows[v] & (1 << u)) && colors[u] >= 0) used |= 1 << colors[u];
        int color = 0; while (used & (1 << color)) ++color;
        colors[v] = color; if (color + 1 > maximum) maximum = color + 1;
    }
    return maximum;
}
