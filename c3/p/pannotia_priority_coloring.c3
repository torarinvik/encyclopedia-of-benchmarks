module pannotia_priority_coloring;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 147;
const long MAX_PRIORITY = 99999998;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long pannotia_priority_coloring(long* input, usz length, char* output, usz capacity)
        @export("pannotia_priority_coloring") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], mode64 = input[2];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M ||
        (mode64 != 0 && mode64 != 1) || length != 3 + (usz)n64 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    usz mode = (usz)mode64;
    ulong[MAX_N] adjacency = zeroed;
    usz[MAX_N] degree = zeroed;
    long[MAX_N] priority = zeroed;
    long[MAX_N] color = zeroed;
    bool[MAX_N] active = zeroed;
    for (usz v = 0; v < n; v += 1) {
        priority[v] = input[3 + v];
        if (priority[v] < 0 || priority[v] > MAX_PRIORITY) return -1;
        for (usz prior = 0; prior < v; prior += 1)
            if (priority[prior] == priority[v]) return -1;
        color[v] = -1;
        active[v] = true;
    }
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[3 + n + 2 * edge], v64 = input[4 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        ulong bit = 1 << v;
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        adjacency[v] |= 1 << u;
        degree[u] += 1;
        degree[v] += 1;
    }
    for (usz v = 0; v < n; v += 1) if (degree[v] == 1) return -1;
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    long current_color = 1;
    while (true) {
        bool[MAX_N] chosen = zeroed;
        usz chosen_count = 0;
        for (usz v = 0; v < n; v += 1) {
            if (!active[v]) continue;
            long maximum = -1, minimum = 99999999;
            for (usz u = 0; u < n; u += 1) if (active[u] && (adjacency[v] & (1 << u)) != 0) {
                if (priority[u] > maximum) maximum = priority[u];
                if (priority[u] < minimum) minimum = priority[u];
            }
            if (priority[v] > maximum) { color[v] = current_color; chosen[v] = true; }
            if (mode == 1 && priority[v] < minimum) { color[v] = current_color + 1; chosen[v] = true; }
            if (chosen[v]) chosen_count += 1;
        }
        if (chosen_count == 0) return -1;
        for (usz v = 0; v < n; v += 1) if (chosen[v]) active[v] = false;
        bool remaining = false;
        for (usz v = 0; v < n; v += 1) remaining = remaining || active[v];
        if (!remaining) break;
        current_color += mode == 1 ? 2 : 1;
    }
    for (usz v = 0; v < n; v += 1) store_i64_le(output, 8 * v, color[v]);
    return (long)output_bytes;
}
