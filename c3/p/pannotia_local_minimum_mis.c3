module pannotia_local_minimum_mis;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 146;
const long MAX_PRIORITY = 99999998;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long pannotia_local_minimum_mis(long* input, usz length, char* output, usz capacity)
        @export("pannotia_local_minimum_mis") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M ||
        length != 2 + (usz)n64 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    ulong[MAX_N] adjacency = zeroed;
    long[MAX_N] priority = zeroed;
    for (usz v = 0; v < n; v += 1) {
        priority[v] = input[2 + v];
        if (priority[v] < 0 || priority[v] > MAX_PRIORITY) return -1;
        for (usz prior = 0; prior < v; prior += 1)
            if (priority[prior] == priority[v]) return -1;
    }
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + n + 2 * edge], v64 = input[3 + n + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        ulong bit = 1 << v;
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        adjacency[v] |= 1 << u;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    bool[MAX_N] active = zeroed;
    bool[MAX_N] selected = zeroed;
    for (usz v = 0; v < n; v += 1) active[v] = true;
    while (true) {
        bool[MAX_N] chosen = zeroed;
        usz chosen_count = 0;
        for (usz v = 0; v < n; v += 1) {
            if (!active[v]) continue;
            bool local_minimum = true;
            for (usz u = 0; u < n; u += 1)
                if (active[u] && (adjacency[v] & (1 << u)) != 0 && priority[u] < priority[v]) local_minimum = false;
            if (local_minimum) { chosen[v] = true; chosen_count += 1; }
        }
        if (chosen_count == 0) return -1;
        for (usz v = 0; v < n; v += 1) if (chosen[v]) { selected[v] = true; active[v] = false; }
        for (usz v = 0; v < n; v += 1) if (chosen[v])
            for (usz u = 0; u < n; u += 1)
                if (active[u] && (adjacency[v] & (1 << u)) != 0) active[u] = false;
        bool remaining = false;
        for (usz v = 0; v < n; v += 1) remaining = remaining || active[v];
        if (!remaining) break;
    }
    for (usz v = 0; v < n; v += 1) store_i64_le(output, 8 * v, selected[v] ? 2 : 0);
    return (long)output_bytes;
}
