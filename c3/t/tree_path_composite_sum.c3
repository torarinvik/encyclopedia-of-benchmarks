module tree_path_composite_sum;

const usz MAX_N = 32;
const usz MAX_CELLS = MAX_N * MAX_N;
const usz MAX_INPUT = 5 * MAX_N - 3;
const long MOD = 998244353;

fn usz tpc_find_root(usz[MAX_N]* parent, usz item) {
    usz node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn void tpc_store(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tree_path_composite_sum(long* input, usz length, char* output, usz capacity)
    @export("tree_path_composite_sum") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n + 4 * (n - 1)) return -1;

    long[MAX_N] vertex_value = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        vertex_value[vertex] = input[1 + vertex];
        if (vertex_value[vertex] < 0 || vertex_value[vertex] >= MOD) return -1;
    }
    bool[MAX_CELLS] adjacent = zeroed;
    long[MAX_CELLS] multiplier = zeroed;
    long[MAX_CELLS] addend = zeroed;
    usz[MAX_N] dsu_parent, dsu_size;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    usz offset = 1 + n;
    for (usz edge = 0; edge + 1 < n; edge += 1) {
        long u_value = input[offset], v_value = input[offset + 1];
        long b = input[offset + 2], c = input[offset + 3];
        offset += 4;
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            u_value == v_value || b < 1 || b >= MOD || c < 0 || c >= MOD) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        usz root_u = tpc_find_root(dsu_parent, u);
        usz root_v = tpc_find_root(dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) {
            usz temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        multiplier[u * MAX_N + v] = b;
        multiplier[v * MAX_N + u] = b;
        addend[u * MAX_N + v] = c;
        addend[v * MAX_N + u] = c;
    }

    usz[MAX_N] order, stack;
    long[MAX_N] parent;
    for (usz vertex = 0; vertex < n; vertex += 1) parent[vertex] = -2;
    parent[0] = -1;
    usz top = 1, order_count = 0;
    stack[0] = 0;
    while (top > 0) {
        top -= 1;
        usz u = stack[top];
        order[order_count] = u;
        order_count += 1;
        for (usz v = 0; v < n; v += 1) {
            usz cell = u * MAX_N + v;
            if (adjacent[cell] && (long)v != parent[u]) {
                parent[v] = (long)u;
                stack[top] = v;
                top += 1;
            }
        }
    }

    long[MAX_N] down_sum = zeroed, up_sum = zeroed, answer = zeroed;
    usz[MAX_N] down_count = zeroed, up_count = zeroed;
    usz position = order_count;
    while (position > 0) {
        position -= 1;
        usz u = order[position];
        down_sum[u] = vertex_value[u];
        down_count[u] = 1;
        for (usz v = 0; v < n; v += 1) {
            usz cell = u * MAX_N + v;
            if (adjacent[cell] && parent[v] == (long)u) {
                long contribution = (multiplier[cell] * down_sum[v] +
                    addend[cell] * (long)down_count[v]) % MOD;
                down_sum[u] = (down_sum[u] + contribution) % MOD;
                down_count[u] += down_count[v];
            }
        }
    }
    for (usz position = 0; position < order_count; position += 1) {
        usz u = order[position];
        long total_sum = vertex_value[u];
        usz total_count = 1;
        if (parent[u] >= 0) {
            total_sum = (total_sum + up_sum[u]) % MOD;
            total_count += up_count[u];
        }
        for (usz v = 0; v < n; v += 1) {
            usz cell = u * MAX_N + v;
            if (adjacent[cell] && parent[v] == (long)u) {
                total_sum = (total_sum + multiplier[cell] * down_sum[v] +
                    addend[cell] * (long)down_count[v]) % MOD;
                total_count += down_count[v];
            }
        }
        answer[u] = total_sum;
        for (usz v = 0; v < n; v += 1) {
            usz cell = u * MAX_N + v;
            if (adjacent[cell] && parent[v] == (long)u) {
                long contribution = (multiplier[cell] * down_sum[v] +
                    addend[cell] * (long)down_count[v]) % MOD;
                long outside_sum = (total_sum - contribution + MOD) % MOD;
                usz outside_count = total_count - down_count[v];
                up_sum[v] = (multiplier[cell] * outside_sum +
                    addend[cell] * (long)outside_count) % MOD;
                up_count[v] = outside_count;
            }
        }
    }

    usz required = 8 * n;
    if (output == null || capacity < required) return -2;
    for (usz vertex = 0; vertex < n; vertex += 1)
        tpc_store(output, 8 * vertex, answer[vertex]);
    return (long)required;
}
