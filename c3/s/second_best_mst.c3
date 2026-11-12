module second_best_mst;

const usz MAX_N = 8;
const usz MAX_M = 20;
const usz OUTPUT_BYTES = 32;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long second_best_mst(long* input, usz length, char* output, usz capacity)
    @export("second_best_mst") {
    if (input == null || length < 2 || length > 2 + 3 * MAX_M) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < n_value - 1 || m_value > (long)MAX_M)
        return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 3 * m) return -1;

    usz[MAX_M] edge_u, edge_v, order;
    long[MAX_M] edge_weight;
    bool[MAX_N * MAX_N] seen = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u_value = input[2 + 3 * edge], v_value = input[3 + 3 * edge];
        long weight = input[4 + 3 * edge];
        if (u_value < 0 || u_value >= v_value || v_value >= n_value || weight < 0 || weight > 1000000)
            return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        if (seen[u * MAX_N + v]) return -1;
        seen[u * MAX_N + v] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
        edge_weight[edge] = weight;
        order[edge] = edge;
    }

    for (usz i = 1; i < m; i += 1) {
        usz edge = order[i], j = i;
        while (j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge] ||
                (edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge))) {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = edge;
    }

    usz[MAX_N] dsu, size;
    for (usz vertex = 0; vertex < n; vertex += 1) { dsu[vertex] = vertex; size[vertex] = 1; }
    bool[MAX_M] in_mst = zeroed;
    usz[MAX_N * MAX_N] tree_to, tree_edge;
    usz[MAX_N] degree = zeroed;
    usz selected = 0;
    long mst_weight = 0;
    for (usz position = 0; position < m; position += 1) {
        usz edge = order[position];
        usz root_u = edge_u[edge], root_v = edge_v[edge];
        while (dsu[root_u] != root_u) { dsu[root_u] = dsu[dsu[root_u]]; root_u = dsu[root_u]; }
        while (dsu[root_v] != root_v) { dsu[root_v] = dsu[dsu[root_v]]; root_v = dsu[root_v]; }
        if (root_u == root_v) continue;
        if (size[root_u] < size[root_v]) { usz temporary = root_u; root_u = root_v; root_v = temporary; }
        dsu[root_v] = root_u;
        size[root_u] += size[root_v];
        in_mst[edge] = true;
        selected += 1;
        mst_weight += edge_weight[edge];
        usz cell_u = edge_u[edge] * MAX_N + degree[edge_u[edge]];
        tree_to[cell_u] = edge_v[edge]; tree_edge[cell_u] = edge; degree[edge_u[edge]] += 1;
        usz cell_v = edge_v[edge] * MAX_N + degree[edge_v[edge]];
        tree_to[cell_v] = edge_u[edge]; tree_edge[cell_v] = edge; degree[edge_v[edge]] += 1;
    }
    if (selected != n - 1) return -1;

    long second_weight = -1;
    long entering_edge = -1, leaving_edge = -1;
    for (usz added = 0; added < m; added += 1) {
        if (in_mst[added]) continue;
        long[MAX_N] parent, parent_edge;
        usz[MAX_N] queue;
        for (usz vertex = 0; vertex < n; vertex += 1) parent[vertex] = -1;
        usz head = 0, tail = 0;
        usz start = edge_u[added], target = edge_v[added];
        parent[start] = (long)start;
        queue[tail] = start; tail += 1;
        while (head < tail && parent[target] < 0) {
            usz vertex = queue[head]; head += 1;
            for (usz i = 0; i < degree[vertex]; i += 1) {
                usz cell = vertex * MAX_N + i;
                usz next = tree_to[cell];
                if (parent[next] >= 0) continue;
                parent[next] = (long)vertex;
                parent_edge[next] = (long)tree_edge[cell];
                queue[tail] = next; tail += 1;
            }
        }
        long first_weight = -1, second_path_weight = -1;
        long first_edge = -1, second_path_edge = -1;
        usz vertex = target;
        while (vertex != start) {
            long path_edge = parent_edge[vertex];
            long weight = edge_weight[(usz)path_edge];
            if (weight > first_weight) {
                second_path_weight = first_weight; second_path_edge = first_edge;
                first_weight = weight; first_edge = path_edge;
            } else if (weight == first_weight) {
                if (first_edge < 0 || path_edge < first_edge) first_edge = path_edge;
            } else if (weight > second_path_weight) {
                second_path_weight = weight; second_path_edge = path_edge;
            } else if (weight == second_path_weight &&
                    (second_path_edge < 0 || path_edge < second_path_edge)) {
                second_path_edge = path_edge;
            }
            vertex = (usz)parent[vertex];
        }
        long removed_weight = -1, removed_edge = -1;
        if (edge_weight[added] > first_weight) { removed_weight = first_weight; removed_edge = first_edge; }
        else if (edge_weight[added] == first_weight && second_path_weight >= 0) {
            removed_weight = second_path_weight; removed_edge = second_path_edge;
        }
        if (removed_edge < 0) continue;
        long candidate = mst_weight + edge_weight[added] - removed_weight;
        if (second_weight < 0 || candidate < second_weight ||
                (candidate == second_weight && ((long)added < entering_edge ||
                ((long)added == entering_edge && removed_edge < leaving_edge)))) {
            second_weight = candidate; entering_edge = (long)added; leaving_edge = removed_edge;
        }
    }

    if (output == null || capacity < OUTPUT_BYTES) return -2;
    store_i64_le(output, 0, mst_weight);
    store_i64_le(output, 8, second_weight);
    store_i64_le(output, 16, entering_edge);
    store_i64_le(output, 24, leaving_edge);
    return (long)OUTPUT_BYTES;
}
