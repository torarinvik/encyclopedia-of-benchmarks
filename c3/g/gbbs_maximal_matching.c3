module gbbs_maximal_matching;

const usz MAX_N = 16;
const usz MAX_M = 64;
const usz MAX_INPUT = 194;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long gbbs_maximal_matching(long* input, usz length, char* output, usz capacity)
        @export("gbbs_maximal_matching") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M ||
        length != 2 + 3 * (usz)m64) return -1;
    usz m = (usz)m64, edge_start = 2 + (usz)m64;
    bool[MAX_M] rank_seen = zeroed;
    usz[MAX_M] order = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long rank64 = input[2+edge];
        if (rank64 < 0 || rank64 >= (long)m) return -1;
        usz rank = (usz)rank64;
        if (rank_seen[rank]) return -1;
        rank_seen[rank] = true;
        order[rank] = edge;
        long u64 = input[edge_start+2*edge], v64 = input[edge_start+2*edge+1];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        for (usz prior = 0; prior < edge; prior += 1)
            if (input[edge_start+2*prior] == u64 &&
                input[edge_start+2*prior+1] == v64) return -1;
    }
    usz output_bytes = 8*m;
    if (output == null || capacity < output_bytes) return -2;
    bool[MAX_N] matched = zeroed;
    long[MAX_M] selected = zeroed;
    usz rank = 0;
    while (rank < m) {
        usz edge = order[rank];
        usz u = (usz)input[edge_start+2*edge], v = (usz)input[edge_start+2*edge+1];
        if (!matched[u] && !matched[v]) {
            selected[edge] = 1;
            matched[u] = true;
            matched[v] = true;
        }
        rank += 1;
    }
    for (usz edge = 0; edge < m; edge += 1) store_i64_le(output, 8*edge, selected[edge]);
    return (long)output_bytes;
}
