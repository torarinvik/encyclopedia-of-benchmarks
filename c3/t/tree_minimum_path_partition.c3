// Uncompiled minimum tree path-partition draft.
module tree_minimum_path_partition;
fn long tree_minimum_path_partition(long* input, usz length) @export("tree_minimum_path_partition") {
    if (input == null || length < 1 || length > 65) return -1;
    long nv = input[0];
    if (nv < 1 || nv > 64 || length != (usz)nv) return -1;
    usz n = (usz)nv;
    for (usz v = 1; v < n; v++) if (input[v] < 0 || input[v] >= (long)v) return -1;
    long[64] base = zeroed, first = zeroed, second = zeroed;
    for (usz v = n; v > 1;) {
        v--;
        usz p = (usz)input[v];
        long best = base[v] + first[v] + second[v];
        long gain = 1 + base[v] + first[v] - best;
        base[p] += best;
        if (gain > first[p]) { second[p] = first[p]; first[p] = gain; }
        else if (gain > second[p]) second[p] = gain;
    }
    return nv - base[0] - first[0] - second[0];
}
