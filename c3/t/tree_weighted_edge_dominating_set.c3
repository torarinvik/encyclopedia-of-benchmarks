// Uncompiled minimum-weight tree edge-domination draft.
module tree_weighted_edge_dominating_set;
fn long tweds_min(long a, long b) { return a < b ? a : b; }
fn long tree_weighted_edge_dominating_set(long* input, usz length) @export("tree_weighted_edge_dominating_set") {
    if (input == null || length < 1 || length > 128) return -1;
    long nv = input[0];
    if (nv < 1 || nv > 64 || length != (usz)(2*nv-1)) return -1;
    usz n = (usz)nv;
    for (usz v = 1; v < n; v++)
        if (input[v] < 0 || input[v] >= (long)v || input[n+v-1] < 0 || input[n+v-1] > 1000000) return -1;
    long inf = 1000000000000;
    long[64] selected = zeroed, closed = zeroed, pending = zeroed;
    for (usz v = 0; v < n; v++) selected[v] = inf;
    for (usz v = n; v > 1;) {
        v--;
        usz p = (usz)input[v];
        long skip = tweds_min(selected[v], closed[v]);
        long take = input[n+v-1] + tweds_min(selected[v], pending[v]);
        selected[p] = tweds_min(inf, tweds_min(selected[p] + tweds_min(skip, take), pending[p] + take));
        closed[p] = tweds_min(inf, closed[p] + selected[v]);
        pending[p] = tweds_min(inf, pending[p] + skip);
    }
    return tweds_min(selected[0], closed[0]);
}
