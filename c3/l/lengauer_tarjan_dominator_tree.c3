module lengauer_tarjan_dominator_tree;

const usz MAX_V = 63;
const usz MAX_E = 2047;
const usz MAX_INPUT = 4097;

fn int lt_eval(int vertex, int* ancestor, int* label, int* semi, int* path) {
    if (ancestor[vertex] == 0) return vertex;
    int used = 0, current = vertex;
    while (ancestor[ancestor[current]] != 0) { path[used] = current; used++; current = ancestor[current]; }
    while (used > 0) {
        used--;
        current = path[used];
        int p = ancestor[current];
        if (semi[label[p]] < semi[label[current]]) label[current] = label[p];
        ancestor[current] = ancestor[p];
    }
    return label[vertex];
}

fn long lengauer_tarjan_dominator_tree(long* input, usz length, char* output,
    usz capacity) @export("lengauer_tarjan_dominator_tree") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long nv = input[0], root_value = input[1], me = input[2];
    if (nv < 1 || nv > 63 || root_value < 0 || root_value >= nv || me < 0 || me > 2047) return -1;
    int n = (int)nv, root = (int)root_value, m = (int)me;
    if (length != 3 + 2 * (usz)m) return -1;

    ulong[MAX_V] outmask = zeroed;
    int[MAX_V] out_head;
    int[MAX_E] edge_source, edge_target, out_next, pred_next;
    int[MAX_V + 1] pred_head, vertex_at, parent, semi, ancestor, label, immediate, bucket_head, bucket_next;
    int[MAX_V] dfs_number = zeroed, node_stack, edge_stack;
    int[MAX_V + 1] eval_path;
    char[MAX_V] staged = zeroed;
    for (int v = 0; v < n; v++) out_head[v] = -1;
    for (int v = 0; v <= (int)MAX_V; v++) { pred_head[v] = -1; bucket_head[v] = -1; }

    int edge_count = 0;
    for (int i = 0; i < m; i++) {
        long sv = input[3 + 2 * i], tv = input[4 + 2 * i];
        if (sv < 0 || sv >= nv || tv < 0 || tv >= nv) return -1;
        int source = (int)sv, target = (int)tv;
        ulong bit = 1ul << (ulong)target;
        if ((outmask[source] & bit) == 0) {
            outmask[source] |= bit;
            edge_source[edge_count] = source;
            edge_target[edge_count] = target;
            out_next[edge_count] = out_head[source];
            out_head[source] = edge_count;
            edge_count++;
        }
    }

    int dfs_count = 1, top = 1;
    dfs_number[root] = 1;
    vertex_at[1] = root;
    node_stack[0] = root;
    edge_stack[0] = out_head[root];
    while (top > 0) {
        int frame = top - 1, current = node_stack[frame], edge = edge_stack[frame];
        if (edge == -1) { top--; continue; }
        edge_stack[frame] = out_next[edge];
        int target = edge_target[edge];
        if (dfs_number[target] == 0) {
            int number = dfs_count + 1;
            dfs_count = number;
            dfs_number[target] = number;
            vertex_at[number] = target;
            parent[number] = dfs_number[current];
            node_stack[top] = target;
            edge_stack[top] = out_head[target];
            top++;
        }
    }
    for (int edge = 0; edge < edge_count; edge++) {
        int source_number = dfs_number[edge_source[edge]], target_number = dfs_number[edge_target[edge]];
        if (source_number != 0 && target_number != 0) {
            pred_next[edge] = pred_head[target_number];
            pred_head[target_number] = edge;
        }
    }
    for (int v = 1; v <= dfs_count; v++) { semi[v] = v; label[v] = v; }
    for (int w = dfs_count; w >= 2; w--) {
        int edge = pred_head[w];
        while (edge != -1) {
            int predecessor = dfs_number[edge_source[edge]];
            int representative = lt_eval(predecessor, &ancestor[0], &label[0], &semi[0], &eval_path[0]);
            if (semi[representative] < semi[w]) semi[w] = semi[representative];
            edge = pred_next[edge];
        }
        bucket_next[w] = bucket_head[semi[w]];
        bucket_head[semi[w]] = w;
        ancestor[w] = parent[w];
        int owner = parent[w], member = bucket_head[owner];
        bucket_head[owner] = -1;
        while (member != -1) {
            int next = bucket_next[member];
            int representative = lt_eval(member, &ancestor[0], &label[0], &semi[0], &eval_path[0]);
            immediate[member] = semi[representative] < semi[member] ? representative : owner;
            member = next;
        }
    }
    for (int w = 2; w <= dfs_count; w++) if (immediate[w] != semi[w]) immediate[w] = immediate[immediate[w]];
    immediate[1] = 1;
    for (int v = 0; v < n; v++) {
        int number = dfs_number[v];
        staged[v] = number == 0 ? (char)255 : (char)vertex_at[immediate[number]];
    }
    if (output == null || capacity < (usz)n) return -2;
    for (int v = 0; v < n; v++) output[v] = staged[v];
    return n;
}
