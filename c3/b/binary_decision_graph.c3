module binary_decision_graph;

fn void put_i64(uint8* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at * 8 + b] = (uint8)(bits >> (b * 8));
}

fn long binary_decision_graph(long* input, usz length, uint8* output, usz capacity) @export("binary_decision_graph") {
    if (input == null || length < 2 || length > 65) return -1;
    long nv = input[0];
    if (nv < 1 || nv > 6 || length != 1 + ((usz)1 << (usz)nv)) return -1;
    usz n = (usz)nv;
    usz count = (usz)1 << n;
    long[64] ids; long[64] next;
    long[63] vars; long[63] lows; long[63] highs;
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
        ids[i] = input[i + 1];
    }
    usz nodes = 0, current_count = count;
    for (usz step = 0; step < n; step++) {
        usz variable = n - 1 - step, next_count = current_count / 2;
        for (usz p = 0; p < next_count; p++) {
            long lo = ids[2 * p], hi = ids[2 * p + 1];
            if (lo == hi) { next[p] = lo; continue; }
            usz found = nodes, j = nodes;
            while (j > 0) {
                j--;
                if ((usz)vars[j] != variable) break;
                if (lows[j] == lo && highs[j] == hi) { found = j; break; }
            }
            if (found == nodes) {
                vars[nodes] = (long)variable; lows[nodes] = lo; highs[nodes] = hi;
                next[p] = (long)(2 + nodes); nodes++;
            } else next[p] = (long)(2 + found);
        }
        for (usz p = 0; p < next_count; p++) ids[p] = next[p];
        current_count = next_count;
    }
    usz bytes = 8 * (2 + 3 * nodes);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, (long)nodes);
    for (usz i = 0; i < nodes; i++) {
        put_i64(output, 2 + 3 * i, vars[i]); put_i64(output, 3 + 3 * i, lows[i]); put_i64(output, 4 + 3 * i, highs[i]);
    }
    return (long)bytes;
}
