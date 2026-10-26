// Clean-room bounded GBBS Shiloach-Vishkin spanning-forest profile.
module gbbs_shiloach_vishkin_spanning_forest;
const usz N = 12;
const usz M = 24;
const usz INPUT = 2 + 2 * M;

usz find_root(usz* parent, usz vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

long gbbs_shiloach_vishkin_spanning_forest(long* input, usz length,
        char* output, usz capacity) @export("gbbs_shiloach_vishkin_spanning_forest") {
    if (input == null || length < 2 || length > INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > 12 || m64 < 0 || m64 > 24 || length != 2 + 2 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    bool[N * N] seen = zeroed;
    usz[M] edge_u = zeroed, edge_v = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        usz u = (usz)u64, v = (usz)v64;
        if (seen[u * N + v]) return -1;
        seen[u * N + v] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    if (output == null || capacity < m) return -2;

    usz[N] parent = zeroed, previous = zeroed, next_parent = zeroed, best_lower = zeroed;
    bool[M] selected = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) parent[vertex] = vertex;
    for (usz round = 0; round < n; round += 1) {
        for (usz vertex = 0; vertex < n; vertex += 1) {
            previous[vertex] = find_root(&parent[0], vertex);
            next_parent[vertex] = previous[vertex];
            best_lower[vertex] = n;
        }
        for (usz edge = 0; edge < m; edge += 1) {
            usz root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
            if (root_u == root_v) continue;
            usz lower = root_u < root_v ? root_u : root_v;
            usz higher = root_u < root_v ? root_v : root_u;
            if (previous[higher] == higher && lower < best_lower[higher]) best_lower[higher] = lower;
        }
        bool changed = false;
        for (usz higher = 0; higher < n; higher += 1) {
            usz lower = best_lower[higher];
            if (lower == n) continue;
            next_parent[higher] = lower;
            changed = true;
            for (usz edge = 0; edge < m; edge += 1) {
                usz root_u = previous[edge_u[edge]], root_v = previous[edge_v[edge]];
                if ((root_u == higher && root_v == lower) || (root_u == lower && root_v == higher)) {
                    selected[edge] = true;
                    break;
                }
            }
        }
        for (usz vertex = 0; vertex < n; vertex += 1)
            parent[vertex] = find_root(&next_parent[0], vertex);
        if (!changed) break;
    }
    for (usz edge = 0; edge < m; edge += 1) output[edge] = selected[edge] ? 1 : 0;
    return (long)m;
}
