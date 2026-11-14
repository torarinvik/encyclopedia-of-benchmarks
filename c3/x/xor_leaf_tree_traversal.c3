module xor_leaf_tree_traversal;

fn long xor_leaf_tree_traversal(long* input, usz length, char* output, usz capacity) @export("xor_leaf_tree_traversal") {
    if (input == null || length < 2 || input[0] < 1 || input[0] > 64) return -1;
    int n = (int)input[0];
    if (input[1] < 0 || input[1] >= n || length != (usz)(2 * n)) return -1;
    int root = (int)input[1];
    int[64] degree = {}, edge_xor = {}, parents = {}, dsu = {}, ranks = {}, order = {};
    int[63] a = {}, b = {};
    for (int i = 0; i < n; i++) { dsu[i] = i; parents[i] = -1; }
    for (int e = 0; e < n - 1; e++) {
        long ur = input[2 + 2 * e], vr = input[3 + 2 * e];
        if (ur < 0 || ur >= n || vr < 0 || vr >= n || ur == vr) return -1;
        int u = (int)ur, v = (int)vr, x = u, y = v;
        while (dsu[x] != x) { dsu[x] = dsu[dsu[x]]; x = dsu[x]; }
        while (dsu[y] != y) { dsu[y] = dsu[dsu[y]]; y = dsu[y]; }
        if (x == y) return -1;
        if (ranks[x] < ranks[y]) dsu[x] = y;
        else { dsu[y] = x; if (ranks[x] == ranks[y]) ranks[x]++; }
        a[e] = u; b[e] = v; degree[u]++; degree[v]++;
        edge_xor[u] ^= e; edge_xor[v] ^= e;
    }
    degree[root] = 0;
    int used = 0;
    for (int start = 0; start < n; start++) {
        int v = start;
        while (degree[v] == 1) {
            int e = edge_xor[v], next = a[e] ^ b[e] ^ v;
            parents[v] = e; order[used++] = v; degree[v] = 0;
            degree[next]--; edge_xor[next] ^= e; v = next;
        }
    }
    order[used++] = root;
    if (used != n) return -1;
    if (output == null || capacity < (usz)(16 * n)) return -2;
    for (int i = 0; i < 2 * n; i++) {
        long value = i < n ? parents[i] : order[i - n];
        ulong bits = (ulong)value;
        for (int byte = 0; byte < 8; byte++) output[8*i+byte] = (char)(bits >> (8*byte));
    }
    return 16 * n;
}
