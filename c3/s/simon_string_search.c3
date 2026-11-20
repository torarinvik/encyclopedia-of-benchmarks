module simon_string_search;

fn long simon_string_search(long* values, usz length) @export("simon_string_search") {
    if (values == null || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    usz n = (usz)values[0], m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    for (usz i = 0; i < n + m; i++) if (values[2 + i] < 0 || values[2 + i] > 15) return -2;
    usz p = 2 + n;
    int[16] head, target, next;
    for (usz i = 0; i < 16; i++) head[i] = -1;
    int edge_count = 0, ell = -1;
    for (usz i = 1; i < m; i++) {
        int k = ell;
        int cell = k < 0 ? -1 : head[(usz)k];
        ell = -1;
        if (values[p + i] == values[p + (usz)(k + 1)]) ell = k + 1;
        else {
            target[edge_count] = k + 1;
            next[edge_count] = head[i - 1];
            head[i - 1] = edge_count++;
        }
        while (cell >= 0) {
            int q = target[cell];
            if (values[p + i] == values[p + (usz)q]) ell = q;
            else {
                target[edge_count] = q;
                next[edge_count] = head[i - 1];
                head[i - 1] = edge_count++;
            }
            cell = next[cell];
        }
    }
    int state = -1;
    long matches = 0;
    for (usz j = 0; j < n; j++) {
        long symbol = values[2 + j];
        if (state < (int)m - 1 && values[p + (usz)(state + 1)] == symbol) state++;
        else if (state >= 0) {
            int edge = head[(usz)state];
            state = -1;
            while (edge >= 0) {
                int q = target[edge];
                if (values[p + (usz)q] == symbol) { state = q; break; }
                edge = next[edge];
            }
        } else state = -1;
        if (state >= (int)m - 1) { matches++; state = ell; }
    }
    return matches;
}
