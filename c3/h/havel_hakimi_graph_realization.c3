module havel_hakimi_graph_realization;

const usz MAX_N = 8;
const usz MAX_EDGES = 28;
const usz MAX_INPUT = 10;

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = bitcast(value, ulong);
    for (usz i = 0; i < 8; i++) { output[offset + i] = (char)(bits & 255); bits >>= 8; }
}

fn long havel_hakimi_graph_realization(long* input, usz length, char* output, usz capacity) @export("havel_hakimi_graph_realization") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long nv = input[0]; if (nv < 0 || nv > (long)MAX_N) return -1;
    usz n = (usz)nv; if (length != n + 1) return -1;
    long[MAX_N] residual; bool[MAX_N] active;
    for (usz v = 0; v < n; v++) {
        long d = input[v + 1]; if (d < 0 || d >= nv) return -1;
        residual[v] = d; active[v] = true;
    }
    long[MAX_EDGES * 2] edges; usz edge_count = 0; bool graphical = true;
    while (graphical) {
        long hub = -1;
        for (usz v = 0; v < n; v++) if (active[v] && residual[v] > 0 &&
            (hub < 0 || residual[v] > residual[(usz)hub] || (residual[v] == residual[(usz)hub] && (long)v < hub))) hub = (long)v;
        if (hub < 0) break;
        long d = residual[(usz)hub]; residual[(usz)hub] = 0; active[(usz)hub] = false;
        usz[MAX_N] candidates; usz count = 0;
        for (usz v = 0; v < n; v++) if (active[v]) candidates[count++] = v;
        for (usz i = 1; i < count; i++) {
            usz value = candidates[i]; usz j = i;
            while (j > 0 && (residual[candidates[j - 1]] < residual[value] ||
                (residual[candidates[j - 1]] == residual[value] && candidates[j - 1] > value))) { candidates[j] = candidates[j - 1]; j--; }
            candidates[j] = value;
        }
        if ((usz)d > count) { graphical = false; break; }
        for (long i = 0; i < d; i++) {
            usz neighbor = candidates[(usz)i]; if (residual[neighbor] == 0) { graphical = false; break; }
            residual[neighbor]--;
            edges[2 * edge_count] = hub < (long)neighbor ? hub : (long)neighbor;
            edges[2 * edge_count + 1] = hub < (long)neighbor ? (long)neighbor : hub;
            edge_count++;
        }
    }
    long[2 + 2 * MAX_EDGES] words; usz used = 0;
    if (graphical) { words[used++] = 1; words[used++] = (long)edge_count; for (usz i = 0; i < edge_count * 2; i++) words[used++] = edges[i]; }
    else { words[used++] = 0; }
    if (output == null || capacity < used * 8) return -2;
    for (usz i = 0; i < used; i++) put_i64(output, 8 * i, words[i]);
    return (long)(used * 8);
}
