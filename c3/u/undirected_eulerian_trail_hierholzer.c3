module undirected_eulerian_trail_hierholzer;

fn long undirected_eulerian_trail_hierholzer(long* input, usz length, char* output, usz capacity)
    @export("undirected_eulerian_trail_hierholzer") {
    if (input == null || length < 2 || length > 67 || input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 32) return -1;
    usz n = (usz)input[0]; usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;
    usz[2][32] endpoints = zeroed;
    usz[64][16] adjacency = zeroed;
    usz[16] degree = zeroed; usz[16] cursor = zeroed;
    for (usz e = 0; e < m; e++) {
        long u0 = input[2 + 2 * e]; long v0 = input[3 + 2 * e];
        if (u0 < 0 || v0 < 0 || u0 >= (long)n || v0 >= (long)n) return -1;
        usz u = (usz)u0; usz v = (usz)v0;
        endpoints[e][0] = u; endpoints[e][1] = v;
        adjacency[u][degree[u]++] = e; adjacency[v][degree[v]++] = e;
    }
    usz odd = 0; usz start = 0;
    for (usz v = 0; v < n; v++) if (degree[v] % 2 != 0) { if (odd == 0) start = v; odd++; }
    if (odd != 0 && odd != 2) return 0;
    if (odd == 0 && m != 0) while (degree[start] == 0) start++;
    bool[32] used = zeroed; usz[33] stack = zeroed; usz[33] reverse = zeroed;
    usz top = 1; usz count = 0; stack[0] = start;
    while (top != 0) {
        usz v = stack[top - 1];
        while (cursor[v] < degree[v] && used[adjacency[v][cursor[v]]]) cursor[v]++;
        if (cursor[v] == degree[v]) reverse[count++] = stack[--top];
        else {
            usz e = adjacency[v][cursor[v]++]; used[e] = true;
            stack[top++] = endpoints[e][0] == v ? endpoints[e][1] : endpoints[e][0];
        }
    }
    if (count != m + 1) return 0;
    usz bytes = count * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < count; i++) {
        ulong value = (ulong)reverse[count - 1 - i];
        for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)(value >> (8 * b));
    }
    return (long)bytes;
}
