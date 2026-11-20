module bondy_chvatal_hamiltonian_closure;

const MAX_VERTICES = 8;
const MAX_EDGES = 28;
const MAX_INPUT_WORDS = 59;
const MAX_OUTPUT_WORDS = 10;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long bondy_chvatal_hamiltonian_closure(long* input, usz length,
        char* output, usz capacity) @export("bondy_chvatal_hamiltonian_closure") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    long n_word = input[0], m_word = input[1];
    if (n_word < 3 || n_word > MAX_VERTICES || m_word < 0 || m_word > MAX_EDGES) return -1;
    int n = (int)n_word, m = (int)m_word;
    if (m > n * (n - 1) / 2 || length != (usz)(2 + 2 * m)) return -1;

    bool[MAX_VERTICES][MAX_VERTICES] adjacency = zeroed;
    for (int edge = 0; edge < m; edge++) {
        long u_word = input[2 + 2 * edge], v_word = input[3 + 2 * edge];
        if (u_word < 0 || u_word >= n_word || v_word < 0 || v_word >= n_word || u_word == v_word) return -1;
        int u = (int)u_word, v = (int)v_word;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
    }

    int added = 0;
    while (true) {
        int[MAX_VERTICES] degree = zeroed;
        for (int u = 0; u < n; u++)
            for (int v = 0; v < n; v++) if (adjacency[u][v]) degree[u]++;
        int chosen_u = n, chosen_v = n;
        for (int u = 0; u < n; u++) {
            if (chosen_u < n) break;
            for (int v = u + 1; v < n; v++) {
                if (!adjacency[u][v] && degree[u] + degree[v] >= n) {
                    chosen_u = u;
                    chosen_v = v;
                    break;
                }
            }
        }
        if (chosen_u == n) break;
        adjacency[chosen_u][chosen_v] = true;
        adjacency[chosen_v][chosen_u] = true;
        added++;
    }

    long[MAX_OUTPUT_WORDS] staged = zeroed;
    int full_mask = (1 << n) - 1;
    bool complete = true;
    for (int u = 0; u < n; u++) {
        int row = 0;
        for (int v = 0; v < n; v++) if (adjacency[u][v]) row |= 1 << v;
        staged[2 + u] = row;
        if (row != (full_mask ^ (1 << u))) complete = false;
    }
    if (complete) staged[0] = 1;
    staged[1] = added;

    usz output_bytes = (usz)(2 + n) * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < (usz)(2 + n); word++) store_i64_le(output, word * 8, staged[word]);
    return (long)output_bytes;
}
