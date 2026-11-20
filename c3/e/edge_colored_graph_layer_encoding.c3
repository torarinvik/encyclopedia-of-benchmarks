module edge_colored_graph_layer_encoding;
const usz MAX_N = 8; const usz MAX_M = 28; const usz MAX_D = 3;
const usz MAX_INPUT = 97; const usz MAX_VERTICES = 24;

fn void put_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long edge_colored_graph_layer_encoding(long* input, usz length,
        char* output, usz capacity) @export("edge_colored_graph_layer_encoding") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1], d0 = input[2], q0 = input[3];
    if (n0 < 1 || n0 > 8 || m0 < 0 || m0 > 28 || d0 < 1 || d0 > 3 || q0 < 1 || q0 > 3) return -1;
    usz n = (usz)n0, m = (usz)m0, layers = (usz)d0, classes = (usz)q0;
    usz edge_offset = 4 + n;
    if (length != edge_offset + 3 * m) return -1;
    long[MAX_N] vertex_colors = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        vertex_colors[vertex] = input[4 + vertex];
        if (vertex_colors[vertex] < 0 || vertex_colors[vertex] >= q0) return -1;
    }
    u8[MAX_N * MAX_N] source_colors = zeroed;
    usz offset = edge_offset;
    for (usz edge = 0; edge < m; edge += 1) {
        long u0 = input[offset], v0 = input[offset + 1], color0 = input[offset + 2];
        offset += 3;
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || color0 < 1 || color0 >= (1L << d0)) return -1;
        usz u = (usz)u0, v = (usz)v0;
        if (u > v) { usz temp = u; u = v; v = temp; }
        usz index = u * MAX_N + v;
        if (source_colors[index] != 0) return -1;
        source_colors[index] = (u8)color0;
    }

    usz nodes = n * layers;
    bool[MAX_VERTICES * MAX_VERTICES] adjacency = zeroed;
    for (usz layer = 0; layer < layers; layer += 1) {
        u8 bit = (u8)(1 << layer);
        for (usz u = 0; u < n; u += 1)
            for (usz v = u + 1; v < n; v += 1)
                if ((source_colors[u * MAX_N + v] & bit) != 0)
                    adjacency[(layer * n + u) * MAX_VERTICES + layer * n + v] = true;
    }
    for (usz vertex = 0; vertex < n; vertex += 1)
        for (usz layer = 0; layer + 1 < layers; layer += 1)
            adjacency[(layer * n + vertex) * MAX_VERTICES + (layer + 1) * n + vertex] = true;
    usz count = 0;
    for (usz u = 0; u < nodes; u += 1)
        for (usz v = u + 1; v < nodes; v += 1)
            if (adjacency[u * MAX_VERTICES + v]) count += 1;
    usz bytes = 8 * (2 + nodes + 2 * count);
    if (output == null || capacity < bytes) return -2;
    put_le(output, 0, (long)nodes);
    put_le(output, 8, (long)count);
    usz word = 2;
    for (usz layer = 0; layer < layers; layer += 1)
        for (usz vertex = 0; vertex < n; vertex += 1) {
            put_le(output, 8 * word, (long)(layer * classes + (usz)vertex_colors[vertex]));
            word += 1;
        }
    for (usz u = 0; u < nodes; u += 1)
        for (usz v = u + 1; v < nodes; v += 1)
            if (adjacency[u * MAX_VERTICES + v]) {
                put_le(output, 8 * word, (long)u); word += 1;
                put_le(output, 8 * word, (long)v); word += 1;
            }
    return (long)bytes;
}
