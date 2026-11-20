#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    FR_MAX_N = 12,
    FR_MAX_ARCS = 60,
    FR_MAX_PIECES = 119,
    FR_MAX_BOUNDARY = 12,
    FR_MAX_BLOCKS = 44,
    FR_MAX_UNION_NODES = 24,
    FR_MAX_BASE_ARCS = 3,
    FR_MAX_INPUT = 2088,
    FR_MAX_WEIGHT = 100
};

#define FR_INF INT64_C(1152921504606846976)

typedef struct {
    int left;
    int right;
    int boundary_count;
    uint64_t arc_mask;
    uint16_t vertex_mask;
    int boundary[FR_MAX_BOUNDARY];
} FrPiece;

typedef struct {
    int tail;
    int head;
    int64_t weight;
} FrArc;

typedef struct {
    int child;
    int row_count;
    int column_count;
    int rows[FR_MAX_BOUNDARY];
    int columns[FR_MAX_BOUNDARY];
    int64_t weights[FR_MAX_BOUNDARY][FR_MAX_BOUNDARY];
    int64_t best_value[FR_MAX_BOUNDARY];
    int best_row[FR_MAX_BOUNDARY];
} FrBlock;

static FrPiece fr_pieces[FR_MAX_PIECES];
static FrArc fr_arcs[FR_MAX_ARCS];
static int fr_n, fr_m, fr_source, fr_piece_count;
static int64_t fr_ddg[FR_MAX_PIECES][FR_MAX_N][FR_MAX_N];
static int64_t fr_potential[FR_MAX_PIECES][FR_MAX_N];
static FrBlock fr_block_workspace[FR_MAX_BLOCKS];

static int fr_popcount16(uint16_t value) {
    int count = 0;
    while (value != 0) {
        count += (int)(value & 1u);
        value = (uint16_t)(value >> 1);
    }
    return count;
}

static int fr_popcount64(uint64_t value) {
    int count = 0;
    while (value != 0) {
        count += (int)(value & UINT64_C(1));
        value >>= 1;
    }
    return count;
}

static bool fr_piece_connected(uint64_t arc_mask, uint16_t vertex_mask) {
    if (vertex_mask == 0) return false;
    int start = 0;
    while ((vertex_mask & (uint16_t)(1u << start)) == 0) ++start;
    uint16_t reached = (uint16_t)(1u << start);
    bool changed = true;
    while (changed) {
        changed = false;
        for (int edge = 0; edge < fr_m; ++edge) {
            if ((arc_mask & (UINT64_C(1) << edge)) == 0) continue;
            const int u = fr_arcs[edge].tail;
            const int v = fr_arcs[edge].head;
            if ((reached & (uint16_t)(1u << u)) != 0 &&
                (reached & (uint16_t)(1u << v)) == 0) {
                reached |= (uint16_t)(1u << v);
                changed = true;
            }
            if ((reached & (uint16_t)(1u << v)) != 0 &&
                (reached & (uint16_t)(1u << u)) == 0) {
                reached |= (uint16_t)(1u << u);
                changed = true;
            }
        }
    }
    return reached == vertex_mask;
}

static uint16_t fr_vertex_mask_for_arcs(uint64_t arc_mask) {
    uint16_t mask = 0;
    for (int edge = 0; edge < fr_m; ++edge) {
        if ((arc_mask & (UINT64_C(1) << edge)) == 0) continue;
        mask |= (uint16_t)(1u << fr_arcs[edge].tail);
        mask |= (uint16_t)(1u << fr_arcs[edge].head);
    }
    return mask;
}

