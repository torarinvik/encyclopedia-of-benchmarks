// Uncompiled chordal-graph optimal coloring draft.
module chordal_graph_optimal_coloring;
fn long chordal_graph_optimal_coloring(long* input, usz length) @export("chordal_graph_optimal_coloring") {
    if (input == null || length < 2 || length > 18) return -1;
    long nv = input[0];
    if (nv < 1 || nv > 16 || length != (usz)(nv+1)) return -1;
    int n = (int)nv;
    int[16] rows = zeroed, weight = zeroed, colors = zeroed, order = zeroed;
    for (int v = 0; v < n; v++) {
        if (input[v+1] < 0 || input[v+1] >= (1 << n) || (input[v+1] & (1 << v)) != 0) return -1;
        rows[v] = (int)input[v+1]; colors[v] = -1;
    }
    for (int v = 0; v < n; v++) for (int u = 0; u < v; u++)
        if (((rows[v] >> u) & 1) != ((rows[u] >> v) & 1)) return -1;
    int selected = 0;
    for (int i = 0; i < n; i++) {
        int v = -1;
        for (int u = 0; u < n; u++) if ((selected & (1 << u)) == 0 && (v < 0 || weight[u] > weight[v])) v = u;
        int earlier = rows[v] & selected;
        for (int j = 0; j < i; j++) {
            int u = order[j];
            if ((earlier & (1 << u)) != 0 && (earlier & ~(rows[u] | (1 << u))) != 0) return -2;
        }
        order[i] = v; selected |= 1 << v;
        for (int u = 0; u < n; u++) if ((selected & (1 << u)) == 0 && (rows[v] & (1 << u)) != 0) weight[u]++;
    }
    int maximum = 0;
    for (int i = 0; i < n; i++) {
        int v = order[i], used = 0;
        for (int u = 0; u < n; u++) if ((rows[v] & (1 << u)) != 0 && colors[u] >= 0) used |= 1 << colors[u];
        int color = 0; while ((used & (1 << color)) != 0) color++;
        colors[v] = color; if (color+1 > maximum) maximum = color+1;
    }
    return maximum;
}
