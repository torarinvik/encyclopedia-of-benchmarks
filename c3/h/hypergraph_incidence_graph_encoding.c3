module hypergraph_incidence_graph_encoding;
const usz MAX_N = 8; const usz MAX_M = 12; const usz MAX_INPUT = 111;

fn void put_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long hypergraph_incidence_graph_encoding(long* input, usz length,
                                             char* output, usz capacity)
    @export("hypergraph_incidence_graph_encoding") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 8 || m0 < 0 || m0 > 12) return -1;
    usz n = (usz)n0, m = (usz)m0;
    bool[MAX_N * MAX_M] incidence = zeroed;
    usz offset = 2;
    for (usz edge = 0; edge < m; edge += 1) {
        if (offset >= length) return -1;
        long size0 = input[offset];
        offset += 1;
        if (size0 < 0 || size0 > n0 || (usz)size0 > length - offset) return -1;
        for (usz item = 0; item < (usz)size0; item += 1) {
            long vertex0 = input[offset];
            offset += 1;
            if (vertex0 < 0 || vertex0 >= n0) return -1;
            usz vertex = (usz)vertex0;
            if (incidence[vertex * MAX_M + edge]) return -1;
            incidence[vertex * MAX_M + edge] = true;
        }
    }
    if (offset != length) return -1;

    usz count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1)
        for (usz edge = 0; edge < m; edge += 1)
            if (incidence[vertex * MAX_M + edge]) count += 1;
    usz nodes = n + m;
    usz bytes = 8 * (2 + nodes + 2 * count);
    if (output == null || capacity < bytes) return -2;
    put_le(output, 0, (long)nodes);
    put_le(output, 8, (long)count);
    usz word = 2;
    for (usz vertex = 0; vertex < n; vertex += 1) { put_le(output, 8 * word, 0); word += 1; }
    for (usz edge = 0; edge < m; edge += 1) { put_le(output, 8 * word, 1); word += 1; }
    for (usz vertex = 0; vertex < n; vertex += 1)
        for (usz edge = 0; edge < m; edge += 1)
            if (incidence[vertex * MAX_M + edge]) {
                put_le(output, 8 * word, (long)vertex); word += 1;
                put_le(output, 8 * word, (long)(n + edge)); word += 1;
            }
    return (long)bytes;
}
