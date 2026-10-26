// Clean-room bounded GARDENIA Forward-Backward-Trim SCC profile.
module gardenia_fb_trim_scc;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 130;
const usz MAX_TASKS = 34;

fn u64 reach(u64 active, usz pivot, u8* adjacent, bool reverse, usz n) {
    u64 seen = (u64)1 << pivot;
    while (true) {
        u64 expanded = seen;
        for (usz u = 0; u < n; u += 1) {
            u64 ub = (u64)1 << u;
            if (!(seen & ub) || !(active & ub)) continue;
            for (usz v = 0; v < n; v += 1) {
                u64 vb = (u64)1 << v;
                bool edge = reverse ? adjacent[v * MAX_N + u] != 0
                                    : adjacent[u * MAX_N + v] != 0;
                if ((active & vb) && edge) expanded |= vb;
            }
        }
        if (expanded == seen) return seen;
        seen = expanded;
    }
}

fn void store_i64_le(char* output, usz offset, i64 value) {
    u64 bits = (u64)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn i64 gardenia_fb_trim_scc(i64* input, usz length, char* output, usz capacity)
        @export("gardenia_fb_trim_scc") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    i64 n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    u8[MAX_N * MAX_N] adjacent = zeroed;
    for (usz e = 0; e < m; e += 1) {
        i64 u64 = input[2 + 2 * e], v64 = input[3 + 2 * e];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacent[u * MAX_N + v] != 0) return -1;
        adjacent[u * MAX_N + v] = 1;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    i64[MAX_N] labels = zeroed;
    u64[MAX_TASKS] tasks = zeroed;
    usz task_count = 1;
    tasks[0] = ((u64)1 << n) - 1;
    while (task_count > 0) {
        task_count -= 1;
        u64 active = tasks[task_count];
        while (active != 0) {
            u64 trimmed = 0;
            for (usz u = 0; u < n; u += 1) {
                u64 ub = (u64)1 << u;
                if (!(active & ub)) continue;
                bool has_in = false, has_out = false;
                for (usz v = 0; v < n; v += 1) {
                    if (!(active & ((u64)1 << v))) continue;
                    has_out = has_out || adjacent[u * MAX_N + v] != 0;
                    has_in = has_in || adjacent[v * MAX_N + u] != 0;
                }
                if (!has_in || !has_out) trimmed |= ub;
            }
            if (trimmed == 0) break;
            for (usz u = 0; u < n; u += 1)
                if (trimmed & ((u64)1 << u)) labels[u] = (i64)u;
            active &= ~trimmed;
        }
        if (active == 0) continue;
        usz pivot = 0;
        while (!(active & ((u64)1 << pivot))) pivot += 1;
        u64 forward = reach(active, pivot, &adjacent[0], false, n);
        u64 backward = reach(active, pivot, &adjacent[0], true, n);
        u64 component = forward & backward;
        usz representative = 0;
        while (!(component & ((u64)1 << representative))) representative += 1;
        for (usz u = 0; u < n; u += 1)
            if (component & ((u64)1 << u)) labels[u] = (i64)representative;
        u64[3] children = {active & ~(forward | backward), forward & ~backward, backward & ~forward};
        for (usz child = 0; child < 3; child += 1) if (children[child] != 0) {
            if (task_count >= MAX_TASKS) return -1;
            tasks[task_count] = children[child];
            task_count += 1;
        }
    }
    for (usz u = 0; u < n; u += 1) store_i64_le(output, 8 * u, labels[u]);
    return (i64)output_bytes;
}
