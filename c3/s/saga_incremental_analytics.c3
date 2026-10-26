module saga_incremental_analytics;

const usz MAX_N = 8;
const usz MAX_E = 28;
const usz MAX_INPUT = 5 + MAX_N + 3 * MAX_E;
const long INF_VALUE = 1000000000;

fn void push_once(usz vertex, usz* queue, usz* count, bool* seen) {
    if (!seen[vertex]) { seen[vertex] = true; queue[count[0]] = vertex; count[0] += 1; }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long saga_incremental_analytics(long* input, usz length, char* output, usz capacity)
        @export("saga_incremental_analytics") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long mode64 = input[0], n64 = input[1], base64 = input[2], added64 = input[3], source64 = input[4];
    if (mode64 < 1 || mode64 > 6 || n64 < 2 || n64 > (long)MAX_N || base64 < 0 || added64 < 1 ||
        base64 + added64 > (long)MAX_E || length != 5 + (usz)n64 + 3 * (usz)(base64 + added64)) return -1;
    usz mode = (usz)mode64, n = (usz)n64, base_edges = (usz)base64, edge_count = (usz)(base64 + added64);
    if (mode == 1 || mode == 2 || mode == 5) {
        if (source64 < 0 || source64 >= n64) return -1;
    } else if (source64 != -1) return -1;

    long[MAX_N] property = zeroed;
    for (usz v = 0; v < n; v += 1) {
        long value = input[5 + v];
        if (mode == 1 && (value < -1 || value >= n64)) return -1;
        if ((mode == 2 || mode == 5) && (value < -1 || value > INF_VALUE)) return -1;
        if (mode == 3 && (value < -1 || value > 1000000)) return -1;
        if ((mode == 4 || mode == 6) && (value < -1 || value >= n64)) return -1;
        property[v] = value;
    }
    usz[MAX_N][MAX_N] neighbors = zeroed;
    long[MAX_N][MAX_N] weights = zeroed;
    usz[MAX_N] degree = zeroed;
    bool[MAX_N][MAX_N] edge_seen = zeroed;
    bool[MAX_N] affected = zeroed;
    usz edge_start = 5 + n;
    for (usz edge = 0; edge < edge_count; edge += 1) {
        usz pos = edge_start + 3 * edge;
        long u64 = input[pos], v64 = input[pos + 1], w = input[pos + 2];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || w < 1 || w > 9) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (edge_seen[u][v]) return -1;
        edge_seen[u][v] = true; edge_seen[v][u] = true;
        neighbors[u][degree[u]] = v; weights[u][degree[u]] = w; degree[u] += 1;
        neighbors[v][degree[v]] = u; weights[v][degree[v]] = w; degree[v] += 1;
        if (edge >= base_edges) { affected[u] = true; affected[v] = true; }
    }
    if (mode == 3) for (usz v = 0; v < n; v += 1) if (degree[v] == 0) return -1;
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    if (mode == 1 && property[(usz)source64] == -1) property[(usz)source64] = 0;
    if (mode == 2 || mode == 5) for (usz v = 0; v < n; v += 1) if (property[v] == -1)
        property[v] = v == (usz)source64 ? (mode == 2 ? 0 : INF_VALUE) : (mode == 2 ? INF_VALUE : 0);
    if (mode == 4 || mode == 6) for (usz v = 0; v < n; v += 1) if (property[v] == -1) property[v] = (long)v;

    if (mode == 3) {
        float damping = 0.85f;
        float base = (1.0f - damping) / (float)n;
        float[MAX_N] rank = zeroed, contribution = zeroed;
        for (usz v = 0; v < n; v += 1) {
            rank[v] = property[v] == -1 ? 1.0f / (float)n : (float)property[v] / 1000000.0f;
            contribution[v] = rank[v] / (float)degree[v];
        }
        usz[MAX_N] queue = zeroed;
        usz count = 0;
        bool[MAX_N] seen = zeroed;
        for (usz v = 0; v < n; v += 1) if (affected[v]) {
            float incoming = 0.0f;
            for (usz j = 0; j < degree[v]; j += 1) incoming += contribution[neighbors[v][j]];
            float old = rank[v]; rank[v] = base + damping * incoming;
            float difference = rank[v] - old;
            if (difference < 0.0f) difference = -difference;
            if (difference > 1.0e-7f)
                for (usz j = 0; j < degree[v]; j += 1) push_once(neighbors[v][j], &queue[0], &count, &seen[0]);
        }
        usz rounds = 0;
        while (count != 0) {
            rounds += 1; if (rounds > 256) return -1;
            for (usz v = 0; v < n; v += 1) contribution[v] = rank[v] / (float)degree[v];
            usz[MAX_N] current = queue;
            usz current_count = count;
            count = 0; seen = zeroed;
            for (usz q = 0; q < current_count; q += 1) {
                usz v = current[q];
                float incoming = 0.0f;
                for (usz j = 0; j < degree[v]; j += 1) incoming += contribution[neighbors[v][j]];
                float old = rank[v]; rank[v] = base + damping * incoming;
                float difference = rank[v] - old;
                if (difference < 0.0f) difference = -difference;
                if (difference > 1.0e-7f)
                    for (usz j = 0; j < degree[v]; j += 1) push_once(neighbors[v][j], &queue[0], &count, &seen[0]);
            }
        }
        for (usz v = 0; v < n; v += 1) property[v] = (long)(rank[v] * 1000000.0f + 0.5f);
    } else {
        usz[MAX_N] active = zeroed;
        usz active_count = 0;
        for (usz v = 0; v < n; v += 1) if (affected[v]) { active[active_count] = v; active_count += 1; }
        bool first = true;
        usz rounds = 0;
        while (active_count != 0) {
            rounds += 1; if (rounds > 256) return -1;
            usz[MAX_N] next = zeroed;
            usz next_count = 0;
            bool[MAX_N] seen = zeroed;
            for (usz a = 0; a < active_count; a += 1) {
                usz v = active[a]; long old = property[v];
                long candidate = (mode == 1 || mode == 2 || mode == 4) ? INF_VALUE : 0;
                if (mode == 1) for (usz j = 0; j < degree[v]; j += 1) {
                    long p = property[neighbors[v][j]]; if (p != -1 && p + 1 < candidate) candidate = p + 1;
                }
                else if (mode == 2) for (usz j = 0; j < degree[v]; j += 1) {
                    long p = property[neighbors[v][j]] + weights[v][j]; if (p < candidate) candidate = p;
                }
                else if (mode == 4) { candidate = old; for (usz j = 0; j < degree[v]; j += 1) candidate = min(candidate, property[neighbors[v][j]]); }
                else if (mode == 5) for (usz j = 0; j < degree[v]; j += 1) candidate = max(candidate, min(property[neighbors[v][j]], weights[v][j]));
                else { candidate = old; for (usz j = 0; j < degree[v]; j += 1) candidate = max(candidate, property[neighbors[v][j]]); }
                bool changed = mode == 1 ? candidate != INF_VALUE && (old == -1 || candidate < old)
                    : mode == 2 ? candidate < old && candidate != INF_VALUE
                    : mode == 4 ? candidate < old || (first && old == (long)v)
                    : mode == 5 ? candidate > old
                    : candidate > old || (first && old == (long)v);
                if (changed) {
                    property[v] = candidate;
                    if (mode == 1) {
                        for (usz j = 0; j < degree[v]; j += 1) {
                            usz u = neighbors[v][j];
                            long update = property[v] + 1;
                            if (property[u] == -1 || update < property[u]) {
                                property[u] = update;
                                push_once(u, &next[0], &next_count, &seen[0]);
                            }
                        }
                    } else {
                        for (usz j = 0; j < degree[v]; j += 1) push_once(neighbors[v][j], &next[0], &next_count, &seen[0]);
                    }
                }
            }
            active = next; active_count = next_count; first = false;
        }
    }
    for (usz v = 0; v < n; v += 1) store_i64_le(output, 8 * v, property[v]);
    return (long)output_bytes;
}
