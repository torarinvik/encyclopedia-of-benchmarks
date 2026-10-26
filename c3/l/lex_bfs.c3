module lex_bfs;

const usz MAX_N = 16;
const usz MAX_M = 120;
const usz MAX_INPUT = 243;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long lex_bfs(long* input, usz length, char* output, usz capacity) @export("lex_bfs") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1], start64 = input[2];
    if (n64 < 1 || n64 > (long)MAX_N || m64 < 0 || m64 > (long)MAX_M ||
        start64 < 0 || start64 >= n64 || length != 3 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64, start = (usz)start64;
    bool[MAX_N][MAX_N] adjacency = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[3 + 2 * edge], v64 = input[4 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_N][MAX_N] labels = zeroed;
    long[MAX_N] order = zeroed;
    usz[MAX_N] label_len = zeroed;
    bool[MAX_N] selected = zeroed;
    usz current = start;
    for (usz step = 0; step < n; step += 1) {
        if (step > 0) {
            bool have_best = false;
            for (usz vertex = 0; vertex < n; vertex += 1) {
                if (selected[vertex]) continue;
                if (!have_best) { current = vertex; have_best = true; continue; }
                usz shared = label_len[vertex] < label_len[current]
                    ? label_len[vertex] : label_len[current];
                usz position = 0;
                bool decided = false;
                while (position < shared) {
                    if (labels[vertex][position] != labels[current][position]) {
                        if (labels[vertex][position] > labels[current][position]) current = vertex;
                        decided = true;
                        break;
                    }
                    position += 1;
                }
                if (!decided && (label_len[vertex] > label_len[current] ||
                    (label_len[vertex] == label_len[current] && vertex < current))) current = vertex;
            }
        }
        selected[current] = true;
        order[step] = (long)current;
        for (usz neighbor = 0; neighbor < n; neighbor += 1) {
            if (!adjacency[current][neighbor] || selected[neighbor]) continue;
            for (usz position = label_len[neighbor]; position > 0; position -= 1)
                labels[neighbor][position] = labels[neighbor][position - 1];
            labels[neighbor][0] = (long)step;
            label_len[neighbor] += 1;
        }
    }
    for (usz index = 0; index < n; index += 1) store_i64_le(output, 8 * index, order[index]);
    return (long)output_bytes;
}
