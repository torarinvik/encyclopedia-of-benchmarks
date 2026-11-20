module influence_maximization_greedy_live_edge;

const int MAX_N = 8, MAX_M = 24, MAX_WORLDS = 8;

fn void put_i64(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[word * 8 + byte] = (char)((bits >> (8 * byte)) & 255);
    }
}

fn int reachable_count(int n, int m, int world, uint seeds,
        int[MAX_M] edge_u, int[MAX_M] edge_v, int[MAX_M] masks) {
    int[MAX_N] queue = {0};
    uint reached = seeds;
    int head = 0, tail = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        if ((seeds & (1U << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        int source = queue[head++];
        for (int edge = 0; edge < m; edge++) {
            int target = edge_v[edge];
            uint bit = 1U << target;
            if (edge_u[edge] == source && (masks[edge] & (1 << world)) != 0
                    && (reached & bit) == 0) {
                reached |= bit;
                queue[tail++] = target;
            }
        }
    }
    int count = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        if ((reached & (1U << vertex)) != 0) count++;
    }
    return count;
}

fn long influence_maximization_greedy_live_edge(long* input, usz input_length,
        char* output, usz output_capacity) @export("influence_maximization_greedy_live_edge") {
    if (input == null || input_length < 4 || input_length > 77) return -1;
    long n0 = input[0], m0 = input[1], k0 = input[2], worlds0 = input[3];
    if (n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M || k0 < 0 || k0 > n0
            || worlds0 < 1 || worlds0 > MAX_WORLDS
            || input_length != (usz)(4 + 3 * m0)) return -1;
    int n = (int)n0, m = (int)m0, k = (int)k0, worlds = (int)worlds0;
    int[MAX_M] edge_u = {0}, edge_v = {0}, masks = {0};
    int allowed = (1 << worlds) - 1;
    for (int edge = 0; edge < m; edge++) {
        long u = input[4 + 3 * edge], v = input[5 + 3 * edge], mask = input[6 + 3 * edge];
        if (u < 0 || u >= n0 || v < 0 || v >= n0 || u == v || mask < 0 || mask > allowed) return -1;
        for (int earlier = 0; earlier < edge; earlier++) {
            if (edge_u[earlier] == u && edge_v[earlier] == v) return -1;
        }
        edge_u[edge] = (int)u;
        edge_v[edge] = (int)v;
        masks[edge] = (int)mask;
    }
    int[MAX_N] chosen = {0}, scores = {0};
    uint selected = 0;
    for (int round = 0; round < k; round++) {
        int[MAX_WORLDS] current = {0};
        for (int world = 0; world < worlds; world++) {
            current[world] = reachable_count(n, m, world, selected, edge_u, edge_v, masks);
        }
        int best_node = -1, best_score = -1;
        for (int candidate = 0; candidate < n; candidate++) {
            uint bit = 1U << candidate;
            if ((selected & bit) != 0) continue;
            int score = 0;
            for (int world = 0; world < worlds; world++) {
                score += reachable_count(n, m, world, selected | bit, edge_u, edge_v, masks)
                        - current[world];
            }
            if (score > best_score) { best_node = candidate; best_score = score; }
        }
        if (best_node < 0) return -1;
        selected |= 1U << best_node;
        chosen[round] = best_node;
        scores[round] = best_score;
    }
    usz bytes = (usz)(1 + 2 * k) * 8;
    if (output == null || output_capacity < bytes) return -2;
    put_i64(output, 0, (long)k);
    for (int round = 0; round < k; round++) {
        put_i64(output, (usz)(1 + 2 * round), (long)chosen[round]);
        put_i64(output, (usz)(2 + 2 * round), (long)scores[round]);
    }
    return (long)bytes;
}
