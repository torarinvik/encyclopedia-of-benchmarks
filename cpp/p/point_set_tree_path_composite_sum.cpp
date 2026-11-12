#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PTS_MAX_N 16
#define PTS_MAX_Q 32
#define PTS_MAX_E 15
#define PTS_MAX_CLUSTERS 75
#define PTS_MAX_INPUT 238
#define PTS_MOD INT64_C(998244353)

enum { PTS_VERTEX = 0, PTS_EDGE = 1, PTS_RAKE = 2,
       PTS_BRANCH = 3, PTS_ATTACH = 4, PTS_COMPRESS = 5 };

typedef struct { int64_t mul, add; } PtsAffine;
typedef struct {
    int16_t kind, a, b, parent, shared, boundary0, boundary1, boundary_count, edge_id;
    uint8_t has0, has1;
    uint16_t mask;
    int32_t count;
    int64_t sum0, sum1;
    PtsAffine forward, reverse;
} PtsCluster;
typedef struct { int64_t sum0, count0, sum1, count1; } PtsContext;

static int64_t pts_mod(int64_t x) {
    x %= PTS_MOD;
    return x < 0 ? x + PTS_MOD : x;
}

static PtsAffine pts_identity(void) { return PtsAffine{1, 0}; }

static PtsAffine pts_compose(PtsAffine outer, PtsAffine inner) {
    return PtsAffine{outer.mul * inner.mul % PTS_MOD,
                     (outer.mul * inner.add + outer.add) % PTS_MOD};
}

static int64_t pts_apply(PtsAffine map, int64_t sum, int64_t count) {
    return (map.mul * sum + map.add * count) % PTS_MOD;
}

static int pts_boundary_index(const PtsCluster *node, int vertex) {
    if (node->boundary0 == vertex) return 0;
    if (node->boundary_count == 2 && node->boundary1 == vertex) return 1;
    return -1;
}

static bool pts_has(const PtsCluster *node, int vertex) {
    int index = pts_boundary_index(node, vertex);
    return index == 0 ? node->has0 : index == 1 ? node->has1 : false;
}

static int64_t pts_sum_at(const PtsCluster *node, int vertex) {
    return pts_boundary_index(node, vertex) == 0 ? node->sum0 : node->sum1;
}

static PtsAffine pts_map_at(const PtsCluster *node, int from, int to) {
    if (from == to || node->boundary_count != 2) return pts_identity();
    return node->boundary0 == from && node->boundary1 == to ? node->forward : node->reverse;
}

static void pts_recalculate(PtsCluster nodes[PTS_MAX_CLUSTERS], int id,
                            const int64_t values[PTS_MAX_N],
                            const PtsAffine edge_map[PTS_MAX_E]) {
    PtsCluster *p = &nodes[id];
    if (p->kind == PTS_VERTEX) {
        p->count = 1;
        p->mask = (uint16_t)(1U << p->boundary0);
        p->sum0 = values[p->boundary0];
        p->has0 = 1;
        return;
    }
    if (p->kind == PTS_EDGE) {
        p->forward = p->reverse = edge_map[p->edge_id];
        return;
    }
    const PtsCluster *a = &nodes[p->a], *b = &nodes[p->b];
    int x = p->shared;
    bool overlap = pts_has(a, x) && pts_has(b, x);
    int duplicate_count = overlap ? 1 : 0;
    int64_t duplicate = overlap ? values[x] : 0;
    p->count = a->count + b->count - duplicate_count;
    p->mask = (uint16_t)(a->mask | b->mask);
    int boundaries[2] = {p->boundary0, p->boundary1};
    for (int index = 0; index < p->boundary_count; ++index) {
        int boundary = boundaries[index];
        int64_t total;
        if (boundary == x) {
            total = pts_mod(pts_sum_at(a, x) + pts_sum_at(b, x) - duplicate);
        } else if (pts_boundary_index(a, boundary) >= 0) {
            int64_t sibling_sum = pts_mod(pts_sum_at(b, x) - duplicate);
            total = (pts_sum_at(a, boundary) +
                     pts_apply(pts_map_at(a, boundary, x), sibling_sum,
                               b->count - duplicate_count)) % PTS_MOD;
        } else {
            int64_t sibling_sum = pts_mod(pts_sum_at(a, x) - duplicate);
            total = (pts_sum_at(b, boundary) +
                     pts_apply(pts_map_at(b, boundary, x), sibling_sum,
                               a->count - duplicate_count)) % PTS_MOD;
        }
        if (index == 0) {
            p->sum0 = total;
            p->has0 = pts_has(a, boundary) || pts_has(b, boundary);
        } else {
            p->sum1 = total;
            p->has1 = pts_has(a, boundary) || pts_has(b, boundary);
        }
    }
    if (p->boundary_count == 2) {
        int u = p->boundary0, v = p->boundary1;
        bool a_has_u = pts_boundary_index(a, u) >= 0;
        bool a_has_v = pts_boundary_index(a, v) >= 0;
        bool b_has_u = pts_boundary_index(b, u) >= 0;
        bool b_has_v = pts_boundary_index(b, v) >= 0;
        if (a_has_u && a_has_v) {
            p->forward = pts_map_at(a, u, v);
            p->reverse = pts_map_at(a, v, u);
        } else if (b_has_u && b_has_v) {
            p->forward = pts_map_at(b, u, v);
            p->reverse = pts_map_at(b, v, u);
        } else {
            p->forward = pts_compose(pts_map_at(a, u, x), pts_map_at(b, x, v));
            p->reverse = pts_compose(pts_map_at(b, v, x), pts_map_at(a, x, u));
        }
    }
}

