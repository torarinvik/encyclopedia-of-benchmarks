module lca;

fn usz find_root(usz* parent, usz vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

long lca(long* input, usz length) @export("lca") {
    if (input == null || length < 3 || length > 129 || input[0] < 1 || input[0] > 64) return -1;
    usz n = (usz)input[0];
    if (length != 2 * n + 1) return -1;
    usz dsu[64], degree[64];
    long adjacency[64][64];
    for (usz i = 0; i < n; i++) { dsu[i] = i; degree[i] = 0; }
    usz position = 1;
    for (usz edge = 0; edge + 1 < n; edge++) {
        long u_arg = input[position], v_arg = input[position + 1];
        position += 2;
        if (u_arg < 0 || u_arg >= (long)n || v_arg < 0 || v_arg >= (long)n || u_arg == v_arg) return -1;
        usz u = (usz)u_arg, v = (usz)v_arg;
        usz ru = find_root(dsu, u), rv = find_root(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        adjacency[u][degree[u]++] = (long)v;
        adjacency[v][degree[v]++] = (long)u;
    }
    long qa_arg = input[position], qb_arg = input[position + 1];
    if (qa_arg < 0 || qa_arg >= (long)n || qb_arg < 0 || qb_arg >= (long)n) return -1;
    usz component = find_root(dsu, 0);
    for (usz i = 1; i < n; i++) if (find_root(dsu, i) != component) return -1;

    usz parent[64], depth[64], stack[64], stack_size = 0;
    bool seen[64];
    for (usz i = 0; i < n; i++) seen[i] = false;
    parent[0] = 0; depth[0] = 0; seen[0] = true; stack[stack_size++] = 0;
    while (stack_size > 0) {
        usz vertex = stack[--stack_size];
        for (usz i = 0; i < degree[vertex]; i++) {
            usz next = (usz)adjacency[vertex][i];
            if (!seen[next]) {
                seen[next] = true; parent[next] = vertex; depth[next] = depth[vertex] + 1;
                stack[stack_size++] = next;
            }
        }
    }
    usz a = (usz)qa_arg, b = (usz)qb_arg;
    if (depth[a] < depth[b]) { usz t = a; a = b; b = t; }
    while (depth[a] != depth[b]) a = parent[a];
    if (a == b) return (long)a;
    while (a != b) { a = parent[a]; b = parent[b]; }
    return (long)a;
}
