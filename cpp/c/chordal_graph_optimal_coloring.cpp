// Uncompiled chordal-graph optimal coloring draft.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t chordal_graph_optimal_coloring(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 18) return -1;
    const auto nv = input[0];
    if (nv < 1 || nv > 16 || length != static_cast<std::size_t>(nv) + 1) return -1;
    const int n = static_cast<int>(nv), limit = 1 << n;
    std::array<int,16> rows{}, weight{}, colors{}, order{};
    colors.fill(-1);
    for (int v = 0; v < n; ++v) {
        if (input[v+1] < 0 || input[v+1] >= limit || (input[v+1] & (1 << v))) return -1;
        rows[v] = static_cast<int>(input[v+1]);
    }
    for (int v = 0; v < n; ++v) for (int u = 0; u < v; ++u)
        if (bool(rows[v] & (1 << u)) != bool(rows[u] & (1 << v))) return -1;
    int selected = 0;
    for (int i = 0; i < n; ++i) {
        int v = -1;
        for (int u = 0; u < n; ++u)
            if (!(selected & (1 << u)) && (v < 0 || weight[u] > weight[v])) v = u;
        const int earlier = rows[v] & selected;
        for (int j = 0; j < i; ++j) {
            const int u = order[j];
            if ((earlier & (1 << u)) && (earlier & ~(rows[u] | (1 << u)))) return -2;
        }
        order[i] = v; selected |= 1 << v;
        for (int u = 0; u < n; ++u) if (!(selected & (1 << u)) && (rows[v] & (1 << u))) ++weight[u];
    }
    int maximum = 0;
    for (int i = 0; i < n; ++i) {
        const int v = order[i]; int used = 0;
        for (int u = 0; u < n; ++u) if ((rows[v] & (1 << u)) && colors[u] >= 0) used |= 1 << colors[u];
        int color = 0; while (used & (1 << color)) ++color;
        colors[v] = color; maximum = std::max(maximum, color + 1);
    }
    return maximum;
}
