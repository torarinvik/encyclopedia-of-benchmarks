module two_sat;

const int MAX_LITS = 80;
const int MAX_CLAUSES = 2047;

fn void dfs_order(bool* graph, usz n, usz v, bool* seen, usz* order, usz* count) {
    seen[v] = true;
    for (usz w = 0; w < n; w++) if (graph[v * MAX_LITS + w] && !seen[w]) dfs_order(graph, n, w, seen, order, count);
    order[(*count)++] = v;
}
fn void dfs_component(bool* graph, usz n, usz v, int* comp, int id) {
    comp[v] = id;
    for (usz w = 0; w < n; w++) if (graph[v * MAX_LITS + w] && comp[w] < 0) dfs_component(graph, n, w, comp, id);
}
fn long two_sat(long* input, usz length, char* output, usz capacity) @export("two_sat") {
    if (input == null || length < 2 || length > 4096) return -1;
    long vr = input[0]; long cr = input[1];
    if (vr < 0 || vr > 40 || cr < 0 || cr > MAX_CLAUSES || length != 2 + 2 * (usz)cr) return -1;
    usz variables = (usz)vr; usz clauses = (usz)cr; usz n = 2 * variables;
    bool[6400] graph = {}; bool[6400] transpose = {};
    for (usz i = 0; i < clauses; i++) {
        long a = input[2 + 2 * i]; long b = input[3 + 2 * i];
        if (a == 0 || b == 0 || a < -vr || a > vr || b < -vr || b > vr) return -1;
        usz aa = (usz)(a < 0 ? -a : a); usz bb = (usz)(b < 0 ? -b : b);
        usz x = 2 * (aa - 1) + (usz)(a < 0 ? 1 : 0); usz y = 2 * (bb - 1) + (usz)(b < 0 ? 1 : 0);
        usz u1 = x ^ 1; usz v1 = y; usz u2 = y ^ 1; usz v2 = x;
        graph[u1 * MAX_LITS + v1] = true; transpose[v1 * MAX_LITS + u1] = true;
        graph[u2 * MAX_LITS + v2] = true; transpose[v2 * MAX_LITS + u2] = true;
    }
    bool[80] seen = {}; usz[80] order = {}; usz count = 0;
    for (usz v = 0; v < n; v++) if (!seen[v]) dfs_order(&graph[0], n, v, &seen[0], &order[0], &count);
    int[80] comp; for (usz v = 0; v < n; v++) comp[v] = -1;
    int id = 0;
    while (count > 0) { count--; usz v = order[count]; if (comp[v] < 0) dfs_component(&transpose[0], n, v, &comp[0], id++); }
    bool satisfiable = true;
    for (usz i = 0; i < variables; i++) if (comp[2 * i] == comp[2 * i + 1]) satisfiable = false;
    usz outlen = satisfiable ? variables + 1 : 1;
    if (output == null || capacity < outlen) return -2;
    output[0] = satisfiable ? 1 : 0;
    if (satisfiable) for (usz i = 0; i < variables; i++) output[i + 1] = comp[2 * i] > comp[2 * i + 1] ? 1 : 0;
    return (long)outlen;
}