static bool fr_parse(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > FR_MAX_INPUT) return false;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    const int64_t source_value = input[2];
    const int64_t pieces_value = input[3];
    if (n_value < 2 || n_value > FR_MAX_N || m_value < 1 || m_value > FR_MAX_ARCS ||
        source_value < 0 || source_value >= n_value || pieces_value < 1 ||
        pieces_value > FR_MAX_PIECES || (pieces_value & 1) == 0) return false;
    fr_n = (int)n_value;
    fr_m = (int)m_value;
    fr_source = (int)source_value;
    fr_piece_count = (int)pieces_value;

    bool seen_arc[FR_MAX_N][FR_MAX_N] = {{false}};
    bool seen_pair[FR_MAX_N][FR_MAX_N] = {{false}};
    int undirected_edges = 0;
    size_t offset = 4;
    for (int edge = 0; edge < fr_m; ++edge) {
        if (offset + 3 > length) return false;
        const int64_t u_value = input[offset++];
        const int64_t v_value = input[offset++];
        const int64_t weight = input[offset++];
        if (u_value < 0 || u_value >= fr_n || v_value < 0 || v_value >= fr_n ||
            u_value == v_value || weight < -FR_MAX_WEIGHT || weight > FR_MAX_WEIGHT) return false;
        const int u = (int)u_value, v = (int)v_value;
        if (seen_arc[u][v]) return false;
        seen_arc[u][v] = true;
        if (!seen_pair[u][v]) {
            seen_pair[u][v] = seen_pair[v][u] = true;
            ++undirected_edges;
        }
        fr_arcs[edge] = (FrArc){u, v, weight};
    }
    const int simple_edge_limit = fr_n == 2 ? 1 : 3 * fr_n - 6;
    if (undirected_edges > simple_edge_limit || fr_m > 2 * simple_edge_limit) return false;

    bool visited[FR_MAX_N] = {false};
    int queue[FR_MAX_N], head = 0, tail = 0;
    visited[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const int u = queue[head++];
        for (int edge = 0; edge < fr_m; ++edge) {
            const int a = fr_arcs[edge].tail, b = fr_arcs[edge].head;
            int v = -1;
            if (a == u) v = b;
            else if (b == u) v = a;
            if (v >= 0 && !visited[v]) {
                visited[v] = true;
                queue[tail++] = v;
            }
        }
    }
    for (int v = 0; v < fr_n; ++v) if (!visited[v]) return false;

    int parent_count[FR_MAX_PIECES] = {0};
    uint64_t leaf_union = 0;
    int leaf_count = 0;
    const uint64_t full_arc_mask = (UINT64_C(1) << fr_m) - 1;
    for (int index = 0; index < fr_piece_count; ++index) {
        if (offset + 4 > length) return false;
        const int64_t left_value = input[offset++];
        const int64_t right_value = input[offset++];
        const int64_t mask_value = input[offset++];
        const int64_t boundary_count_value = input[offset++];
        if (boundary_count_value < 1 || boundary_count_value > FR_MAX_BOUNDARY ||
            boundary_count_value > fr_n || offset + (size_t)boundary_count_value > length) return false;
        FrPiece *piece = &fr_pieces[index];
        piece->left = (int)left_value;
        piece->right = (int)right_value;
        piece->boundary_count = (int)boundary_count_value;
        uint16_t listed_boundary = 0;
        for (int i = 0; i < piece->boundary_count; ++i) {
            const int64_t vertex_value = input[offset++];
            if (vertex_value < 0 || vertex_value >= fr_n) return false;
            const int vertex = (int)vertex_value;
            const uint16_t bit = (uint16_t)(1u << vertex);
            if (listed_boundary & bit) return false;
            listed_boundary |= bit;
            piece->boundary[i] = vertex;
        }

        if (left_value == -1 && right_value == -1) {
            if (mask_value <= 0) return false;
            const uint64_t mask = (uint64_t)mask_value;
            if ((mask & ~full_arc_mask) != 0 || fr_popcount64(mask) > FR_MAX_BASE_ARCS ||
                (leaf_union & mask) != 0) return false;
            piece->arc_mask = mask;
            leaf_union |= mask;
            ++leaf_count;
            piece->vertex_mask = fr_vertex_mask_for_arcs(mask);
            if (!fr_piece_connected(mask, piece->vertex_mask)) return false;
        } else {
            if (left_value < 0 || right_value < 0 || left_value >= index ||
                right_value >= index || left_value == right_value || mask_value != -1) return false;
            const int left = (int)left_value, right = (int)right_value;
            if (parent_count[left] != 0 || parent_count[right] != 0) return false;
            parent_count[left] = parent_count[right] = 1;
            FrPiece *left_piece = &fr_pieces[left], *right_piece = &fr_pieces[right];
            if (left_piece->arc_mask & right_piece->arc_mask) return false;
            piece->arc_mask = left_piece->arc_mask | right_piece->arc_mask;
            piece->vertex_mask = left_piece->vertex_mask | right_piece->vertex_mask;
            const int parent_vertices = fr_popcount16(piece->vertex_mask);
            const int max_child_vertices = (2 * parent_vertices + 2) / 3;
            if (fr_popcount16(left_piece->vertex_mask) > max_child_vertices ||
                fr_popcount16(right_piece->vertex_mask) > max_child_vertices ||
                (left_piece->vertex_mask & right_piece->vertex_mask) == 0) return false;
        }

        uint16_t expected_boundary = 0;
        for (int vertex = 0; vertex < fr_n; ++vertex) {
            const uint16_t bit = (uint16_t)(1u << vertex);
            if ((piece->vertex_mask & bit) == 0) continue;
            if (vertex == fr_source) {
                expected_boundary |= bit;
                continue;
            }
            for (int edge = 0; edge < fr_m; ++edge) {
                if ((piece->arc_mask & (UINT64_C(1) << edge)) == 0 &&
                    (fr_arcs[edge].tail == vertex || fr_arcs[edge].head == vertex)) {
                    expected_boundary |= bit;
                    break;
                }
            }
        }
        if (listed_boundary != expected_boundary) return false;
        if (!fr_piece_connected(piece->arc_mask, piece->vertex_mask)) return false;
        if (index == fr_piece_count - 1 &&
            (piece->arc_mask != full_arc_mask || piece->vertex_mask != (uint16_t)((1u << fr_n) - 1u))) return false;
    }
    if (offset != length || fr_piece_count != 2 * leaf_count - 1 ||
        leaf_union != full_arc_mask || parent_count[fr_piece_count - 1] != 0) return false;
    for (int i = 0; i < fr_piece_count - 1; ++i) if (parent_count[i] != 1) return false;
    const FrPiece *root = &fr_pieces[fr_piece_count - 1];
    if (root->boundary_count != 1 || root->boundary[0] != fr_source) return false;
    return true;
}