static int pts_append(PtsCluster nodes[PTS_MAX_CLUSTERS], int *count,
                      int kind, int a_id, int b_id, int shared,
                      const int64_t values[PTS_MAX_N],
                      const PtsAffine edge_map[PTS_MAX_E]) {
    if (*count >= PTS_MAX_CLUSTERS) return -1;
    int id = (*count)++;
    PtsCluster *node = &nodes[id];
    *node = PtsCluster{};
    node->kind = (int16_t)kind;
    node->a = (int16_t)a_id;
    node->b = (int16_t)b_id;
    node->parent = -1;
    node->shared = (int16_t)shared;
    node->edge_id = -1;
    node->forward = node->reverse = pts_identity();
    if (kind == PTS_VERTEX) {
        node->boundary0 = (int16_t)shared;
        node->boundary_count = 1;
    } else if (kind == PTS_EDGE) {
        node->boundary0 = (int16_t)a_id;
        node->boundary1 = (int16_t)b_id;
        node->boundary_count = 2;
        node->edge_id = (int16_t)shared;
    } else {
        PtsCluster *a = &nodes[a_id], *b = &nodes[b_id];
        int a_other = a->boundary_count == 2 && a->boundary0 == shared ? a->boundary1 : a->boundary0;
        int b_other = b->boundary_count == 2 && b->boundary0 == shared ? b->boundary1 : b->boundary0;
        if (kind == PTS_RAKE) {
            node->boundary0 = (int16_t)shared;
            node->boundary_count = 1;
        } else if (kind == PTS_BRANCH) {
            node->boundary0 = (int16_t)a_other;
            node->boundary_count = 1;
        } else if (kind == PTS_ATTACH) {
            node->boundary0 = a->boundary0;
            node->boundary1 = a->boundary1;
            node->boundary_count = 2;
        } else {
            node->boundary0 = (int16_t)a_other;
            node->boundary1 = (int16_t)b_other;
            node->boundary_count = 2;
        }
        a->parent = (int16_t)id;
        b->parent = (int16_t)id;
    }
    pts_recalculate(nodes, id, values, edge_map);
    return id;
}

static int pts_make_rake(PtsCluster nodes[PTS_MAX_CLUSTERS], int *node_count,
                         int base, const int *branches, int branch_count,
                         const int64_t values[PTS_MAX_N],
                         const PtsAffine edge_map[PTS_MAX_E]) {
    int level[PTS_MAX_N + 1], next[PTS_MAX_N + 1];
    int count = 1;
    level[0] = base;
    for (int i = 0; i < branch_count; ++i) level[count++] = branches[i];
    while (count > 1) {
        int next_count = 0;
        for (int i = 0; i < count; i += 2) {
            if (i + 1 == count) next[next_count++] = level[i];
            else {
                int merged = pts_append(nodes, node_count, PTS_RAKE,
                    level[i], level[i + 1], nodes[level[i]].boundary0, values, edge_map);
                if (merged < 0) return -1;
                next[next_count++] = merged;
            }
        }
        for (int i = 0; i < next_count; ++i) level[i] = next[i];
        count = next_count;
    }
    return level[0];
}

