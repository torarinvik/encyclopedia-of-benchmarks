/* Fixed-tree diameter updates using a rake/compress cluster hierarchy. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define DTT_MAX_VERTICES 16
#define DTT_MAX_OPERATIONS 32
#define DTT_MAX_EDGES 15
#define DTT_MAX_NODES 75
#define DTT_MAX_INPUT 143
#define DTT_MAX_WEIGHT INT64_C(1000)

enum { DTT_EDGE_BASE = 0, DTT_EDGE_COMPRESS = 1, DTT_RAKE_ZERO = 2,
       DTT_RAKE_MERGE = 3, DTT_RAKE_BRANCH = 4 };

typedef struct {
    int16_t kind, a, b, c, parent, endpoint0, endpoint1, pivot, edge_id;
    int64_t length, far0, far1, diameter, best1, best2;
} DttNode;

static int dtt_find_root(int parent[DTT_MAX_VERTICES], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static int64_t dtt_far_at(const DttNode nodes[DTT_MAX_NODES], int node_id, int vertex) {
    const DttNode *node = &nodes[node_id];
    return node->endpoint0 == vertex ? node->far0 : node->far1;
}

static void dtt_recalculate(DttNode nodes[DTT_MAX_NODES], int node_id,
                            const int64_t weights[DTT_MAX_EDGES]) {
    DttNode *node = &nodes[node_id];
    if (node->kind == DTT_EDGE_BASE) {
        int64_t weight = weights[node->edge_id];
        node->length = node->far0 = node->far1 = node->diameter = weight;
    } else if (node->kind == DTT_RAKE_ZERO) {
        node->best1 = node->best2 = node->diameter = 0;
    } else if (node->kind == DTT_RAKE_MERGE) {
        const DttNode *left = &nodes[node->a], *right = &nodes[node->b];
        int64_t first = 0, second = 0;
        const int64_t arms[4] = {left->best1, left->best2, right->best1, right->best2};
        for (int i = 0; i < 4; ++i) {
            if (arms[i] >= first) { second = first; first = arms[i]; }
            else if (arms[i] > second) second = arms[i];
        }
        node->best1 = first;
        node->best2 = second;
        node->diameter = left->diameter > right->diameter ? left->diameter : right->diameter;
        if (left->best1 + right->best1 > node->diameter)
            node->diameter = left->best1 + right->best1;
    } else if (node->kind == DTT_RAKE_BRANCH) {
        const DttNode *edge = &nodes[node->a], *local = &nodes[node->b];
        int64_t center_far = dtt_far_at(nodes, node->a, node->endpoint0);
        int64_t pivot_far = dtt_far_at(nodes, node->a, node->pivot);
        node->best1 = center_far > edge->length + local->best1 ? center_far : edge->length + local->best1;
        node->best2 = 0;
        node->diameter = edge->diameter > local->diameter ? edge->diameter : local->diameter;
        if (pivot_far + local->best1 > node->diameter) node->diameter = pivot_far + local->best1;
    } else {
        const DttNode *first = &nodes[node->a], *second = &nodes[node->b], *local = &nodes[node->c];
        int y = node->endpoint0, z = node->endpoint1, x = node->pivot;
        int64_t first_y = dtt_far_at(nodes, node->a, y);
        int64_t first_x = dtt_far_at(nodes, node->a, x);
        int64_t second_x = dtt_far_at(nodes, node->b, x);
        int64_t second_z = dtt_far_at(nodes, node->b, z);
        node->length = first->length + second->length;
        int64_t from_y = first->length + (second_x > local->best1 ? second_x : local->best1);
        int64_t from_z = second->length + (first_x > local->best1 ? first_x : local->best1);
        node->far0 = first_y > from_y ? first_y : from_y;
        node->far1 = second_z > from_z ? second_z : from_z;
        node->diameter = first->diameter > second->diameter ? first->diameter : second->diameter;
        if (local->diameter > node->diameter) node->diameter = local->diameter;
        if (first_x + second_x > node->diameter) node->diameter = first_x + second_x;
        if (first_x + local->best1 > node->diameter) node->diameter = first_x + local->best1;
        if (second_x + local->best1 > node->diameter) node->diameter = second_x + local->best1;
    }
}

static int dtt_append(DttNode nodes[DTT_MAX_NODES], int *count, int kind,
                      const int64_t weights[DTT_MAX_EDGES], int a, int b, int c,
                      int endpoint0, int endpoint1, int pivot, int edge_id) {
    if (*count >= DTT_MAX_NODES) return -1;
    int node_id = (*count)++;
    DttNode *node = &nodes[node_id];
    node->kind = (int16_t)kind;
    node->a = (int16_t)a; node->b = (int16_t)b; node->c = (int16_t)c;
    node->parent = -1;
    node->endpoint0 = (int16_t)endpoint0; node->endpoint1 = (int16_t)endpoint1;
    node->pivot = (int16_t)pivot; node->edge_id = (int16_t)edge_id;
    node->length = node->far0 = node->far1 = node->diameter = 0;
    node->best1 = node->best2 = 0;
    if (a >= 0) nodes[a].parent = (int16_t)node_id;
    if (b >= 0) nodes[b].parent = (int16_t)node_id;
    if (c >= 0) nodes[c].parent = (int16_t)node_id;
    dtt_recalculate(nodes, node_id, weights);
    return node_id;
}

static int dtt_make_rake(DttNode nodes[DTT_MAX_NODES], int *node_count,
                         const int64_t weights[DTT_MAX_EDGES], int base,
                         const int16_t branch_ids[DTT_MAX_VERTICES], int branch_count) {
    int16_t level[DTT_MAX_VERTICES + 1], next[DTT_MAX_VERTICES + 1];
    int count = 1;
    level[0] = (int16_t)base;
    for (int i = 0; i < branch_count; ++i) level[count++] = branch_ids[i];
    while (count > 1) {
        int next_count = 0;
        for (int i = 0; i < count; i += 2) {
            if (i + 1 == count) next[next_count++] = level[i];
            else {
                int merged = dtt_append(nodes, node_count, DTT_RAKE_MERGE, weights,
                                        level[i], level[i + 1], -1, -1, -1, -1, -1);
                if (merged < 0) return -1;
                next[next_count++] = (int16_t)merged;
            }
        }
        for (int i = 0; i < next_count; ++i) level[i] = next[i];
        count = next_count;
    }
    return level[0];
}

static int dtt_neighbor_count(const bool adjacency[DTT_MAX_VERTICES][DTT_MAX_VERTICES],
                              const bool active[DTT_MAX_VERTICES], int n, int vertex,
                              int output[2]) {
    int count = 0;
    for (int other = 0; other < n; ++other) {
        if (active[other] && adjacency[vertex][other]) {
            if (count < 2) output[count] = other;
            ++count;
        }
    }
    return count;
}

int64_t dynamic_top_tree_component_diameter(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > DTT_MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > DTT_MAX_VERTICES || q_value < 0 || q_value > DTT_MAX_OPERATIONS) return -1;
    int n = (int)n_value, q = (int)q_value;
    int edge_end = 2 + 3 * (n - 1);
    if (length != (size_t)(edge_end + 3 * q)) return -1;

    int edge_u[DTT_MAX_EDGES], edge_v[DTT_MAX_EDGES], dsu[DTT_MAX_VERTICES];
    int64_t weights[DTT_MAX_EDGES] = {0};
    for (int i = 0; i < n; ++i) dsu[i] = i;
    for (int edge_id = 0; edge_id < n - 1; ++edge_id) {
        int offset = 2 + 3 * edge_id;
        int64_t u_value = input[offset], v_value = input[offset + 1], weight = input[offset + 2];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value ||
            weight < 0 || weight > DTT_MAX_WEIGHT) return -1;
        int u = (int)u_value, v = (int)v_value;
        int ru = dtt_find_root(dsu, u), rv = dtt_find_root(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        edge_u[edge_id] = u; edge_v[edge_id] = v; weights[edge_id] = weight;
    }
    for (int vertex = 1; vertex < n; ++vertex)
        if (dtt_find_root(dsu, vertex) != dtt_find_root(dsu, 0)) return -1;

    int op_code[DTT_MAX_OPERATIONS], op_edge[DTT_MAX_OPERATIONS], op_value[DTT_MAX_OPERATIONS];
    int query_count = 0;
    for (int op = 0; op < q; ++op) {
        int offset = edge_end + 3 * op;
        int64_t opcode = input[offset], edge_id = input[offset + 1], value = input[offset + 2];
        if (opcode == 0) {
            if (edge_id < 0 || edge_id >= n - 1 || value < 0 || value > DTT_MAX_WEIGHT) return -1;
        } else if (opcode == 1) {
            if (edge_id != 0 || value != 0) return -1;
            ++query_count;
        } else return -1;
        op_code[op] = (int)opcode; op_edge[op] = (int)edge_id; op_value[op] = (int)value;
    }
    size_t output_bytes = (size_t)query_count * 8;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;

    DttNode nodes[DTT_MAX_NODES];
    int node_count = 0, base_rake[DTT_MAX_VERTICES], base_edge[DTT_MAX_EDGES];
    bool adjacency[DTT_MAX_VERTICES][DTT_MAX_VERTICES] = {{false}};
    bool active[DTT_MAX_VERTICES] = {false};
    int16_t edge_cluster[DTT_MAX_VERTICES][DTT_MAX_VERTICES];
    int16_t branches[DTT_MAX_VERTICES][DTT_MAX_VERTICES];
    int branch_count[DTT_MAX_VERTICES] = {0};
    for (int u = 0; u < DTT_MAX_VERTICES; ++u)
        for (int v = 0; v < DTT_MAX_VERTICES; ++v) edge_cluster[u][v] = -1;
    for (int vertex = 0; vertex < n; ++vertex) {
        active[vertex] = true;
        base_rake[vertex] = dtt_append(nodes, &node_count, DTT_RAKE_ZERO, weights,
                                       -1, -1, -1, -1, -1, -1, -1);
        if (base_rake[vertex] < 0) return -1;
    }
    for (int edge_id = 0; edge_id < n - 1; ++edge_id) {
        int u = edge_u[edge_id], v = edge_v[edge_id];
        int cluster = dtt_append(nodes, &node_count, DTT_EDGE_BASE, weights,
                                 -1, -1, -1, u, v, -1, edge_id);
        if (cluster < 0) return -1;
        base_edge[edge_id] = cluster;
        adjacency[u][v] = adjacency[v][u] = true;
        edge_cluster[u][v] = edge_cluster[v][u] = (int16_t)cluster;
    }

    int active_count = n;
    while (active_count > 1) {
        if (active_count == 2) {
            int pair[2], found = 0;
            for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) pair[found++] = vertex;
            int x = pair[0], y = pair[1];
            int local = dtt_make_rake(nodes, &node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            int branch = dtt_append(nodes, &node_count, DTT_RAKE_BRANCH, weights,
                                    edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0) return -1;
            branches[y][branch_count[y]++] = (int16_t)branch;
            adjacency[x][y] = adjacency[y][x] = false;
            active[x] = false;
            --active_count;
            break;
        }

        int leaves[DTT_MAX_VERTICES], leaf_neighbor[DTT_MAX_VERTICES], leaf_count = 0;
        for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) {
            int adjacent[2];
            if (dtt_neighbor_count(adjacency, active, n, vertex, adjacent) == 1) {
                leaves[leaf_count] = vertex;
                leaf_neighbor[leaf_count++] = adjacent[0];
            }
        }
        for (int i = 0; i < leaf_count; ++i) {
            int x = leaves[i], y = leaf_neighbor[i];
            int local = dtt_make_rake(nodes, &node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            int branch = dtt_append(nodes, &node_count, DTT_RAKE_BRANCH, weights,
                                    edge_cluster[x][y], local, -1, y, -1, x, -1);
            if (branch < 0 || branch_count[y] >= DTT_MAX_VERTICES) return -1;
            branches[y][branch_count[y]++] = (int16_t)branch;
        }
        for (int i = 0; i < leaf_count; ++i) {
            int x = leaves[i], y = leaf_neighbor[i];
            adjacency[x][y] = adjacency[y][x] = false;
            edge_cluster[x][y] = edge_cluster[y][x] = -1;
            active[x] = false;
            --active_count;
        }
        if (active_count <= 1) break;

        bool chosen[DTT_MAX_VERTICES] = {false};
        int compress_vertices[DTT_MAX_VERTICES], compress_count = 0;
        for (int x = 0; x < n; ++x) if (active[x]) {
            int adjacent[2];
            if (dtt_neighbor_count(adjacency, active, n, x, adjacent) != 2) continue;
            if (!chosen[adjacent[0]] && !chosen[adjacent[1]]) {
                chosen[x] = true;
                compress_vertices[compress_count++] = x;
            }
        }
        int pending_x[DTT_MAX_VERTICES], pending_y[DTT_MAX_VERTICES];
        int pending_z[DTT_MAX_VERTICES], pending_cluster[DTT_MAX_VERTICES];
        for (int i = 0; i < compress_count; ++i) {
            int x = compress_vertices[i], adjacent[2];
            dtt_neighbor_count(adjacency, active, n, x, adjacent);
            int y = adjacent[0], z = adjacent[1];
            int local = dtt_make_rake(nodes, &node_count, weights, base_rake[x], branches[x], branch_count[x]);
            if (local < 0) return -1;
            int compressed = dtt_append(nodes, &node_count, DTT_EDGE_COMPRESS, weights,
                                        edge_cluster[y][x], edge_cluster[x][z], local,
                                        y, z, x, -1);
            if (compressed < 0) return -1;
            pending_x[i] = x; pending_y[i] = y; pending_z[i] = z; pending_cluster[i] = compressed;
        }
        for (int i = 0; i < compress_count; ++i) {
            int x = pending_x[i], y = pending_y[i], z = pending_z[i];
            adjacency[y][x] = adjacency[x][y] = false;
            adjacency[x][z] = adjacency[z][x] = false;
            edge_cluster[y][x] = edge_cluster[x][y] = -1;
            edge_cluster[x][z] = edge_cluster[z][x] = -1;
            active[x] = false;
            --active_count;
        }
        for (int i = 0; i < compress_count; ++i) {
            int y = pending_y[i], z = pending_z[i];
            adjacency[y][z] = adjacency[z][y] = true;
            edge_cluster[y][z] = edge_cluster[z][y] = (int16_t)pending_cluster[i];
        }
    }

    int root_vertex = 0;
    while (!active[root_vertex]) ++root_vertex;
    int root = dtt_make_rake(nodes, &node_count, weights, base_rake[root_vertex],
                             branches[root_vertex], branch_count[root_vertex]);
    int64_t staged[DTT_MAX_OPERATIONS];
    int staged_count = 0;
    for (int op = 0; op < q; ++op) {
        if (op_code[op] == 0) {
            int edge_id = op_edge[op];
            weights[edge_id] = op_value[op];
            int node_id = base_edge[edge_id];
            dtt_recalculate(nodes, node_id, weights);
            int ancestor = nodes[node_id].parent;
            while (ancestor >= 0) {
                dtt_recalculate(nodes, ancestor, weights);
                ancestor = nodes[ancestor].parent;
            }
        } else staged[staged_count++] = nodes[root].diameter;
    }
    for (int i = 0; i < staged_count; ++i) {
        uint64_t bits = (uint64_t)staged[i];
        for (int byte = 0; byte < 8; ++byte) output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)output_bytes;
}
