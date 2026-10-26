module zdd_family_count;

fn void put_i64(uint8* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at * 8 + b] = (uint8)(bits >> (b * 8));
}

fn long zdd_family_count(long* input, usz length, uint8* output, usz capacity) @export("zdd_family_count") {
    if (input == null || length < 2 || length > 34) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 6 || m0 < 0 || m0 > 32 || length != (usz)(m0 + 2)) return -1;
    usz n = (usz)n0, m = (usz)m0, limit = (usz)1 << (usz)n0;
    long[64] ids; long[64] next; long[63] vars; long[63] lows; long[63] highs;
    long[65] counts; bool[64] seen;
    counts[1] = 1;
    for (usz i = 0; i < m; i++) {
        long mask = input[2 + i];
        if (mask < 0 || (usz)mask >= limit || seen[(usz)mask]) return -1;
        seen[(usz)mask] = true; ids[(usz)mask] = 1;
    }
    usz nodes = 0, current_count = limit;
    for (usz variable = 0; variable < n; variable++) {
        usz next_count = current_count / 2;
        for (usz p = 0; p < next_count; p++) {
            long low = ids[2 * p], high = ids[2 * p + 1];
            if (high == 0) { next[p] = low; continue; }
            usz found = nodes, j = nodes;
            while (j > 0) {
                j--;
                if ((usz)vars[j] != variable) break;
                if (lows[j] == low && highs[j] == high) { found = j; break; }
            }
            if (found == nodes) {
                vars[nodes] = (long)variable; lows[nodes] = low; highs[nodes] = high;
                counts[2 + nodes] = counts[(usz)low] + counts[(usz)high];
                next[p] = (long)(2 + nodes); nodes++;
            } else next[p] = (long)(2 + found);
        }
        for (usz p = 0; p < next_count; p++) ids[p] = next[p];
        current_count = next_count;
    }
    usz bytes = 8 * (3 + 3 * nodes);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, (long)nodes); put_i64(output, 2, counts[(usz)ids[0]]);
    for (usz i = 0; i < nodes; i++) {
        put_i64(output, 3 + 3 * i, vars[i]); put_i64(output, 4 + 3 * i, lows[i]); put_i64(output, 5 + 3 * i, highs[i]);
    }
    return (long)bytes;
}
