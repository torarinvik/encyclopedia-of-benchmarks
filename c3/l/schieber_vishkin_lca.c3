module schieber_vishkin_lca;

const usz MAX_NODES = 256;
const usz MAX_QUERIES = 1024;
const usz MAX_ARCS = 510;
const usz MAX_INPUT = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES;

fn uint sv_lowbit(uint x) { return x & (0u - x); }
fn uint sv_highbit(uint x) {
    uint rest = x;
    uint bit = 0;
    while (rest != 0) { bit = rest; rest >>= 1; }
    return bit;
}

fn long schieber_vishkin_lca(long* input, usz length, char* output, usz capacity)
    @export("schieber_vishkin_lca") {
    if (input == null || length < 4 || length > MAX_INPUT + 1) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_NODES) return -1;
    usz n = (usz)input[0];
    if (input[1] < 0 || input[1] >= (long)n || input[2] != (long)(n - 1) ||
        input[3] < 0 || input[3] > (long)MAX_QUERIES) return -1;
    usz m = (usz)input[2], q = (usz)input[3];
    usz query_offset = 4 + 2 * m;
    if (length != query_offset + 2 * q) return -1;
    usz root = (usz)input[1];

    int[MAX_NODES] head, parent, order, stack_node, stack_arc, path_parent;
    int[MAX_ARCS] arc_to, arc_next;
    usz[MAX_NODES] preorder;
    uint[MAX_NODES] inlabel, ascendant;
    char[MAX_QUERIES] answers;
    for (usz node = 0; node < n; node++) { head[node] = -1; parent[node] = -2; }
    usz arcs = 0;
    for (usz edge = 0; edge < m; edge++) {
        long av = input[4 + 2 * edge], bv = input[5 + 2 * edge];
        if (av < 0 || av >= (long)n || bv < 0 || bv >= (long)n || av == bv) return -1;
        usz a = (usz)av, b = (usz)bv;
        arc_to[arcs] = (int)b; arc_next[arcs] = head[a]; head[a] = (int)arcs; arcs++;
        arc_to[arcs] = (int)a; arc_next[arcs] = head[b]; head[b] = (int)arcs; arcs++;
    }
    for (usz query = 0; query < q; query++) for (usz side = 0; side < 2; side++) {
        long node = input[query_offset + 2 * query + side];
        if (node < 0 || node >= (long)n) return -1;
    }

    usz reached = 1, top = 1;
    parent[root] = -1; preorder[root] = 1; order[0] = (int)root;
    stack_node[0] = (int)root; stack_arc[0] = head[root];
    while (top > 0) {
        usz slot = top - 1, node = (usz)stack_node[slot];
        int arc = stack_arc[slot];
        if (arc < 0) { top--; continue; }
        stack_arc[slot] = arc_next[(usz)arc];
        usz neighbor = (usz)arc_to[(usz)arc];
        if ((int)neighbor == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = (int)node; preorder[neighbor] = reached + 1;
        order[reached++] = (int)neighbor;
        stack_node[top] = (int)neighbor; stack_arc[top] = head[neighbor]; top++;
    }
    if (reached != n) return -1;
    if (capacity < q || (q != 0 && output == null)) return -2;

    for (usz node = 0; node < n; node++) inlabel[node] = (uint)preorder[node];
    for (usz i = n; i > 1; i--) {
        usz node = (usz)order[i - 1], p = (usz)parent[node];
        if (sv_lowbit(inlabel[p]) < sv_lowbit(inlabel[node])) inlabel[p] = inlabel[node];
    }
    for (usz pos = 0; pos < n; pos++) {
        usz node = (usz)order[pos];
        if (parent[node] < 0) {
            ascendant[node] = sv_lowbit(inlabel[node]);
            path_parent[preorder[node] - 1] = (int)node;
        } else {
            usz p = (usz)parent[node];
            ascendant[node] = ascendant[p] | sv_lowbit(inlabel[node]);
            path_parent[preorder[node] - 1] = inlabel[node] != inlabel[p]
                ? (int)p : path_parent[preorder[p] - 1];
        }
    }
    for (usz query = 0; query < q; query++) {
        usz u = (usz)input[query_offset + 2 * query];
        usz v = (usz)input[query_offset + 2 * query + 1];
        uint lu = sv_lowbit(inlabel[u]), lv = sv_lowbit(inlabel[v]);
        uint mask = sv_highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1u;
        uint j = sv_lowbit(ascendant[u] & ascendant[v] & ~mask);
        if (j == 0) return -1;
        usz x = u, y = v;
        if (j != lu) {
            mask = sv_highbit(ascendant[u] & (j - 1u)) - 1u;
            usz index = ((preorder[u] & ~(usz)mask) | ((usz)mask + 1)) - 1;
            x = (usz)path_parent[index];
        }
        if (j != lv) {
            mask = sv_highbit(ascendant[v] & (j - 1u)) - 1u;
            usz index = ((preorder[v] & ~(usz)mask) | ((usz)mask + 1)) - 1;
            y = (usz)path_parent[index];
        }
        answers[query] = (char)(preorder[x] < preorder[y] ? x : y);
    }
    for (usz query = 0; query < q; query++) output[query] = answers[query];
    return (long)q;
}