static int fr_collect_arcs(uint64_t arc_mask, FrArc *out) {
    int count = 0;
    for (int edge = 0; edge < fr_m; ++edge)
        if (arc_mask & (UINT64_C(1) << edge)) out[count++] = fr_arcs[edge];
    return count;
}

static bool fr_bellman_ford_all(const int *nodes, int node_count,
                                const FrArc *arcs, int arc_count,
                                int64_t *labels) {
    for (int i = 0; i < node_count; ++i) labels[nodes[i]] = 0;
    for (int pass = 0; pass + 1 < node_count; ++pass) {
        bool changed = false;
        for (int edge = 0; edge < arc_count; ++edge) {
            const int u = arcs[edge].tail, v = arcs[edge].head;
            const int64_t candidate = labels[u] + arcs[edge].weight;
            if (candidate < labels[v]) {
                labels[v] = candidate;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (int edge = 0; edge < arc_count; ++edge) {
        const int u = arcs[edge].tail, v = arcs[edge].head;
        if (labels[u] + arcs[edge].weight < labels[v]) return false;
    }
    return true;
}

static bool fr_bellman_ford_seeded(const FrArc *arcs, int arc_count,
                                   const int64_t *seed_labels,
                                   int64_t *labels) {
    for (int v = 0; v < fr_n; ++v) labels[v] = seed_labels[v];
    for (int pass = 0; pass + 1 < fr_n; ++pass) {
        bool changed = false;
        for (int edge = 0; edge < arc_count; ++edge) {
            const int u = arcs[edge].tail, v = arcs[edge].head;
            if (labels[u] == FR_INF) continue;
            const int64_t candidate = labels[u] + arcs[edge].weight;
            if (candidate < labels[v]) {
                labels[v] = candidate;
                changed = true;
            }
        }
        if (!changed) break;
    }
    for (int edge = 0; edge < arc_count; ++edge) {
        const int u = arcs[edge].tail, v = arcs[edge].head;
        if (labels[u] != FR_INF && labels[u] + arcs[edge].weight < labels[v]) return false;
    }
    return true;
}

static int64_t fr_monge_sum(int64_t a, int64_t b) {
    return a == FR_INF || b == FR_INF ? FR_INF : a + b;
}

static bool fr_check_monge_rec(int piece_index, int lo, int hi) {
    if (hi - lo <= 1) return true;
    const FrPiece *piece = &fr_pieces[piece_index];
    const int middle = (lo + hi) / 2;
    for (int direction = 0; direction < 2; ++direction) {
        const int row_lo = direction == 0 ? lo : middle;
        const int row_hi = direction == 0 ? middle : hi;
        const int col_lo = direction == 0 ? middle : lo;
        const int col_hi = direction == 0 ? hi : middle;
        for (int i = row_lo; i < row_hi; ++i)
            for (int i2 = i + 1; i2 < row_hi; ++i2)
                for (int j = col_lo; j < col_hi; ++j)
                    for (int j2 = j + 1; j2 < col_hi; ++j2) {
                        const int u = piece->boundary[i], u2 = piece->boundary[i2];
                        const int v = piece->boundary[j], v2 = piece->boundary[j2];
                        const int64_t lhs = fr_monge_sum(fr_ddg[piece_index][u][v],
                                                         fr_ddg[piece_index][u2][v2]);
                        const int64_t rhs = fr_monge_sum(fr_ddg[piece_index][u][v2],
                                                         fr_ddg[piece_index][u2][v]);
                        if (lhs > rhs) return false;
                    }
    }
    return fr_check_monge_rec(piece_index, lo, middle) &&
           fr_check_monge_rec(piece_index, middle, hi);
}

static void fr_add_block(int child, const int *rows, int row_count,
                         const int *columns, int column_count,
                         const int64_t *potential, FrBlock *blocks,
                         int *block_count) {
    if (row_count == 0 || column_count == 0 || *block_count >= FR_MAX_BLOCKS) return;
    FrBlock *block = &blocks[(*block_count)++];
    block->child = child;
    block->row_count = row_count;
    block->column_count = column_count;
    for (int i = 0; i < row_count; ++i) block->rows[i] = rows[i];
    for (int j = 0; j < column_count; ++j) block->columns[j] = columns[j];
    for (int i = 0; i < row_count; ++i) for (int j = 0; j < column_count; ++j) {
        const int u = rows[i], v = columns[j];
        const int64_t distance = fr_ddg[child][u][v];
        block->weights[i][j] = distance == FR_INF ? FR_INF :
            distance + potential[u] - potential[v];
    }
}

static void fr_build_blocks_rec(int child, int lo, int hi,
                                const int64_t *potential,
                                FrBlock *blocks, int *block_count) {
    if (hi - lo <= 1) return;
    const FrPiece *piece = &fr_pieces[child];
    const int middle = (lo + hi) / 2;
    fr_add_block(child, piece->boundary + lo, middle - lo,
                 piece->boundary + middle, hi - middle, potential, blocks, block_count);
    fr_add_block(child, piece->boundary + middle, hi - middle,
                 piece->boundary + lo, middle - lo, potential, blocks, block_count);
    fr_build_blocks_rec(child, lo, middle, potential, blocks, block_count);
    fr_build_blocks_rec(child, middle, hi, potential, blocks, block_count);
}

static void fr_activate(int vertex, int64_t value, FrBlock *blocks,
                        int block_count, const bool *settled) {
    for (int b = 0; b < block_count; ++b) {
        FrBlock *block = &blocks[b];
        for (int i = 0; i < block->row_count; ++i) {
            if (block->rows[i] != vertex) continue;
            for (int j = 0; j < block->column_count; ++j) {
                const int target = block->columns[j];
                const int64_t weight = block->weights[i][j];
                if (settled[target] || weight == FR_INF) continue;
                const int64_t candidate = value + weight;
                if (candidate < block->best_value[j] ||
                    (candidate == block->best_value[j] && vertex < block->best_row[j])) {
                    block->best_value[j] = candidate;
                    block->best_row[j] = vertex;
                }
            }
        }
    }
}

static void fr_settle(int vertex, bool *settled, FrBlock *blocks, int block_count) {
    settled[vertex] = true;
    for (int b = 0; b < block_count; ++b)
        for (int j = 0; j < blocks[b].column_count; ++j)
            if (blocks[b].columns[j] == vertex) {
                blocks[b].best_value[j] = FR_INF;
                blocks[b].best_row[j] = INT32_MAX;
            }
}

static void fr_run_dijkstra(const int *nodes, int node_count,
                            FrBlock *blocks, int block_count,
                            const int *seed_vertices, const int64_t *seed_values,
                            int seed_count, int64_t *labels) {
    bool settled[FR_MAX_N] = {false};
    for (int v = 0; v < fr_n; ++v) labels[v] = FR_INF;
    for (int b = 0; b < block_count; ++b)
        for (int j = 0; j < blocks[b].column_count; ++j) {
            blocks[b].best_value[j] = FR_INF;
            blocks[b].best_row[j] = INT32_MAX;
        }
    (void)nodes;
    (void)node_count;
    for (int i = 0; i < seed_count; ++i) {
        const int vertex = seed_vertices[i];
        if (seed_values[i] < labels[vertex]) labels[vertex] = seed_values[i];
    }
    /* Seed labels are tentative sources. Activate them, but let them compete
       in the same global minimum selection as the block candidates. */
    for (int i = 0; i < node_count; ++i) {
        const int vertex = nodes[i];
        if (labels[vertex] != FR_INF)
            fr_activate(vertex, labels[vertex], blocks, block_count, settled);
    }

    while (true) {
        int best_vertex = -1, best_row = INT32_MAX;
        int64_t best_value = FR_INF;
        for (int i = 0; i < node_count; ++i) {
            const int vertex = nodes[i];
            const int64_t value = labels[vertex];
            if (settled[vertex] || value == FR_INF) continue;
            if (value < best_value ||
                (value == best_value && (best_vertex < 0 || vertex < best_vertex)) ||
                (value == best_value && vertex == best_vertex && -1 < best_row)) {
                best_value = value;
                best_vertex = vertex;
                best_row = -1;
            }
        }
        for (int b = 0; b < block_count; ++b) {
            FrBlock *block = &blocks[b];
            for (int j = 0; j < block->column_count; ++j) {
                const int vertex = block->columns[j];
                const int64_t value = block->best_value[j];
                const int row = block->best_row[j];
                if (settled[vertex] || value == FR_INF) continue;
                if (value < best_value ||
                    (value == best_value && (best_vertex < 0 || vertex < best_vertex)) ||
                    (value == best_value && vertex == best_vertex && row < best_row)) {
                    best_value = value;
                    best_vertex = vertex;
                    best_row = row;
                }
            }
        }
        if (best_vertex < 0) break;
        if (best_value < labels[best_vertex]) labels[best_vertex] = best_value;
        fr_settle(best_vertex, settled, blocks, block_count);
        fr_activate(best_vertex, labels[best_vertex], blocks, block_count, settled);
    }
}

static int fr_unique_child_nodes(int left, int right, int *nodes) {
    bool present[FR_MAX_N] = {false};
    const FrPiece *a = &fr_pieces[left], *b = &fr_pieces[right];
    for (int i = 0; i < a->boundary_count; ++i) present[a->boundary[i]] = true;
    for (int i = 0; i < b->boundary_count; ++i) present[b->boundary[i]] = true;
    int count = 0;
    for (int v = 0; v < fr_n; ++v) if (present[v]) nodes[count++] = v;
    return count;
}

static int fr_build_piece(int index) {
    FrPiece *piece = &fr_pieces[index];
    for (int u = 0; u < fr_n; ++u) for (int v = 0; v < fr_n; ++v)
        fr_ddg[index][u][v] = FR_INF;
    if (piece->left == -1) {
        FrArc arcs[FR_MAX_BASE_ARCS];
        const int arc_count = fr_collect_arcs(piece->arc_mask, arcs);
        int nodes[FR_MAX_N], node_count = 0;
        for (int v = 0; v < fr_n; ++v)
            if (piece->vertex_mask & (uint16_t)(1u << v)) nodes[node_count++] = v;
        int64_t potential[FR_MAX_N] = {0};
        if (!fr_bellman_ford_all(nodes, node_count, arcs, arc_count, potential)) return -1;
        for (int i = 0; i < piece->boundary_count; ++i) {
            int64_t seeds[FR_MAX_N], labels[FR_MAX_N];
            for (int v = 0; v < fr_n; ++v) seeds[v] = FR_INF;
            seeds[piece->boundary[i]] = 0;
            if (!fr_bellman_ford_seeded(arcs, arc_count, seeds, labels)) return -1;
            for (int j = 0; j < piece->boundary_count; ++j)
                fr_ddg[index][piece->boundary[i]][piece->boundary[j]] = labels[piece->boundary[j]];
        }
        return 0;
    }

    const int children[2] = {piece->left, piece->right};
    int nodes[FR_MAX_UNION_NODES];
    const int node_count = fr_unique_child_nodes(children[0], children[1], nodes);
    bool in_union[FR_MAX_N] = {false};
    for (int i = 0; i < node_count; ++i) in_union[nodes[i]] = true;
    for (int i = 0; i < piece->boundary_count; ++i)
        if (!in_union[piece->boundary[i]]) return -1;

    FrArc union_arcs[2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY];
    int union_arc_count = 0;
    for (int ci = 0; ci < 2; ++ci) {
        const int child = children[ci];
        const FrPiece *child_piece = &fr_pieces[child];
        for (int i = 0; i < child_piece->boundary_count; ++i)
            for (int j = 0; j < child_piece->boundary_count; ++j) {
                const int u = child_piece->boundary[i], v = child_piece->boundary[j];
                if (u == v || fr_ddg[child][u][v] == FR_INF) continue;
                union_arcs[union_arc_count++] = (FrArc){u, v, fr_ddg[child][u][v]};
            }
    }
    int64_t *potential = fr_potential[index];
    for (int v = 0; v < fr_n; ++v) potential[v] = 0;
    if (!fr_bellman_ford_all(nodes, node_count, union_arcs, union_arc_count, potential)) return -1;
    for (int i = 0; i < union_arc_count; ++i) {
        const int u = union_arcs[i].tail, v = union_arcs[i].head;
        if (union_arcs[i].weight + potential[u] - potential[v] < 0) return -1;
    }

    FrBlock *blocks = fr_block_workspace;
    int block_count = 0;
    for (int ci = 0; ci < 2; ++ci) {
        const int child = children[ci];
        if (!fr_check_monge_rec(child, 0, fr_pieces[child].boundary_count)) return -1;
        fr_build_blocks_rec(child, 0, fr_pieces[child].boundary_count,
                            potential, blocks, &block_count);
    }
    if (block_count > FR_MAX_BLOCKS) return -1;
    for (int i = 0; i < piece->boundary_count; ++i) {
        const int source = piece->boundary[i];
        const int seed_vertices[1] = {source};
        const int64_t seed_values[1] = {0};
        int64_t labels[FR_MAX_N];
        fr_run_dijkstra(nodes, node_count, blocks, block_count,
                        seed_vertices, seed_values, 1, labels);
        for (int j = 0; j < piece->boundary_count; ++j) {
            const int target = piece->boundary[j];
            fr_ddg[index][source][target] = labels[target] == FR_INF ? FR_INF :
                labels[target] - potential[source] + potential[target];
        }
    }
    return 0;
}

static void fr_expand(int index, const int64_t *known, int64_t *result) {
    const FrPiece *piece = &fr_pieces[index];
    if (piece->left == -1) {
        FrArc arcs[FR_MAX_BASE_ARCS];
        const int arc_count = fr_collect_arcs(piece->arc_mask, arcs);
        int64_t labels[FR_MAX_N];
        if (!fr_bellman_ford_seeded(arcs, arc_count, known, labels)) return;
        for (int vertex = 0; vertex < fr_n; ++vertex)
            if ((piece->vertex_mask & (uint16_t)(1u << vertex)) && labels[vertex] < result[vertex])
                result[vertex] = labels[vertex];
        return;
    }

    int nodes[FR_MAX_UNION_NODES];
    const int node_count = fr_unique_child_nodes(piece->left, piece->right, nodes);
    FrBlock *blocks = fr_block_workspace;
    int block_count = 0;
    const int children[2] = {piece->left, piece->right};
    for (int ci = 0; ci < 2; ++ci)
        fr_build_blocks_rec(children[ci], 0, fr_pieces[children[ci]].boundary_count,
                            fr_potential[index], blocks, &block_count);

    int seed_vertices[FR_MAX_BOUNDARY];
    int64_t seed_values[FR_MAX_BOUNDARY];
    int seed_count = 0;
    for (int i = 0; i < piece->boundary_count; ++i) {
        const int vertex = piece->boundary[i];
        if (known[vertex] == FR_INF) continue;
        seed_vertices[seed_count] = vertex;
        seed_values[seed_count] = known[vertex] - fr_potential[index][vertex];
        ++seed_count;
    }
    int64_t reduced[FR_MAX_N], raw[FR_MAX_N];
    fr_run_dijkstra(nodes, node_count, blocks, block_count,
                    seed_vertices, seed_values, seed_count, reduced);
    for (int vertex = 0; vertex < fr_n; ++vertex)
        raw[vertex] = reduced[vertex] == FR_INF ? FR_INF : reduced[vertex] + fr_potential[index][vertex];

    for (int ci = 0; ci < 2; ++ci) {
        const int child = children[ci];
        int64_t child_known[FR_MAX_N];
        for (int vertex = 0; vertex < fr_n; ++vertex) child_known[vertex] = FR_INF;
        for (int j = 0; j < fr_pieces[child].boundary_count; ++j) {
            const int vertex = fr_pieces[child].boundary[j];
            child_known[vertex] = raw[vertex];
        }
        fr_expand(child, child_known, result);
    }
}

static void fr_write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t fakcharoenphol_rao_planar_sssp(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (!fr_parse(input, length)) return -1;
    int all_nodes[FR_MAX_N];
    int64_t global_potential[FR_MAX_N] = {0};
    for (int vertex = 0; vertex < fr_n; ++vertex) all_nodes[vertex] = vertex;
    if (!fr_bellman_ford_all(all_nodes, fr_n, fr_arcs, fr_m, global_potential)) return -1;
    for (int p = 0; p < fr_piece_count; ++p)
        for (int u = 0; u < fr_n; ++u)
            for (int v = 0; v < fr_n; ++v)
                fr_ddg[p][u][v] = FR_INF;
    for (int p = 0; p < fr_piece_count; ++p)
        if (fr_build_piece(p) != 0) return -1;

    int64_t result[FR_MAX_N], known[FR_MAX_N];
    for (int v = 0; v < fr_n; ++v) {
        result[v] = FR_INF;
        known[v] = FR_INF;
    }
    known[fr_source] = 0;
    fr_expand(fr_piece_count - 1, known, result);
    const size_t output_bytes = (size_t)fr_n * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (int v = 0; v < fr_n; ++v)
        fr_write_i64_le(output, (size_t)v * 8,
                        result[v] == FR_INF ? INT64_MAX : result[v]);
    return (int64_t)output_bytes;
}