static int pts_neighbor_count(const bool adjacency[PTS_MAX_N][PTS_MAX_N],
                              const bool active[PTS_MAX_N], int n, int vertex,
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

static int pts_find(size_t parent[PTS_MAX_N], int vertex) {
    size_t v = (size_t)vertex;
    while (parent[v] != v) { parent[v] = parent[parent[v]]; v = parent[v]; }
    return (int)v;
}

static void pts_context_at(const PtsCluster *parent, const PtsContext *context,
                           int vertex, int64_t *sum, int64_t *count) {
    int index = pts_boundary_index(parent, vertex);
    *sum = index == 0 ? context->sum0 : index == 1 ? context->sum1 : 0;
    *count = index == 0 ? context->count0 : index == 1 ? context->count1 : 0;
}

static PtsContext pts_child_context(const PtsCluster nodes[PTS_MAX_CLUSTERS],
                                    int parent_id, int child_id,
                                    PtsContext context,
                                    const int64_t values[PTS_MAX_N]) {
    const PtsCluster *parent = &nodes[parent_id];
    const PtsCluster *child = &nodes[child_id];
    int sibling_id = child_id == parent->a ? parent->b : parent->a;
    const PtsCluster *sibling = &nodes[sibling_id];
    int x = parent->shared;
    bool overlap = pts_has(child, x) && pts_has(sibling, x);
    int64_t count_at_x = sibling->count - (overlap ? 1 : 0);
    int64_t sum_at_x = pts_mod(pts_sum_at(sibling, x) - (overlap ? values[x] : 0));
    for (int i = 0; i < sibling->boundary_count; ++i) {
        int boundary = i == 0 ? sibling->boundary0 : sibling->boundary1;
        if (pts_boundary_index(parent, boundary) < 0) continue;
        int64_t outside_sum, outside_count;
        pts_context_at(parent, &context, boundary, &outside_sum, &outside_count);
        sum_at_x = (sum_at_x + pts_apply(pts_map_at(sibling, x, boundary),
                                         outside_sum, outside_count)) % PTS_MOD;
        count_at_x += outside_count;
    }
    PtsContext result = {0};
    for (int i = 0; i < child->boundary_count; ++i) {
        int boundary = i == 0 ? child->boundary0 : child->boundary1;
        int64_t out_sum, out_count;
        if (boundary == x) {
            out_sum = sum_at_x;
            out_count = count_at_x;
        } else {
            out_sum = pts_apply(pts_map_at(child, boundary, x), sum_at_x, count_at_x);
            out_count = count_at_x;
            if (pts_boundary_index(parent, boundary) >= 0) {
                int64_t outside_sum, outside_count;
                pts_context_at(parent, &context, boundary, &outside_sum, &outside_count);
                out_sum = (out_sum + outside_sum) % PTS_MOD;
                out_count += outside_count;
            }
        }
        if (i == 0) { result.sum0 = out_sum; result.count0 = out_count; }
        else { result.sum1 = out_sum; result.count1 = out_count; }
    }
    return result;
}

static int64_t pts_query(const PtsCluster nodes[PTS_MAX_CLUSTERS], int root,
                         const int vertex_leaf[PTS_MAX_N], int vertex,
                         const int64_t values[PTS_MAX_N]) {
    int path[PTS_MAX_CLUSTERS];
    int path_len = 1;
    path[0] = vertex_leaf[vertex];
    while (path[path_len - 1] != root && path_len < PTS_MAX_CLUSTERS) {
        int parent = nodes[path[path_len - 1]].parent;
        if (parent < 0) return -1;
        path[path_len++] = parent;
    }
    if (path[path_len - 1] != root) return -1;
    PtsContext context = {0};
    for (int i = path_len - 1; i > 0; --i)
        context = pts_child_context(nodes, path[i], path[i - 1], context, values);
    return (nodes[vertex_leaf[vertex]].sum0 + context.sum0) % PTS_MOD;
}

static void pts_store(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t point_set_tree_path_composite_sum(const int64_t *input, size_t length,
                                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > PTS_MAX_INPUT) return -1;
    int64_t n_raw = input[0], q_raw = input[1];
    if (n_raw < 1 || n_raw > PTS_MAX_N || q_raw < 1 || q_raw > PTS_MAX_Q) return -1;
    int n = (int)n_raw, q = (int)q_raw, cursor = 2;
    int64_t values[PTS_MAX_N] = {0};
    for (int v = 0; v < n; ++v) {
        if (cursor >= (int)length) return -1;
        values[v] = input[cursor++];
        if (values[v] < 0 || values[v] >= PTS_MOD) return -1;
    }
    int edge_u[PTS_MAX_E], edge_v[PTS_MAX_E];
    PtsAffine edge_map[PTS_MAX_E];
    size_t dsu[PTS_MAX_N];
    for (int v = 0; v < n; ++v) dsu[v] = (size_t)v;
    for (int e = 0; e < n - 1; ++e) {
        if (cursor + 4 > (int)length) return -1;
        int64_t ur = input[cursor++], vr = input[cursor++];
        int64_t mul = input[cursor++], add = input[cursor++];
        if (ur < 0 || ur >= n || vr < 0 || vr >= n || ur == vr ||
            mul < 1 || mul >= PTS_MOD || add < 0 || add >= PTS_MOD) return -1;
        int u = (int)ur, v = (int)vr;
        int ru = pts_find(dsu, u), rv = pts_find(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = (size_t)rv;
        edge_u[e] = u; edge_v[e] = v; edge_map[e] = PtsAffine{mul, add};
    }
    for (int v = 1; v < n; ++v) if (pts_find(dsu, v) != pts_find(dsu, 0)) return -1;

    int op_code[PTS_MAX_Q], op_item[PTS_MAX_Q], op_root[PTS_MAX_Q];
    int64_t op_first[PTS_MAX_Q], op_second[PTS_MAX_Q];
    for (int i = 0; i < q; ++i) {
        if (cursor >= (int)length) return -1;
        int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 3 > (int)length) return -1;
            int64_t item = input[cursor++], value = input[cursor++], root = input[cursor++];
            if (item < 0 || item >= n || value < 0 || value >= PTS_MOD || root < 0 || root >= n) return -1;
            op_code[i] = 0; op_item[i] = (int)item; op_first[i] = value; op_second[i] = 0; op_root[i] = (int)root;
        } else if (opcode == 1) {
            if (cursor + 4 > (int)length) return -1;
            int64_t item = input[cursor++], mul = input[cursor++], add = input[cursor++], root = input[cursor++];
            if (item < 0 || item >= n - 1 || mul < 1 || mul >= PTS_MOD || add < 0 || add >= PTS_MOD || root < 0 || root >= n) return -1;
            op_code[i] = 1; op_item[i] = (int)item; op_first[i] = mul; op_second[i] = add; op_root[i] = (int)root;
        } else return -1;
    }
    if (cursor != (int)length) return -1;
    size_t required = 8U * (size_t)q;
    if (output == NULL || capacity < required) return -2;

    PtsCluster nodes[PTS_MAX_CLUSTERS] = {0};
    int node_count = 0, vertex_leaf[PTS_MAX_N], edge_leaf[PTS_MAX_E];
    for (int v = 0; v < n; ++v) {
        int id = pts_append(nodes, &node_count, PTS_VERTEX, -1, -1, v, values, edge_map);
        if (id < 0) return -1;
        vertex_leaf[v] = id;
    }
    bool adjacency[PTS_MAX_N][PTS_MAX_N] = {{false}};
    int16_t edge_cluster[PTS_MAX_N][PTS_MAX_N];
    for (int u = 0; u < PTS_MAX_N; ++u) for (int v = 0; v < PTS_MAX_N; ++v) edge_cluster[u][v] = -1;
    for (int e = 0; e < n - 1; ++e) {
        int id = pts_append(nodes, &node_count, PTS_EDGE, edge_u[e], edge_v[e], e, values, edge_map);
        if (id < 0) return -1;
        edge_leaf[e] = id;
        adjacency[edge_u[e]][edge_v[e]] = adjacency[edge_v[e]][edge_u[e]] = true;
        edge_cluster[edge_u[e]][edge_v[e]] = edge_cluster[edge_v[e]][edge_u[e]] = (int16_t)id;
    }
    bool active[PTS_MAX_N] = {false};
    int branches[PTS_MAX_N][PTS_MAX_N] = {{0}}, branch_count[PTS_MAX_N] = {0};
    for (int v = 0; v < n; ++v) active[v] = true;
    int active_count = n;
    while (active_count > 1) {
        if (active_count == 2) {
            int pair[2], found = 0;
            for (int v = 0; v < n; ++v) if (active[v]) pair[found++] = v;
            int x = pair[0], y = pair[1];
            int local = pts_make_rake(nodes, &node_count, vertex_leaf[x], branches[x], branch_count[x], values, edge_map);
            if (local < 0) return -1;
            int edge = edge_cluster[x][y];
            int branch = pts_append(nodes, &node_count, PTS_BRANCH, edge, local, x, values, edge_map);
            if (branch < 0 || branch_count[y] >= PTS_MAX_N) return -1;
            branches[y][branch_count[y]++] = branch;
            adjacency[x][y] = adjacency[y][x] = false;
            edge_cluster[x][y] = edge_cluster[y][x] = -1;
            active[x] = false; --active_count;
            break;
        }
        int leaves[PTS_MAX_N], leaf_neighbor[PTS_MAX_N], leaf_count = 0;
        for (int v = 0; v < n; ++v) if (active[v]) {
            int adjacent[2];
            if (pts_neighbor_count(adjacency, active, n, v, adjacent) == 1) {
                leaves[leaf_count] = v; leaf_neighbor[leaf_count++] = adjacent[0];
            }
        }
        for (int i = 0; i < leaf_count; ++i) {
            int x = leaves[i], y = leaf_neighbor[i];
            int local = pts_make_rake(nodes, &node_count, vertex_leaf[x], branches[x], branch_count[x], values, edge_map);
            if (local < 0) return -1;
            int branch = pts_append(nodes, &node_count, PTS_BRANCH, edge_cluster[x][y], local, x, values, edge_map);
            if (branch < 0 || branch_count[y] >= PTS_MAX_N) return -1;
            branches[y][branch_count[y]++] = branch;
        }
        for (int i = 0; i < leaf_count; ++i) {
            int x = leaves[i], y = leaf_neighbor[i];
            adjacency[x][y] = adjacency[y][x] = false;
            edge_cluster[x][y] = edge_cluster[y][x] = -1;
            active[x] = false; --active_count;
        }
        if (active_count <= 1) break;
        bool chosen[PTS_MAX_N] = {false};
        int compress[PTS_MAX_N], compress_count = 0;
        for (int x = 0; x < n; ++x) if (active[x]) {
            int adjacent[2];
            if (pts_neighbor_count(adjacency, active, n, x, adjacent) != 2) continue;
            if (!chosen[adjacent[0]] && !chosen[adjacent[1]]) {
                chosen[x] = true; compress[compress_count++] = x;
            }
        }
        int px[PTS_MAX_N], py[PTS_MAX_N], pz[PTS_MAX_N], pc[PTS_MAX_N];
        for (int i = 0; i < compress_count; ++i) {
            int x = compress[i], adjacent[2];
            (void)pts_neighbor_count(adjacency, active, n, x, adjacent);
            int y = adjacent[0], z = adjacent[1];
            int local = pts_make_rake(nodes, &node_count, vertex_leaf[x], branches[x], branch_count[x], values, edge_map);
            if (local < 0) return -1;
            int attached = pts_append(nodes, &node_count, PTS_ATTACH, edge_cluster[y][x], local, x, values, edge_map);
            if (attached < 0) return -1;
            int compressed = pts_append(nodes, &node_count, PTS_COMPRESS, attached, edge_cluster[x][z], x, values, edge_map);
            if (compressed < 0) return -1;
            px[i] = x; py[i] = y; pz[i] = z; pc[i] = compressed;
        }
        for (int i = 0; i < compress_count; ++i) {
            int x = px[i], y = py[i], z = pz[i];
            adjacency[y][x] = adjacency[x][y] = false; adjacency[x][z] = adjacency[z][x] = false;
            edge_cluster[y][x] = edge_cluster[x][y] = -1; edge_cluster[x][z] = edge_cluster[z][x] = -1;
            active[x] = false; --active_count;
        }
        for (int i = 0; i < compress_count; ++i) {
            int y = py[i], z = pz[i];
            adjacency[y][z] = adjacency[z][y] = true;
            edge_cluster[y][z] = edge_cluster[z][y] = (int16_t)pc[i];
        }
    }
    int root_vertex = 0; while (!active[root_vertex]) ++root_vertex;
    int root = pts_make_rake(nodes, &node_count, vertex_leaf[root_vertex], branches[root_vertex], branch_count[root_vertex], values, edge_map);
    if (root < 0) return -1;

    int64_t answers[PTS_MAX_Q];
    for (int i = 0; i < q; ++i) {
        int item = op_item[i], node_id;
        if (op_code[i] == 0) {
            values[item] = op_first[i];
            node_id = vertex_leaf[item];
            pts_recalculate(nodes, node_id, values, edge_map);
        } else {
            edge_map[item] = PtsAffine{op_first[i], op_second[i]};
            node_id = edge_leaf[item];
            pts_recalculate(nodes, node_id, values, edge_map);
        }
        int ancestor = nodes[node_id].parent;
        while (ancestor >= 0) {
            pts_recalculate(nodes, ancestor, values, edge_map);
            ancestor = nodes[ancestor].parent;
        }
        answers[i] = pts_query(nodes, root, vertex_leaf, op_root[i], values);
        if (answers[i] < 0) return -1;
    }
    for (int i = 0; i < q; ++i) pts_store(output, 8U * (size_t)i, answers[i]);
    return (int64_t)required;
}
