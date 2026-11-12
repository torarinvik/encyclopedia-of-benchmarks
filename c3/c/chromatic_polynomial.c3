module chromatic_polynomial;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 16;
const usz MAX_INPUT = 34;
fn void chromatic_poly(uint64* adjacency, usz n, long* result) {
    usz edge_u = n, edge_v = n;
    for (usz u = 0; u < n && edge_u == n; u += 1) {
        for (usz v = u + 1; v < n; v += 1) {
            if ((adjacency[u] & (1ul << v)) != 0) { edge_u = u; edge_v = v; break; }
        }
    }
    for (usz i = 0; i <= MAX_VERTICES; i += 1) result[i] = 0;
    if (edge_u == n) { result[n] = 1; return; }

    uint64[MAX_VERTICES] deleted = zeroed;
    for (usz i = 0; i < MAX_VERTICES; i += 1) deleted[i] = adjacency[i];
    deleted[edge_u] &= ~(1ul << edge_v);
    deleted[edge_v] &= ~(1ul << edge_u);
    long[MAX_VERTICES + 1] without_edge = zeroed;
    chromatic_poly(&deleted[0], n, &without_edge[0]);

    uint64[MAX_VERTICES] contracted = zeroed;
    for (usz left = 0; left < n; left += 1) {
        for (usz right = left + 1; right < n; right += 1) {
            if ((adjacency[left] & (1ul << right)) == 0 || (left == edge_u && right == edge_v)) continue;
            usz new_left = left == edge_v ? edge_u : left;
            usz new_right = right == edge_v ? edge_u : right;
            if (new_left > edge_v) new_left -= 1;
            if (new_right > edge_v) new_right -= 1;
            if (new_left == new_right) continue;
            contracted[new_left] |= 1ul << new_right;
            contracted[new_right] |= 1ul << new_left;
        }
    }
    long[MAX_VERTICES + 1] with_edge_contracted = zeroed;
    chromatic_poly(&contracted[0], n - 1, &with_edge_contracted[0]);
    for (usz degree = 0; degree <= n; degree += 1)
        result[degree] = without_edge[degree] - with_edge_contracted[degree];
}

fn void put64(char* output, usz offset, long value) {
    uint64 bits = (uint64)value;
    for (usz byte = 0; byte < 8; byte += 1) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long chromatic_polynomial(long* input, usz length, char* output, usz capacity)
    @export("chromatic_polynomial") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > (long)MAX_VERTICES || m_value < 0 || m_value > (long)MAX_EDGES) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;
    uint64[MAX_VERTICES] adjacency = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        if ((adjacency[u] & (1ul << v)) != 0) return -1;
        adjacency[u] |= 1ul << v;
        adjacency[v] |= 1ul << u;
    }
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;
    long[MAX_VERTICES + 1] coefficients = zeroed;
    chromatic_poly(&adjacency[0], n, &coefficients[0]);
    for (usz degree = 0; degree <= n; degree += 1) put64(output, 8 * degree, coefficients[degree]);
    return (long)bytes;
}
