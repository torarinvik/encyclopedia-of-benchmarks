module tree_path_distinct_mo;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_INPUT = 3 * MAX_N + 2 * MAX_Q;
const usz MAX_CELLS = MAX_N * MAX_N;

struct Query {
    usz left;
    usz right;
    usz id;
    usz block;
    usz right_key;
}

fn usz tpm_find_root(usz* parent, usz item) {
    usz node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn bool tpm_less(Query a, Query b) {
    if (a.block != b.block) return a.block < b.block;
    if (a.right_key != b.right_key) return a.right_key < b.right_key;
    return a.id < b.id;
}

fn void tpm_sift(Query* values, usz root_start, usz end) {
    usz root = root_start;
    while (root * 2 + 1 < end) {
        usz child = root * 2 + 1;
        usz largest = root;
        if (tpm_less(values[largest], values[child])) largest = child;
        if (child + 1 < end && tpm_less(values[largest], values[child + 1])) largest = child + 1;
        if (largest == root) return;
        Query temporary = values[root];
        values[root] = values[largest];
        values[largest] = temporary;
        root = largest;
    }
}

fn void tpm_sort(Query* values, usz count) {
    usz start = count / 2;
    while (start > 0) {
        start -= 1;
        tpm_sift(values, start, count);
    }
    usz end = count;
    while (end > 1) {
        end -= 1;
        Query temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        tpm_sift(values, 0, end);
    }
}

fn int tpm_lca(int a, int b, int* parent, usz* depth) {
    while (depth[a] > depth[b]) a = parent[a];
    while (depth[b] > depth[a]) b = parent[b];
    while (a != b) { a = parent[a]; b = parent[b]; }
    return a;
}

fn void tpm_toggle(usz vertex, usz* color_id, usz* counts, bool* active, usz* distinct) {
    usz color = color_id[vertex];
    if (active[vertex]) {
        active[vertex] = false;
        counts[color] -= 1;
        if (counts[color] == 0) distinct[0] -= 1;
    } else {
        active[vertex] = true;
        if (counts[color] == 0) distinct[0] += 1;
        counts[color] += 1;
    }
}

fn void tpm_store(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tree_path_distinct_mo(long* input, usz length, char* output, usz capacity)
    @export("tree_path_distinct_mo") {
    if (input == null || length < 3 || length > MAX_INPUT + 1) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || q_value < 0 || q_value > (long)MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if (length != 3 * n + 2 * q) return -1;

    long[MAX_N] colors;
    for (usz vertex = 0; vertex < n; vertex += 1) colors[vertex] = input[2 + vertex];
    bool[MAX_CELLS] adjacent = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    usz offset = 2 + n;
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        long u_value = input[offset], v_value = input[offset + 1];
        offset += 2;
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        usz root_u = tpm_find_root(&dsu_parent[0], u);
        usz root_v = tpm_find_root(&dsu_parent[0], v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) { usz temporary = root_u; root_u = root_v; root_v = temporary; }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
    }

    int[MAX_Q] query_u, query_v;
    for (usz id = 0; id < q; id += 1) {
        long u_value = input[offset], v_value = input[offset + 1];
        offset += 2;
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value) return -1;
        query_u[id] = (int)u_value;
        query_v[id] = (int)v_value;
    }

    usz[MAX_N] color_id, first_color;
    usz color_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        usz rank = 0;
        while (rank < color_count && colors[first_color[rank]] != colors[vertex]) rank += 1;
        if (rank == color_count) { first_color[color_count] = vertex; color_count += 1; }
        color_id[vertex] = rank;
    }

    int[MAX_N] parent = zeroed, depth = zeroed, entry = zeroed, leave = zeroed;
    usz[2 * MAX_N] euler;
    int[2 * MAX_N] event_node, event_parent;
    bool[2 * MAX_N] event_exit = zeroed;
    usz top = 1, clock = 0;
    event_node[0] = 0;
    event_parent[0] = (int)n;
    while (top > 0) {
        top -= 1;
        int u = event_node[top], previous = event_parent[top];
        if (event_exit[top]) {
            leave[u] = (int)clock;
            euler[clock] = (usz)u;
            clock += 1;
        } else {
            parent[u] = previous;
            entry[u] = (int)clock;
            euler[clock] = (usz)u;
            clock += 1;
            event_node[top] = u;
            event_parent[top] = previous;
            event_exit[top] = true;
            top += 1;
            usz v = n;
            while (v > 0) {
                v -= 1;
                if (adjacent[u * MAX_N + v] && (int)v != previous) {
                    depth[v] = depth[u] + 1;
                    event_node[top] = (int)v;
                    event_parent[top] = u;
                    event_exit[top] = false;
                    top += 1;
                }
            }
        }
    }

    Query[MAX_Q] queries;
    usz block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= 2 * n) block_size += 1;
    for (usz id = 0; id < q; id += 1) {
        int u = query_u[id], v = query_v[id];
        if (entry[u] > entry[v]) { int temporary = u; u = v; v = temporary; }
        int ancestor = tpm_lca(u, v, &parent[0], &depth[0]);
        usz left = (usz)(ancestor == u ? entry[u] : leave[u]);
        usz right = (usz)entry[v];
        usz block = left / block_size;
        usz right_key = block % 2 == 0 ? right : 2 * n - 1 - right;
        queries[id] = Query{left, right, id, block, right_key};
    }
    tpm_sort(&queries[0], q);

    usz[MAX_N] counts = zeroed, answers = zeroed;
    bool[MAX_N] active = zeroed;
    usz distinct = 0;
    int left = 0, right = -1;
    for (usz sorted_id = 0; sorted_id < q; sorted_id += 1) {
        Query query = queries[sorted_id];
        while (left > (int)query.left) { left -= 1; tpm_toggle(euler[left], &color_id[0], &counts[0], &active[0], &distinct); }
        while (right < (int)query.right) { right += 1; tpm_toggle(euler[right], &color_id[0], &counts[0], &active[0], &distinct); }
        while (left < (int)query.left) { tpm_toggle(euler[left], &color_id[0], &counts[0], &active[0], &distinct); left += 1; }
        while (right > (int)query.right) { tpm_toggle(euler[right], &color_id[0], &counts[0], &active[0], &distinct); right -= 1; }
        int ancestor = tpm_lca(query_u[query.id], query_v[query.id], &parent[0], &depth[0]);
        if (ancestor != query_u[query.id] && ancestor != query_v[query.id]) {
            tpm_toggle((usz)ancestor, &color_id[0], &counts[0], &active[0], &distinct);
            answers[query.id] = distinct;
            tpm_toggle((usz)ancestor, &color_id[0], &counts[0], &active[0], &distinct);
        } else answers[query.id] = distinct;
    }

    usz required = 8 * q;
    if (output == null || capacity < required) return -2;
    for (usz id = 0; id < q; id += 1) tpm_store(output, 8 * id, (long)answers[id]);
    return (long)required;
}
