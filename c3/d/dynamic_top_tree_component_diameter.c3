module dynamic_top_tree_component_diameter;

const int MAX_VERTICES = 16;
const int MAX_OPERATIONS = 32;
const int MAX_EDGES = 15;
const int MAX_NODES = 75;
const usz MAX_INPUT = 143;
const long MAX_WEIGHT = 1000;
const int EDGE_BASE = 0, EDGE_COMPRESS = 1, RAKE_ZERO = 2, RAKE_MERGE = 3, RAKE_BRANCH = 4;

struct DttNode {
    short kind, a, b, c, parent, endpoint0, endpoint1, pivot, edge_id;
    long length, far0, far1, diameter, best1, best2;
}

fn int dtt_find_root(int* parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

fn long dtt_far_at(DttNode* nodes, int node_id, int vertex) {
    DttNode* node = &nodes[node_id];
    return node.endpoint0 == vertex ? node.far0 : node.far1;
}

fn void dtt_recalculate(DttNode* nodes, int node_id, long* weights) {
    DttNode* node = &nodes[node_id];
    if (node.kind == EDGE_BASE) {
        long weight = weights[node.edge_id];
        node.length = weight; node.far0 = weight; node.far1 = weight; node.diameter = weight;
    } else if (node.kind == RAKE_ZERO) {
        node.best1 = 0; node.best2 = 0; node.diameter = 0;
    } else if (node.kind == RAKE_MERGE) {
        DttNode* left = &nodes[node.a]; DttNode* right = &nodes[node.b];
        long[4] arms = {left.best1, left.best2, right.best1, right.best2};
        long first = 0; long second = 0;
        for (int i = 0; i < 4; i++) {
            if (arms[i] >= first) { second = first; first = arms[i]; }
            else if (arms[i] > second) second = arms[i];
        }
        node.best1 = first; node.best2 = second;
        node.diameter = left.diameter > right.diameter ? left.diameter : right.diameter;
        if (left.best1 + right.best1 > node.diameter) node.diameter = left.best1 + right.best1;
    } else if (node.kind == RAKE_BRANCH) {
        DttNode* edge = &nodes[node.a]; DttNode* local = &nodes[node.b];
        long center_far = dtt_far_at(nodes, node.a, node.endpoint0);
        long pivot_far = dtt_far_at(nodes, node.a, node.pivot);
        node.best1 = center_far > edge.length + local.best1 ? center_far : edge.length + local.best1;
        node.best2 = 0;
        node.diameter = edge.diameter > local.diameter ? edge.diameter : local.diameter;
        if (pivot_far + local.best1 > node.diameter) node.diameter = pivot_far + local.best1;
    } else {
        DttNode* first = &nodes[node.a]; DttNode* second = &nodes[node.b]; DttNode* local = &nodes[node.c];
        int y = node.endpoint0; int z = node.endpoint1; int x = node.pivot;
        long first_y = dtt_far_at(nodes, node.a, y); long first_x = dtt_far_at(nodes, node.a, x);
        long second_x = dtt_far_at(nodes, node.b, x); long second_z = dtt_far_at(nodes, node.b, z);
        node.length = first.length + second.length;
        long from_y = first.length + (second_x > local.best1 ? second_x : local.best1);
        long from_z = second.length + (first_x > local.best1 ? first_x : local.best1);
        node.far0 = first_y > from_y ? first_y : from_y;
        node.far1 = second_z > from_z ? second_z : from_z;
        node.diameter = first.diameter > second.diameter ? first.diameter : second.diameter;
        if (local.diameter > node.diameter) node.diameter = local.diameter;
        if (first_x + second_x > node.diameter) node.diameter = first_x + second_x;
        if (first_x + local.best1 > node.diameter) node.diameter = first_x + local.best1;
        if (second_x + local.best1 > node.diameter) node.diameter = second_x + local.best1;
    }
}

fn int dtt_append(DttNode* nodes, int* count, int kind, long* weights, int a, int b, int c,
                  int endpoint0, int endpoint1, int pivot, int edge_id) {
    if (*count >= MAX_NODES) return -1;
    int id = *count; *count += 1;
    DttNode* node = &nodes[id];
    node.kind = (short)kind; node.a = (short)a; node.b = (short)b; node.c = (short)c;
    node.parent = -1; node.endpoint0 = (short)endpoint0; node.endpoint1 = (short)endpoint1;
    node.pivot = (short)pivot; node.edge_id = (short)edge_id;
    node.length = 0; node.far0 = 0; node.far1 = 0; node.diameter = 0; node.best1 = 0; node.best2 = 0;
    if (a >= 0) nodes[a].parent = (short)id;
    if (b >= 0) nodes[b].parent = (short)id;
    if (c >= 0) nodes[c].parent = (short)id;
    dtt_recalculate(nodes, id, weights);
    return id;
}

fn int dtt_make_rake(DttNode* nodes, int* node_count, long* weights, int base,
                     short* branch_ids, int branch_count) {
    short[17] level; short[17] next;
    int count = 1; level[0] = (short)base;
    for (int i = 0; i < branch_count; i++) { level[count] = branch_ids[i]; count++; }
    while (count > 1) {
        int next_count = 0;
        for (int i = 0; i < count; i += 2) {
            if (i + 1 == count) { next[next_count] = level[i]; next_count++; }
            else {
                int merged = dtt_append(nodes, node_count, RAKE_MERGE, weights,
                                        level[i], level[i + 1], -1, -1, -1, -1, -1);
                if (merged < 0) return -1;
                next[next_count] = (short)merged; next_count++;
            }
        }
        for (int i = 0; i < next_count; i++) level[i] = next[i];
        count = next_count;
    }
    return level[0];
}

fn int dtt_neighbor_count(bool[MAX_VERTICES][MAX_VERTICES] adjacency,
                          bool* active, int n, int vertex, int* output) {
    int count = 0;
    for (int other = 0; other < n; other++) if (active[other] && adjacency[vertex][other]) {
        if (count < 2) output[count] = other;
        count++;
    }
    return count;
}

fn long dynamic_top_tree_component_diameter(long* input, usz length, uint8* output, usz capacity)
    @export("dynamic_top_tree_component_diameter") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0]; long q_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || q_value < 0 || q_value > MAX_OPERATIONS) return -1;
    int n = (int)n_value; int q = (int)q_value;
    int edge_end = 2 + 3 * (n - 1);
    if (length != (usz)(edge_end + 3 * q)) return -1;

    int[MAX_EDGES] edge_u; int[MAX_EDGES] edge_v; int[MAX_VERTICES] dsu;
    long[MAX_EDGES] weights = zeroed;
    for (int i = 0; i < n; i++) dsu[i] = i;
    for (int edge_id = 0; edge_id < n - 1; edge_id++) {
        int offset = 2 + 3 * edge_id;
        long u_value = input[offset]; long v_value = input[offset + 1]; long weight = input[offset + 2];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight < 0 || weight > MAX_WEIGHT) return -1;
        int u = (int)u_value; int v = (int)v_value;
        int ru = dtt_find_root(&dsu[0], u); int rv = dtt_find_root(&dsu[0], v);
        if (ru == rv) return -1;
        dsu[ru] = rv; edge_u[edge_id] = u; edge_v[edge_id] = v; weights[edge_id] = weight;
    }
    for (int vertex = 1; vertex < n; vertex++)
        if (dtt_find_root(&dsu[0], vertex) != dtt_find_root(&dsu[0], 0)) return -1;

    int[MAX_OPERATIONS] op_code; int[MAX_OPERATIONS] op_edge; int[MAX_OPERATIONS] op_value;
    int query_count = 0;
    for (int op = 0; op < q; op++) {
        int offset = edge_end + 3 * op;
        long opcode = input[offset]; long edge_id = input[offset + 1]; long value = input[offset + 2];
        if (opcode == 0) {
            if (edge_id < 0 || edge_id >= n - 1 || value < 0 || value > MAX_WEIGHT) return -1;
        } else if (opcode == 1) {
            if (edge_id != 0 || value != 0) return -1;
            query_count++;
        } else return -1;
        op_code[op] = (int)opcode; op_edge[op] = (int)edge_id; op_value[op] = (int)value;
    }
    usz output_bytes = (usz)(query_count * 8);
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;

    DttNode[MAX_NODES] nodes = zeroed;
    int node_count = 0; int[MAX_VERTICES] base_rake; int[MAX_EDGES] base_edge;
    bool[MAX_VERTICES][MAX_VERTICES] adjacency = zeroed;
    bool[MAX_VERTICES] active = zeroed;
    short[MAX_VERTICES][MAX_VERTICES] edge_cluster;
    short[MAX_VERTICES][MAX_VERTICES] branches;
    int[MAX_VERTICES] branch_count = zeroed;
    for (int u = 0; u < MAX_VERTICES; u++) for (int v = 0; v < MAX_VERTICES; v++) edge_cluster[u][v] = -1;
    for (int vertex = 0; vertex < n; vertex++) {
        active[vertex] = true;
        base_rake[vertex] = dtt_append(&nodes[0], &node_count, RAKE_ZERO, &weights[0], -1, -1, -1, -1, -1, -1, -1);
        if (base_rake[vertex] < 0) return -1;
    }
    for (int edge_id = 0; edge_id < n - 1; edge_id++) {
        int u = edge_u[edge_id]; int v = edge_v[edge_id];
        int cluster = dtt_append(&nodes[0], &node_count, EDGE_BASE, &weights[0], -1, -1, -1, u, v, -1, edge_id);
        if (cluster < 0) return -1;
        base_edge[edge_id] = cluster;
        adjacency[u][v] = true; adjacency[v][u] = true;
        edge_cluster[u][v] = (short)cluster; edge_cluster[v][u] = (short)cluster;
    }

    int active_count = n;
    while (active_count > 1) {
        if (active_count == 2) {
            int[2] pair; int found = 0;
            for (int vertex = 0; vertex < n; vertex++) if (active[vertex]) { pair[found] = vertex; found++; }
            int x = pair[0]; int y = pair[1];
            int local = dtt_make_rake(&nodes[0], &node_count, &weights[0], base_rake[x], &branches[x][0], branch_count[x]);
            if (local < 0) return -1;
            int branch = dtt_append(&nodes[0], &node_count, RAKE_BRANCH, &weights[0], edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0) return -1;
            branches[y][branch_count[y]] = (short)branch; branch_count[y]++;
            adjacency[x][y] = false; adjacency[y][x] = false; active[x] = false; active_count--;
            break;
        }
        int[MAX_VERTICES] leaves; int[MAX_VERTICES] leaf_neighbor; int leaf_count = 0;
        for (int vertex = 0; vertex < n; vertex++) if (active[vertex]) {
            int[2] adjacent;
            if (dtt_neighbor_count(adjacency, &active[0], n, vertex, &adjacent[0]) == 1) {
                leaves[leaf_count] = vertex; leaf_neighbor[leaf_count] = adjacent[0]; leaf_count++;
            }
        }
        for (int i = 0; i < leaf_count; i++) {
            int x = leaves[i]; int y = leaf_neighbor[i];
            int local = dtt_make_rake(&nodes[0], &node_count, &weights[0], base_rake[x], &branches[x][0], branch_count[x]);
            if (local < 0) return -1;
            int branch = dtt_append(&nodes[0], &node_count, RAKE_BRANCH, &weights[0], edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0 || branch_count[y] >= MAX_VERTICES) return -1;
            branches[y][branch_count[y]] = (short)branch; branch_count[y]++;
        }
        for (int i = 0; i < leaf_count; i++) {
            int x = leaves[i]; int y = leaf_neighbor[i];
            adjacency[x][y] = false; adjacency[y][x] = false;
            edge_cluster[x][y] = -1; edge_cluster[y][x] = -1;
            active[x] = false; active_count--;
        }
        if (active_count <= 1) break;

        bool[MAX_VERTICES] chosen = zeroed;
        int[MAX_VERTICES] compress_vertices; int compress_count = 0;
        for (int x = 0; x < n; x++) if (active[x]) {
            int[2] adjacent;
            if (dtt_neighbor_count(adjacency, &active[0], n, x, &adjacent[0]) != 2) continue;
            if (!chosen[adjacent[0]] && !chosen[adjacent[1]]) { chosen[x] = true; compress_vertices[compress_count] = x; compress_count++; }
        }
        int[MAX_VERTICES] pending_x; int[MAX_VERTICES] pending_y; int[MAX_VERTICES] pending_z; int[MAX_VERTICES] pending_cluster;
        for (int i = 0; i < compress_count; i++) {
            int x = compress_vertices[i]; int[2] adjacent;
            dtt_neighbor_count(adjacency, &active[0], n, x, &adjacent[0]);
            int y = adjacent[0]; int z = adjacent[1];
            int local = dtt_make_rake(&nodes[0], &node_count, &weights[0], base_rake[x], &branches[x][0], branch_count[x]);
            if (local < 0) return -1;
            int compressed = dtt_append(&nodes[0], &node_count, EDGE_COMPRESS, &weights[0],
                                        edge_cluster[y][x], edge_cluster[x][z], local, y, z, x, -1);
            if (compressed < 0) return -1;
            pending_x[i] = x; pending_y[i] = y; pending_z[i] = z; pending_cluster[i] = compressed;
        }
        for (int i = 0; i < compress_count; i++) {
            int x = pending_x[i]; int y = pending_y[i]; int z = pending_z[i];
            adjacency[y][x] = false; adjacency[x][y] = false; adjacency[x][z] = false; adjacency[z][x] = false;
            edge_cluster[y][x] = -1; edge_cluster[x][y] = -1; edge_cluster[x][z] = -1; edge_cluster[z][x] = -1;
            active[x] = false; active_count--;
        }
        for (int i = 0; i < compress_count; i++) {
            int y = pending_y[i]; int z = pending_z[i];
            adjacency[y][z] = true; adjacency[z][y] = true;
            edge_cluster[y][z] = (short)pending_cluster[i]; edge_cluster[z][y] = (short)pending_cluster[i];
        }
    }
    int root_vertex = 0; while (!active[root_vertex]) root_vertex++;
    int root = dtt_make_rake(&nodes[0], &node_count, &weights[0], base_rake[root_vertex], &branches[root_vertex][0], branch_count[root_vertex]);
    int64_t[MAX_OPERATIONS] staged; int staged_count = 0;
    for (int op = 0; op < q; op++) {
        if (op_code[op] == 0) {
            int edge_id = op_edge[op]; weights[edge_id] = op_value[op];
            int node_id = base_edge[edge_id]; dtt_recalculate(&nodes[0], node_id, &weights[0]);
            int ancestor = nodes[node_id].parent;
            while (ancestor >= 0) { dtt_recalculate(&nodes[0], ancestor, &weights[0]); ancestor = nodes[ancestor].parent; }
        } else { staged[staged_count] = nodes[root].diameter; staged_count++; }
    }
    for (int i = 0; i < staged_count; i++) {
        ulong bits = (ulong)staged[i];
        for (int byte = 0; byte < 8; byte++) output[8 * i + byte] = (uint8)(bits >> (8 * byte));
    }
    return (long)output_bytes;
}
