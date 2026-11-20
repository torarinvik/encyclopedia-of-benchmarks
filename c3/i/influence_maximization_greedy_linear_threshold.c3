module influence_maximization_greedy_linear_threshold;

const int MAX_N = 8, MAX_M = 24, MAX_WORLDS = 8;
const int MAX_INPUT = 141, WEIGHT_SCALE = 256;

fn void put_i64(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[word * 8 + byte] = (char)((bits >> (8 * byte)) & 255);
    }
}

fn long reachable_count(int n, int world, int[64] parents, uint seeds) {
    int[MAX_N] queue = {0};
    uint reached = seeds;
    int head = 0, tail = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        if ((seeds & (1U << vertex)) != 0) queue[tail++] = vertex;
    }
    while (head < tail) {
        int source = queue[head++];
        for (int target = 0; target < n; target++) {
            uint bit = 1U << target;
            if (parents[world * MAX_N + target] == source && (reached & bit) == 0) {
                reached |= bit;
                queue[tail++] = target;
            }
        }
    }
    long count = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        if ((reached & (1U << vertex)) != 0) count++;
    }
    return count;
}

fn long influence_maximization_greedy_linear_threshold(long* input, usz input_length,
        char* output, usz output_capacity) @export("influence_maximization_greedy_linear_threshold") {
    if (input == null || input_length < 4 || input_length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1], k0 = input[2], worlds0 = input[3];
    if (n0 < 1 || n0 > MAX_N || m0 < 0 || m0 > MAX_M || k0 < 0 || k0 > n0
            || worlds0 < 1 || worlds0 > MAX_WORLDS) return -1;
    int n = (int)n0, m = (int)m0, k = (int)k0, worlds = (int)worlds0;
    if (input_length != (usz)(4 + 3 * m + worlds * n)) return -1;

    int[MAX_M] edge_u = {0}, edge_v = {0}, edge_weight = {0};
    int[MAX_N] incoming_sum = {0};
    for (int edge = 0; edge < m; edge++) {
        long u0 = input[4 + 3 * edge], v0 = input[5 + 3 * edge], weight0 = input[6 + 3 * edge];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0
                || weight0 < 0 || weight0 > WEIGHT_SCALE) return -1;
        for (int earlier = 0; earlier < edge; earlier++) {
            if (edge_u[earlier] == (int)u0 && edge_v[earlier] == (int)v0) return -1;
        }
        int u = (int)u0, v = (int)v0, weight = (int)weight0;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = weight;
        incoming_sum[v] += weight;
        if (incoming_sum[v] > WEIGHT_SCALE) return -1;
    }

    int[MAX_WORLDS * MAX_N] draws = {0};
    int draws_start = 4 + 3 * m;
    for (int world = 0; world < worlds; world++) {
        for (int vertex = 0; vertex < n; vertex++) {
            long draw = input[draws_start + world * n + vertex];
            if (draw < 0 || draw >= WEIGHT_SCALE) return -1;
            draws[world * MAX_N + vertex] = (int)draw;
        }
    }
    int[MAX_WORLDS * MAX_N] parents = {0};
    for (int world = 0; world < worlds; world++) {
        for (int target = 0; target < n; target++) {
            parents[world * MAX_N + target] = -1;
            int ticket = draws[world * MAX_N + target];
            int offset = 0;
            for (int edge = 0; edge < m; edge++) {
                if (edge_v[edge] != target) continue;
                int next_offset = offset + edge_weight[edge];
                if (offset <= ticket && ticket < next_offset) {
                    parents[world * MAX_N + target] = edge_u[edge];
                    break;
                }
                offset = next_offset;
            }
        }
    }

    int[MAX_N] chosen = {0};
    long[MAX_N] scores = {0};
    uint selected = 0;
    for (int round = 0; round < k; round++) {
        long[MAX_WORLDS] current = {0};
        for (int world = 0; world < worlds; world++) {
            current[world] = reachable_count(n, world, parents, selected);
        }
        int best_node = -1;
        long best_score = -1;
        for (int candidate = 0; candidate < n; candidate++) {
            uint bit = 1U << candidate;
            if ((selected & bit) != 0) continue;
            long score = 0;
            for (int world = 0; world < worlds; world++) {
                score += reachable_count(n, world, parents, selected | bit) - current[world];
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
        put_i64(output, (usz)(2 + 2 * round), scores[round]);
    }
    return (long)bytes;
}
