module routing_cost_constrained_cds_goc_mcds_c;
const usz MAX_N = 8; const usz MAX_INPUT = 17; const usz MAX_OUTPUT = 16;

fn void put64(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { out[at + byte] = (char)(bits & 255); bits >>= 8; }
}

long routing_cost_constrained_cds_goc_mcds_c(long* input, usz length, char* output, usz capacity) @export("routing_cost_constrained_cds_goc_mcds_c") {
    if (input == null || length < 3 || length > MAX_INPUT || input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0]; if (length != 1 + 2 * n) return -1;
    ulong full = (1UL << n) - 1;
    ulong[MAX_N] adjacency = zeroed; long[MAX_N] ids = zeroed;
    for (usz v = 0; v < n; v += 1) {
        long mask = input[1 + v]; ids[v] = input[1 + n + v];
        if (mask < 0 || (ulong)mask > full || (((ulong)mask & (1UL << v)) != 0) || ids[v] < 1 || ids[v] > 1000) return -1;
        adjacency[v] = (ulong)mask;
        for (usz u = 0; u < v; u += 1) if (ids[u] == ids[v]) return -1;
    }
    for (usz u = 0; u < n; u += 1) for (usz v = 0; v < n; v += 1)
        if (((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1)) return -1;
    ulong reached = 1;
    while (true) { ulong expanded = reached; for (usz v = 0; v < n; v += 1) if (((reached >> v) & 1) != 0) expanded |= adjacency[v]; if (expanded == reached) break; reached = expanded; }
    if (reached != full) return -1;
    ulong white = full, independent = 0;
    while (white != 0) {
        ulong black = 0;
        for (usz v = 0; v < n; v += 1) {
            if (((white >> v) & 1) == 0) continue;
            bool lower = false;
            for (usz u = 0; u < n; u += 1) if (((white >> u) & 1) != 0 && ((adjacency[v] >> u) & 1) != 0 && ids[u] < ids[v]) lower = true;
            if (!lower) black |= 1UL << v;
        }
        if (black == 0) return -1;
        independent |= black; ulong removed = black;
        for (usz v = 0; v < n; v += 1) if (((black >> v) & 1) != 0) removed |= adjacency[v];
        white &= ~removed;
    }
    usz[MAX_N] order = zeroed;
    for (usz i = 0; i < n; i += 1) { usz j = i; order[i] = i; while (j > 0 && ids[order[j - 1]] > ids[order[j]]) { usz temp = order[j - 1]; order[j - 1] = order[j]; order[j] = temp; j -= 1; } }
    ulong connectors = 0;
    for (usz a = 0; a < n; a += 1) {
        usz source = order[a]; if (((independent >> source) & 1) == 0) continue;
        for (usz b = a + 1; b < n; b += 1) {
            usz target = order[b]; if (((independent >> target) & 1) == 0) continue;
            long[MAX_N] parent; for (usz v = 0; v < n; v += 1) parent[v] = -2;
            usz[MAX_N] queue = zeroed; usz head = 0, tail = 0; parent[source] = -1; queue[tail++] = source;
            while (head < tail && parent[target] == -2) { usz current = queue[head++]; for (usz oi = 0; oi < n; oi += 1) { usz next = order[oi]; if (((adjacency[current] >> next) & 1) != 0 && parent[next] == -2) { parent[next] = (long)current; queue[tail++] = next; } } }
            if (parent[target] == -2) return -1;
            usz[MAX_N] path = zeroed; usz path_length = 0, current = target;
            while (current != source) { path[path_length++] = current; current = (usz)parent[current]; }
            path[path_length++] = source;
            if (path_length <= 4) for (usz i = 1; i + 1 < path_length; i += 1) connectors |= 1UL << path[i];
        }
    }
    if (output == null || capacity < MAX_OUTPUT) return -2;
    char[MAX_OUTPUT] staged = zeroed; put64(&staged[0], 0, (long)independent); put64(&staged[0], 8, (long)(independent | connectors));
    for (usz i = 0; i < MAX_OUTPUT; i += 1) output[i] = staged[i];
    return (long)MAX_OUTPUT;
}
