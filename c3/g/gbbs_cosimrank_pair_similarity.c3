module gbbs_cosimrank_pair_similarity;

const usz MAX_N = 8;
const usz MAX_M = 24;
const usz MAX_INPUT = 53;

fn void store_scaled_binary64(char* output, uint numerator) {
    ulong bits = 0;
    if (numerator != 0) {
        usz high = 0;
        while ((numerator >> (high + 1)) != 0) high += 1;
        ulong exponent = (ulong)(1003 + high);
        ulong significand = (ulong)numerator << (52 - high);
        bits = (exponent << 52) | (significand & (((ulong)1 << 52) - 1));
    }
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room exact dyadic projection of GBBS CoSimRank; see package LICENSE.txt.
long gbbs_cosimrank_pair_similarity(long* input, usz length, char* output, usz capacity)
        @export("gbbs_cosimrank_pair_similarity") {
    if (input == null || length < 5 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], u64 = input[2], v64 = input[3], iterations64 = input[4];
    if (n64 < 1 || n64 > 8 || m64 < 0 || m64 > 24 || u64 < 0 || u64 >= n64 ||
        v64 < 0 || v64 >= n64 || iterations64 < 1 || iterations64 > 4 ||
        length != 5 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, source_u = (usz)u64, source_v = (usz)v64;
    usz[MAX_M] edge_from = zeroed, edge_to = zeroed;
    usz[MAX_N] degree = zeroed;
    bool[MAX_N * MAX_N] seen = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long from64 = input[5 + 2 * edge], to64 = input[6 + 2 * edge];
        if (from64 < 0 || from64 >= n64 || to64 < 0 || to64 >= n64 || from64 == to64) return -1;
        usz from = (usz)from64, to = (usz)to64;
        if (seen[from * MAX_N + to]) return -1;
        seen[from * MAX_N + to] = true;
        edge_from[edge] = from; edge_to[edge] = to; degree[from] += 1;
    }
    for (usz vertex = 0; vertex < n; vertex += 1)
        if (degree[vertex] != 0 && degree[vertex] != 1 && degree[vertex] != 2 && degree[vertex] != 4) return -1;
    if (output == null || capacity < 8) return -2;
    uint[MAX_N] current_u = zeroed, current_v = zeroed, next_u = zeroed, next_v = zeroed;
    current_u[source_u] = 256; current_v[source_v] = 256;
    uint numerator = source_u == source_v ? ((uint)1 << 20) : 0;
    for (usz step = 0; step < (usz)iterations64; step += 1) {
        for (usz edge = 0; edge < m; edge += 1) {
            usz from = edge_from[edge], to = edge_to[edge];
            next_u[to] += current_u[from] / (uint)degree[from];
            next_v[to] += current_v[from] / (uint)degree[from];
        }
        uint dot = 0;
        for (usz vertex = 0; vertex < n; vertex += 1) dot += next_u[vertex] * next_v[vertex];
        numerator += dot << (3 - step);
        for (usz vertex = 0; vertex < n; vertex += 1) {
            current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex];
            next_u[vertex] = 0; next_v[vertex] = 0;
        }
    }
    store_scaled_binary64(output, numerator);
    return 8;
}
