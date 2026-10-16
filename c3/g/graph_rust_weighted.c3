module graph_rust_weighted;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 256;

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long graph_rust_weighted(long* input, usz length, char* output, usz capacity) @export("graph_rust_weighted") {
    if (input == null || length < 2) return -1;
    long nv = input[0], mv = input[1];
    if (nv < 0 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES || length != 2 + 3 * (usz)mv) return -1;
    int n = (int)nv, m = (int)mv;
    for (int edge = 0; edge < m; edge++) {
        long u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u < 0 || u >= nv || v < 0 || v >= nv || weight < -2147483648 || weight > 2147483647) return -1;
    }
    usz required = (1 + (usz)n + 4 * (usz)m) * 8;
    if (output == null || capacity < required) return -2;
    usz cursor = 0;
    put_i64(output, cursor++ * 8, nv);
    for (int vertex = 0; vertex < n; vertex++) {
        usz degree = 0;
        for (int edge = 0; edge < m; edge++) {
            if (input[2 + 3 * edge] == vertex) degree++;
            if (input[3 + 3 * edge] == vertex) degree++;
        }
        put_i64(output, cursor++ * 8, (long)degree);
        for (int edge = 0; edge < m; edge++) {
            long u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
            if (u == vertex) {
                put_i64(output, cursor++ * 8, v);
                put_i64(output, cursor++ * 8, weight);
            }
            if (v == vertex) {
                put_i64(output, cursor++ * 8, u);
                put_i64(output, cursor++ * 8, weight);
            }
        }
    }
    return (long)required;
}
