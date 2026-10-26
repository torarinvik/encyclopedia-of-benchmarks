// Clean-room bounded GARDENIA Gebremedhin-Manne coloring profile.
module gardenia_gm_vertex_coloring;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 130;
const usz MAX_COLOR = 128;

fn void store_i64_le(char* output, usz offset, i64 value) {
    u64 bits = (u64)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn i64 gardenia_gm_vertex_coloring(i64* input, usz length, char* output, usz capacity)
        @export("gardenia_gm_vertex_coloring") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    i64 n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[MAX_N * MAX_N] adjacent = zeroed;
    for (usz e = 0; e < m; e += 1) {
        i64 u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    i64[MAX_N] colors = zeroed, prior = zeroed, pending = zeroed, next_pending = zeroed;
    usz pending_count = n;
    for (usz u = 0; u < n; u += 1) { colors[u] = 128; pending[u] = (i64)u; }
    usz rounds = 0;
    while (pending_count > 0) {
        rounds += 1;
        if (rounds > n + 1) return -1;
        for (usz u = 0; u < n; u += 1) prior[u] = colors[u];
        for (usz item = 0; item < pending_count; item += 1) {
            usz u = (usz)pending[item];
            bool[MAX_N] forbidden = zeroed;
            for (usz v = 0; v < n; v += 1)
                if (adjacent[u * MAX_N + v] && prior[v] != 128) forbidden[(usz)prior[v]] = true;
            usz color = 0;
            while (color < MAX_COLOR && forbidden[color]) color += 1;
            if (color >= MAX_COLOR) return -1;
            colors[u] = (i64)color;
        }
        usz next_count = 0;
        for (usz item = 0; item < pending_count; item += 1) {
            usz u = (usz)pending[item];
            bool conflict = false;
            for (usz v = u + 1; v < n; v += 1)
                if (adjacent[u * MAX_N + v] && colors[u] == colors[v]) { conflict = true; break; }
            if (conflict) { colors[u] = 128; next_pending[next_count] = (i64)u; next_count += 1; }
        }
        pending_count = next_count;
        for (usz item = 0; item < pending_count; item += 1) pending[item] = next_pending[item];
    }
    for (usz u = 0; u < n; u += 1) store_i64_le(output, 8 * u, colors[u]);
    return (i64)output_bytes;
}
