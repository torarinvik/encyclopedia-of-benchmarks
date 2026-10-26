module gapbs_shiloach_vishkin_components;

const usz MAX_N = 16;
const usz MAX_M = 64;

fn void compress_components(usz n, usz* component) {
    for (usz node = 0; node < n; node++)
        while (component[node] != component[component[node]])
            component[node] = component[component[node]];
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long gapbs_shiloach_vishkin_components(long* input, usz length, char* output, usz capacity)
    @export("gapbs_shiloach_vishkin_components") {
    if (input == null || length < 2 || length > 130) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M ||
        length != 2 + 2 * (usz)m_value) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    uint8[256] adjacency = {0};
    for (usz edge = 0; edge < m; edge++) {
        usz pos = 2 + 2 * edge;
        long u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n_value || adjacency[(usz)u * MAX_N + (usz)v] != 0) return -1;
        adjacency[(usz)u * MAX_N + (usz)v] = 1;
        adjacency[(usz)v * MAX_N + (usz)u] = 1;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    usz[16] component;
    for (usz node = 0; node < n; node++) component[node] = node;
    bool changed = true;
    usz rounds = 0, round_limit = n * n + 1;
    while (changed && rounds < round_limit) {
        changed = false;
        for (usz u = 0; u < n; u++) {
            for (usz v = 0; v < n; v++) {
                if (adjacency[u * MAX_N + v] == 0) continue;
                usz component_u = component[u], component_v = component[v];
                if (component_u == component_v) continue;
                usz high = component_u > component_v ? component_u : component_v;
                usz low = component_u + (component_v - high);
                if (component[high] == high) { changed = true; component[high] = low; }
            }
        }
        compress_components(n, &component[0]);
        rounds++;
    }
    if (changed) return -1;
    for (usz node = 0; node < n; node++) store_i64_le(output, 8 * node, (long)component[node]);
    return (long)output_bytes;
}
