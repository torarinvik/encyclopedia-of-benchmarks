module incremental_minimum_spanning_forest;

fn long incremental_minimum_spanning_forest(long* input, usz length, char* output, usz capacity)
    @export("incremental_minimum_spanning_forest") {
    if (input == null || length < 2 || length > 98) return -1;
    long n = input[0], raw_m = input[1];
    if (n < 1 || n > 16 || raw_m < 1 || raw_m > 32 || length != 2 + 3 * (usz)raw_m) return -1;
    usz m = (usz)raw_m;
    for (usz i = 0; i < m; i++) {
        long u = input[2+3*i], v = input[3+3*i], w = input[4+3*i];
        if (u < 0 || u >= n || v < 0 || v >= n || w < 1 || w > 1000000) return -1;
        for (usz j = 0; j < i; j++) if (input[4+3*j] == w) return -1;
    }
    char[32] active = zeroed; long[32] answers = zeroed;
    for (usz e = 0; e < m; e++) {
        usz start = (usz)input[2+3*e], target = (usz)input[3+3*e];
        if (start == target) { answers[e] = (long)e; continue; }
        long[16] parent = zeroed, edge_of = zeroed, queue = zeroed;
        for (usz i = 0; i < (usz)n; i++) parent[i] = -1;
        usz head = 0, tail = 1; parent[start] = (long)start; queue[0] = (long)start;
        while (head < tail) {
            usz vertex = (usz)queue[head++];
            for (usz i = 0; i < e; i++) {
                if (active[i] == 0) continue;
                usz u = (usz)input[2+3*i], v = (usz)input[3+3*i];
                long next = -1;
                if (u == vertex) next = (long)v; else if (v == vertex) next = (long)u;
                if (next >= 0 && parent[(usz)next] < 0) {
                    parent[(usz)next] = (long)vertex; edge_of[(usz)next] = (long)i;
                    queue[tail++] = next;
                }
            }
        }
        if (parent[target] < 0) { active[e] = 1; answers[e] = -1; continue; }
        usz node = target, heaviest = (usz)edge_of[node];
        while (node != start) {
            usz i = (usz)edge_of[node];
            if (input[4+3*i] > input[4+3*heaviest]) heaviest = i;
            node = (usz)parent[node];
        }
        if (input[4+3*e] < input[4+3*heaviest]) {
            active[heaviest] = 0; active[e] = 1; answers[e] = (long)heaviest;
        } else answers[e] = (long)e;
    }
    usz bytes = 8 * m;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < m; i++) {
        ulong bits = (ulong)answers[i];
        for (usz b = 0; b < 8; b++) output[8*i+b] = (char)(bits >> (8*b));
    }
    return (long)bytes;
}
