module max_cut_gw_rounding;

const usz MAX_N = 16, MAX_M = 120, MAX_D = 4, MAX_INPUT = 431;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long max_cut_gw_rounding(long* input, usz length, char* output, usz capacity)
        @export("max_cut_gw_rounding") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], d64 = input[2];
    if (n64 < 2 || n64 > 16 || m64 < 0 || m64 > 120 || d64 < 1 || d64 > 4 ||
        length != 3 + 3 * (usz)m64 + (usz)n64 * (usz)d64 + (usz)d64) return -1;
    usz n = (usz)n64, m = (usz)m64, d = (usz)d64;
    long[MAX_M] edge_u = zeroed, edge_v = zeroed, edge_weight = zeroed;
    long previous_u = -1, previous_v = -1;
    for (usz edge = 0; edge < m; edge += 1) {
        long u = input[3 + 3 * edge], v = input[4 + 3 * edge], weight = input[5 + 3 * edge];
        if (u < 0 || v <= u || v >= n64 || weight < 1 || weight > 10000 ||
            u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        edge_u[edge] = u; edge_v[edge] = v; edge_weight[edge] = weight;
    }
    usz vector_offset = 3 + 3 * m;
    long[MAX_N][MAX_D] vectors = zeroed;
    long[MAX_D] normal = zeroed;
    long common_norm = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long norm = 0;
        for (usz axis = 0; axis < d; axis += 1) {
            long coordinate = input[vector_offset + vertex * d + axis];
            if (coordinate < -100 || coordinate > 100) return -1;
            vectors[vertex][axis] = coordinate;
            norm += coordinate * coordinate;
        }
        if (vertex == 0) common_norm = norm;
        else if (norm != common_norm) return -1;
    }
    if (common_norm == 0) return -1;
    bool has_normal = false;
    for (usz axis = 0; axis < d; axis += 1) {
        normal[axis] = input[vector_offset + n * d + axis];
        if (normal[axis] < -100 || normal[axis] > 100) return -1;
        if (normal[axis] != 0) has_normal = true;
    }
    if (!has_normal) return -1;
    usz output_bytes = 8 * (n + 1);
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_N] side = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        long projection = 0;
        for (usz axis = 0; axis < d; axis += 1) projection += vectors[vertex][axis] * normal[axis];
        if (projection > 0) side[vertex] = 1;
    }
    long cut = 0;
    for (usz edge = 0; edge < m; edge += 1)
        if (side[(usz)edge_u[edge]] != side[(usz)edge_v[edge]]) cut += edge_weight[edge];
    store_i64_le(output, 0, cut);
    for (usz vertex = 0; vertex < n; vertex += 1) store_i64_le(output, 8 * (vertex + 1), side[vertex]);
    return (long)output_bytes;
}
