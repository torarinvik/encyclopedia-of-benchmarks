#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int max_n = 12;
constexpr int max_arcs = 60;
constexpr int max_pieces = 119;
constexpr int max_boundary = 12;
constexpr int max_blocks = 44;
constexpr int max_union_nodes = 24;
constexpr int max_base_arcs = 3;
constexpr std::size_t max_input = 2088;
constexpr int max_weight = 100;
constexpr std::int64_t inf = INT64_C(1) << 60;

struct Arc {
    int tail = 0;
    int head = 0;
    std::int64_t weight = 0;
};

struct Piece {
    int left = -1;
    int right = -1;
    int boundary_count = 0;
    std::uint64_t arc_mask = 0;
    std::uint16_t vertex_mask = 0;
    std::array<int, max_boundary> boundary{};
};

struct Block {
    int child = 0;
    int row_count = 0;
    int column_count = 0;
    std::array<int, max_boundary> rows{};
    std::array<int, max_boundary> columns{};
    std::array<std::array<std::int64_t, max_boundary>, max_boundary> weights{};
    std::array<std::int64_t, max_boundary> best_value{};
    std::array<int, max_boundary> best_row{};
};

class Context {
public:
    int n = 0;
    int m = 0;
    int source = 0;
    int piece_count = 0;
    std::array<Piece, max_pieces> pieces{};
    std::array<Arc, max_arcs> arcs{};
    std::array<std::array<std::array<std::int64_t, max_n>, max_n>, max_pieces> ddg{};
    std::array<std::array<std::int64_t, max_n>, max_pieces> potential{};
    std::array<Block, max_blocks> block_workspace{};

    bool parse(const std::int64_t* input, std::size_t length) {
        if (input == nullptr || length < 4 || length > max_input) return false;
        const auto n_value = input[0];
        const auto m_value = input[1];
        const auto source_value = input[2];
        const auto pieces_value = input[3];
        if (n_value < 2 || n_value > max_n || m_value < 1 || m_value > max_arcs ||
            source_value < 0 || source_value >= n_value || pieces_value < 1 ||
            pieces_value > max_pieces || pieces_value % 2 == 0) return false;
        n = static_cast<int>(n_value);
        m = static_cast<int>(m_value);
        source = static_cast<int>(source_value);
        piece_count = static_cast<int>(pieces_value);

        std::array<std::array<bool, max_n>, max_n> seen_arc{};
        std::array<std::array<bool, max_n>, max_n> seen_pair{};
        int undirected_edges = 0;
        std::size_t offset = 4;
        for (int edge = 0; edge < m; ++edge) {
            if (offset + 3 > length) return false;
            const auto u_value = input[offset++];
            const auto v_value = input[offset++];
            const auto weight = input[offset++];
            if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n ||
                u_value == v_value || weight < -max_weight || weight > max_weight) return false;
            const int u = static_cast<int>(u_value);
            const int v = static_cast<int>(v_value);
            if (seen_arc[u][v]) return false;
            seen_arc[u][v] = true;
            if (!seen_pair[u][v]) {
                seen_pair[u][v] = seen_pair[v][u] = true;
                ++undirected_edges;
            }
            arcs[edge] = {u, v, weight};
        }
        const int simple_edge_limit = n == 2 ? 1 : 3 * n - 6;
        if (undirected_edges > simple_edge_limit || m > 2 * simple_edge_limit) return false;

        std::array<bool, max_n> visited{};
        std::array<int, max_n> queue{};
        int head = 0, tail = 0;
        visited[0] = true;
        queue[tail++] = 0;
        while (head < tail) {
            const int u = queue[head++];
            for (int edge = 0; edge < m; ++edge) {
                const int a = arcs[edge].tail, b = arcs[edge].head;
                int v = -1;
                if (a == u) v = b;
                else if (b == u) v = a;
                if (v >= 0 && !visited[v]) {
                    visited[v] = true;
                    queue[tail++] = v;
                }
            }
        }
        for (int v = 0; v < n; ++v) if (!visited[v]) return false;

        std::array<int, max_pieces> parent_count{};
        std::uint64_t leaf_union = 0;
        int leaf_count = 0;
        const std::uint64_t full_arc_mask = (UINT64_C(1) << m) - 1;
        for (int index = 0; index < piece_count; ++index) {
            if (offset + 4 > length) return false;
            const auto left_value = input[offset++];
            const auto right_value = input[offset++];
            const auto mask_value = input[offset++];
            const auto boundary_count_value = input[offset++];
            if (boundary_count_value < 1 || boundary_count_value > max_boundary ||
                boundary_count_value > n || offset + static_cast<std::size_t>(boundary_count_value) > length)
                return false;
            Piece& piece = pieces[index];
            piece.boundary_count = static_cast<int>(boundary_count_value);
            std::uint16_t listed_boundary = 0;
            for (int i = 0; i < piece.boundary_count; ++i) {
                const auto vertex_value = input[offset++];
                if (vertex_value < 0 || vertex_value >= n) return false;
                const int vertex = static_cast<int>(vertex_value);
                const auto bit = static_cast<std::uint16_t>(1u << vertex);
                if ((listed_boundary & bit) != 0) return false;
                listed_boundary |= bit;
                piece.boundary[i] = vertex;
            }

            if (left_value == -1 && right_value == -1) {
                if (mask_value <= 0) return false;
                piece.left = piece.right = -1;
                const auto mask = static_cast<std::uint64_t>(mask_value);
                if ((mask & ~full_arc_mask) != 0 || popcount64(mask) > max_base_arcs ||
                    (leaf_union & mask) != 0) return false;
                piece.arc_mask = mask;
                leaf_union |= mask;
                ++leaf_count;
                piece.vertex_mask = vertex_mask_for_arcs(mask);
                if (!piece_connected(mask, piece.vertex_mask)) return false;
            } else {
                if (left_value < 0 || right_value < 0 || left_value >= index ||
                    right_value >= index || left_value == right_value || mask_value != -1) return false;
                const int left = static_cast<int>(left_value);
                const int right = static_cast<int>(right_value);
                piece.left = left;
                piece.right = right;
                if (parent_count[left] != 0 || parent_count[right] != 0) return false;
                parent_count[left] = parent_count[right] = 1;
                const Piece& left_piece = pieces[left];
                const Piece& right_piece = pieces[right];
                if ((left_piece.arc_mask & right_piece.arc_mask) != 0) return false;
                piece.arc_mask = left_piece.arc_mask | right_piece.arc_mask;
                piece.vertex_mask = left_piece.vertex_mask | right_piece.vertex_mask;
                const int parent_vertices = popcount16(piece.vertex_mask);
                const int max_child_vertices = (2 * parent_vertices + 2) / 3;
                if (popcount16(left_piece.vertex_mask) > max_child_vertices ||
                    popcount16(right_piece.vertex_mask) > max_child_vertices ||
                    (left_piece.vertex_mask & right_piece.vertex_mask) == 0) return false;
            }

            std::uint16_t expected_boundary = 0;
            for (int vertex = 0; vertex < n; ++vertex) {
                const auto bit = static_cast<std::uint16_t>(1u << vertex);
                if ((piece.vertex_mask & bit) == 0) continue;
                if (vertex == source) {
                    expected_boundary |= bit;
                    continue;
                }
                for (int edge = 0; edge < m; ++edge) {
                    if ((piece.arc_mask & (UINT64_C(1) << edge)) == 0 &&
                        (arcs[edge].tail == vertex || arcs[edge].head == vertex)) {
                        expected_boundary |= bit;
                        break;
                    }
                }
            }
            if (listed_boundary != expected_boundary ||
                !piece_connected(piece.arc_mask, piece.vertex_mask)) return false;
            if (index == piece_count - 1 &&
                (piece.arc_mask != full_arc_mask || piece.vertex_mask != static_cast<std::uint16_t>((1u << n) - 1u)))
                return false;
        }
        if (offset != length || piece_count != 2 * leaf_count - 1 ||
            leaf_union != full_arc_mask || parent_count[piece_count - 1] != 0) return false;
        for (int i = 0; i < piece_count - 1; ++i) if (parent_count[i] != 1) return false;
        const Piece& root = pieces[piece_count - 1];
        return root.boundary_count == 1 && root.boundary[0] == source;
    }

    std::int64_t run(std::uint8_t* output, std::size_t capacity) {
        std::array<int, max_n> all_nodes{};
        std::array<std::int64_t, max_n> global_potential{};
        for (int vertex = 0; vertex < n; ++vertex) all_nodes[vertex] = vertex;
        if (!bellman_ford_all(all_nodes.data(), n, arcs.data(), m, global_potential)) return -1;
        for (int p = 0; p < piece_count; ++p)
            for (int u = 0; u < n; ++u)
                for (int v = 0; v < n; ++v) ddg[p][u][v] = inf;
        for (int p = 0; p < piece_count; ++p) if (build_piece(p) != 0) return -1;

        std::array<std::int64_t, max_n> result{};
        std::array<std::int64_t, max_n> known{};
        result.fill(inf);
        known.fill(inf);
        known[source] = 0;
        expand(piece_count - 1, known.data(), result.data());
        const std::size_t output_bytes = static_cast<std::size_t>(n) * 8;
        if (output == nullptr || capacity < output_bytes) return -2;
        for (int v = 0; v < n; ++v)
            write_i64_le(output, static_cast<std::size_t>(v) * 8,
                         result[v] == inf ? std::numeric_limits<std::int64_t>::max() : result[v]);
        return static_cast<std::int64_t>(output_bytes);
    }

private:
    static int popcount16(std::uint16_t value) {
        int count = 0;
        while (value != 0) { count += value & 1u; value = static_cast<std::uint16_t>(value >> 1); }
        return count;
    }
    static int popcount64(std::uint64_t value) {
        int count = 0;
        while (value != 0) { count += static_cast<int>(value & 1u); value >>= 1; }
        return count;
    }
    std::uint16_t vertex_mask_for_arcs(std::uint64_t mask) const {
        std::uint16_t result = 0;
        for (int edge = 0; edge < m; ++edge) if (mask & (UINT64_C(1) << edge))
            result |= static_cast<std::uint16_t>((1u << arcs[edge].tail) | (1u << arcs[edge].head));
        return result;
    }
    bool piece_connected(std::uint64_t mask, std::uint16_t vertex_mask) const {
        if (vertex_mask == 0) return false;
        int start = 0;
        while ((vertex_mask & static_cast<std::uint16_t>(1u << start)) == 0) ++start;
        std::uint16_t reached = static_cast<std::uint16_t>(1u << start);
        bool changed = true;
        while (changed) {
            changed = false;
            for (int edge = 0; edge < m; ++edge) {
                if ((mask & (UINT64_C(1) << edge)) == 0) continue;
                const int u = arcs[edge].tail, v = arcs[edge].head;
                const auto ubit = static_cast<std::uint16_t>(1u << u);
                const auto vbit = static_cast<std::uint16_t>(1u << v);
                if ((reached & ubit) != 0 && (reached & vbit) == 0) { reached |= vbit; changed = true; }
                if ((reached & vbit) != 0 && (reached & ubit) == 0) { reached |= ubit; changed = true; }
            }
        }
        return reached == vertex_mask;
    }
    bool bellman_ford_all(const int* nodes, int node_count, const Arc* input_arcs,
                          int arc_count, std::array<std::int64_t, max_n>& labels) const {
        for (int i = 0; i < node_count; ++i) labels[nodes[i]] = 0;
        for (int pass = 0; pass + 1 < node_count; ++pass) {
            bool changed = false;
            for (int edge = 0; edge < arc_count; ++edge) {
                const Arc& arc = input_arcs[edge];
                const auto candidate = labels[arc.tail] + arc.weight;
                if (candidate < labels[arc.head]) { labels[arc.head] = candidate; changed = true; }
            }
            if (!changed) break;
        }
        for (int edge = 0; edge < arc_count; ++edge) {
            const Arc& arc = input_arcs[edge];
            if (labels[arc.tail] + arc.weight < labels[arc.head]) return false;
        }
        return true;
    }
    bool bellman_ford_seeded(const Arc* input_arcs, int arc_count,
                             const std::array<std::int64_t, max_n>& seed_labels,
                             std::array<std::int64_t, max_n>& labels) const {
        labels = seed_labels;
        for (int pass = 0; pass + 1 < n; ++pass) {
            bool changed = false;
            for (int edge = 0; edge < arc_count; ++edge) {
                const Arc& arc = input_arcs[edge];
                if (labels[arc.tail] == inf) continue;
                const auto candidate = labels[arc.tail] + arc.weight;
                if (candidate < labels[arc.head]) { labels[arc.head] = candidate; changed = true; }
            }
            if (!changed) break;
        }
        for (int edge = 0; edge < arc_count; ++edge) {
            const Arc& arc = input_arcs[edge];
            if (labels[arc.tail] != inf && labels[arc.tail] + arc.weight < labels[arc.head]) return false;
        }
        return true;
    }
    static std::int64_t monge_sum(std::int64_t a, std::int64_t b) {
        return a == inf || b == inf ? inf : a + b;
    }
    bool check_monge_rec(int piece_index, int lo, int hi) const {
        if (hi - lo <= 1) return true;
        const Piece& piece = pieces[piece_index];
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
                            const int u = piece.boundary[i], u2 = piece.boundary[i2];
                            const int v = piece.boundary[j], v2 = piece.boundary[j2];
                            const auto lhs = monge_sum(ddg[piece_index][u][v], ddg[piece_index][u2][v2]);
                            const auto rhs = monge_sum(ddg[piece_index][u][v2], ddg[piece_index][u2][v]);
                            if (lhs > rhs) return false;
                        }
        }
        return check_monge_rec(piece_index, lo, middle) && check_monge_rec(piece_index, middle, hi);
    }
    void add_block(int child, const int* rows, int row_count, const int* columns,
                   int column_count, const std::int64_t* reduced_potential, int& block_count) {
        if (row_count == 0 || column_count == 0 || block_count >= max_blocks) return;
        Block& block = block_workspace[block_count++];
        block.child = child;
        block.row_count = row_count;
        block.column_count = column_count;
        for (int i = 0; i < row_count; ++i) block.rows[i] = rows[i];
        for (int j = 0; j < column_count; ++j) block.columns[j] = columns[j];
        for (int i = 0; i < row_count; ++i) for (int j = 0; j < column_count; ++j) {
            const int u = rows[i], v = columns[j];
            const auto distance = ddg[child][u][v];
            block.weights[i][j] = distance == inf ? inf : distance + reduced_potential[u] - reduced_potential[v];
        }
    }
    void build_blocks_rec(int child, int lo, int hi, const std::int64_t* reduced_potential,
                          int& block_count) {
        if (hi - lo <= 1) return;
        const Piece& piece = pieces[child];
        const int middle = (lo + hi) / 2;
        add_block(child, piece.boundary.data() + lo, middle - lo,
                  piece.boundary.data() + middle, hi - middle, reduced_potential, block_count);
        add_block(child, piece.boundary.data() + middle, hi - middle,
                  piece.boundary.data() + lo, middle - lo, reduced_potential, block_count);
        build_blocks_rec(child, lo, middle, reduced_potential, block_count);
        build_blocks_rec(child, middle, hi, reduced_potential, block_count);
    }
    void activate(int vertex, std::int64_t value, int block_count, const bool* settled) {
        for (int b = 0; b < block_count; ++b) {
            Block& block = block_workspace[b];
            for (int i = 0; i < block.row_count; ++i) {
                if (block.rows[i] != vertex) continue;
                for (int j = 0; j < block.column_count; ++j) {
                    const int target = block.columns[j];
                    const auto weight = block.weights[i][j];
                    if (settled[target] || weight == inf) continue;
                    const auto candidate = value + weight;
                    if (candidate < block.best_value[j] ||
                        (candidate == block.best_value[j] && vertex < block.best_row[j])) {
                        block.best_value[j] = candidate;
                        block.best_row[j] = vertex;
                    }
                }
            }
        }
    }
    void settle(int vertex, bool* settled, int block_count) {
        settled[vertex] = true;
        for (int b = 0; b < block_count; ++b)
            for (int j = 0; j < block_workspace[b].column_count; ++j)
                if (block_workspace[b].columns[j] == vertex) {
                    block_workspace[b].best_value[j] = inf;
                    block_workspace[b].best_row[j] = std::numeric_limits<int>::max();
                }
    }
    void run_dijkstra(const int* nodes, int node_count, int block_count,
                      const int* seed_vertices, const std::int64_t* seed_values,
                      int seed_count, std::array<std::int64_t, max_n>& labels) {
        std::array<bool, max_n> settled{};
        labels.fill(inf);
        for (int b = 0; b < block_count; ++b)
            for (int j = 0; j < block_workspace[b].column_count; ++j) {
                block_workspace[b].best_value[j] = inf;
                block_workspace[b].best_row[j] = std::numeric_limits<int>::max();
            }
        for (int i = 0; i < seed_count; ++i) {
            const int vertex = seed_vertices[i];
            if (seed_values[i] < labels[vertex]) labels[vertex] = seed_values[i];
        }
        for (int i = 0; i < node_count; ++i) {
            const int vertex = nodes[i];
            if (labels[vertex] != inf) activate(vertex, labels[vertex], block_count, settled.data());
        }
        while (true) {
            int best_vertex = -1, best_row = std::numeric_limits<int>::max();
            std::int64_t best_value = inf;
            for (int i = 0; i < node_count; ++i) {
                const int vertex = nodes[i];
                const auto value = labels[vertex];
                if (settled[vertex] || value == inf) continue;
                if (value < best_value || (value == best_value && (best_vertex < 0 || vertex < best_vertex)) ||
                    (value == best_value && vertex == best_vertex && -1 < best_row)) {
                    best_value = value;
                    best_vertex = vertex;
                    best_row = -1;
                }
            }
            for (int b = 0; b < block_count; ++b) {
                Block& block = block_workspace[b];
                for (int j = 0; j < block.column_count; ++j) {
                    const int vertex = block.columns[j];
                    const auto value = block.best_value[j];
                    const int row = block.best_row[j];
                    if (settled[vertex] || value == inf) continue;
                    if (value < best_value || (value == best_value && (best_vertex < 0 || vertex < best_vertex)) ||
                        (value == best_value && vertex == best_vertex && row < best_row)) {
                        best_value = value;
                        best_vertex = vertex;
                        best_row = row;
                    }
                }
            }
            if (best_vertex < 0) break;
            if (best_value < labels[best_vertex]) labels[best_vertex] = best_value;
            settle(best_vertex, settled.data(), block_count);
            activate(best_vertex, labels[best_vertex], block_count, settled.data());
        }
    }
    int unique_child_nodes(int left, int right, int* nodes) const {
        std::array<bool, max_n> present{};
        const Piece& a = pieces[left];
        const Piece& b = pieces[right];
        for (int i = 0; i < a.boundary_count; ++i) present[a.boundary[i]] = true;
        for (int i = 0; i < b.boundary_count; ++i) present[b.boundary[i]] = true;
        int count = 0;
        for (int v = 0; v < n; ++v) if (present[v]) nodes[count++] = v;
        return count;
    }
    int collect_arcs(std::uint64_t mask, std::array<Arc, max_base_arcs>& out) const {
        int count = 0;
        for (int edge = 0; edge < m; ++edge) if (mask & (UINT64_C(1) << edge)) out[count++] = arcs[edge];
        return count;
    }
    int build_piece(int index) {
        Piece& piece = pieces[index];
        for (int u = 0; u < n; ++u) for (int v = 0; v < n; ++v) ddg[index][u][v] = inf;
        if (piece.left == -1) {
            std::array<Arc, max_base_arcs> local_arcs{};
            const int arc_count = collect_arcs(piece.arc_mask, local_arcs);
            std::array<int, max_n> nodes{};
            int node_count = 0;
            for (int v = 0; v < n; ++v) if (piece.vertex_mask & (1u << v)) nodes[node_count++] = v;
            std::array<std::int64_t, max_n> local_potential{};
            if (!bellman_ford_all(nodes.data(), node_count, local_arcs.data(), arc_count, local_potential)) return -1;
            for (int i = 0; i < piece.boundary_count; ++i) {
                std::array<std::int64_t, max_n> seeds{}, labels{};
                seeds.fill(inf);
                seeds[piece.boundary[i]] = 0;
                if (!bellman_ford_seeded(local_arcs.data(), arc_count, seeds, labels)) return -1;
                for (int j = 0; j < piece.boundary_count; ++j)
                    ddg[index][piece.boundary[i]][piece.boundary[j]] = labels[piece.boundary[j]];
            }
            return 0;
        }

        const int children[2] = {piece.left, piece.right};
        std::array<int, max_union_nodes> nodes{};
        const int node_count = unique_child_nodes(children[0], children[1], nodes.data());
        std::array<bool, max_n> in_union{};
        for (int i = 0; i < node_count; ++i) in_union[nodes[i]] = true;
        for (int i = 0; i < piece.boundary_count; ++i) if (!in_union[piece.boundary[i]]) return -1;

        std::array<Arc, 2 * max_boundary * max_boundary> union_arcs{};
        int union_arc_count = 0;
        for (int ci = 0; ci < 2; ++ci) {
            const int child = children[ci];
            const Piece& child_piece = pieces[child];
            for (int i = 0; i < child_piece.boundary_count; ++i)
                for (int j = 0; j < child_piece.boundary_count; ++j) {
                    const int u = child_piece.boundary[i], v = child_piece.boundary[j];
                    if (u == v || ddg[child][u][v] == inf) continue;
                    union_arcs[union_arc_count++] = {u, v, ddg[child][u][v]};
                }
        }
        auto& reduced_potential = potential[index];
        reduced_potential.fill(0);
        if (!bellman_ford_all(nodes.data(), node_count, union_arcs.data(), union_arc_count, reduced_potential)) return -1;
        for (int i = 0; i < union_arc_count; ++i) {
            const Arc& arc = union_arcs[i];
            if (arc.weight + reduced_potential[arc.tail] - reduced_potential[arc.head] < 0) return -1;
        }
        int block_count = 0;
        for (int ci = 0; ci < 2; ++ci) {
            const int child = children[ci];
            if (!check_monge_rec(child, 0, pieces[child].boundary_count)) return -1;
            build_blocks_rec(child, 0, pieces[child].boundary_count, reduced_potential.data(), block_count);
        }
        if (block_count > max_blocks) return -1;
        for (int i = 0; i < piece.boundary_count; ++i) {
            const int start = piece.boundary[i];
            const int seed_vertices[1] = {start};
            const std::int64_t seed_values[1] = {0};
            std::array<std::int64_t, max_n> labels{};
            run_dijkstra(nodes.data(), node_count, block_count, seed_vertices, seed_values, 1, labels);
            for (int j = 0; j < piece.boundary_count; ++j) {
                const int target = piece.boundary[j];
                ddg[index][start][target] = labels[target] == inf ? inf :
                    labels[target] - reduced_potential[start] + reduced_potential[target];
            }
        }
        return 0;
    }
    void expand(int index, const std::int64_t* known, std::int64_t* result) {
        const Piece& piece = pieces[index];
        if (piece.left == -1) {
            std::array<Arc, max_base_arcs> local_arcs{};
            const int arc_count = collect_arcs(piece.arc_mask, local_arcs);
            std::array<std::int64_t, max_n> labels{};
            std::array<std::int64_t, max_n> seeds{};
            for (int v = 0; v < n; ++v) seeds[v] = known[v];
            if (!bellman_ford_seeded(local_arcs.data(), arc_count, seeds, labels)) return;
            for (int vertex = 0; vertex < n; ++vertex)
                if ((piece.vertex_mask & (1u << vertex)) && labels[vertex] < result[vertex]) result[vertex] = labels[vertex];
            return;
        }
        std::array<int, max_union_nodes> nodes{};
        const int node_count = unique_child_nodes(piece.left, piece.right, nodes.data());
        int block_count = 0;
        const int children[2] = {piece.left, piece.right};
        for (int ci = 0; ci < 2; ++ci)
            build_blocks_rec(children[ci], 0, pieces[children[ci]].boundary_count,
                             potential[index].data(), block_count);
        std::array<int, max_boundary> seed_vertices{};
        std::array<std::int64_t, max_boundary> seed_values{};
        int seed_count = 0;
        for (int i = 0; i < piece.boundary_count; ++i) {
            const int vertex = piece.boundary[i];
            if (known[vertex] == inf) continue;
            seed_vertices[seed_count] = vertex;
            seed_values[seed_count] = known[vertex] - potential[index][vertex];
            ++seed_count;
        }
        std::array<std::int64_t, max_n> reduced{}, raw{};
        run_dijkstra(nodes.data(), node_count, block_count, seed_vertices.data(), seed_values.data(), seed_count, reduced);
        for (int vertex = 0; vertex < n; ++vertex)
            raw[vertex] = reduced[vertex] == inf ? inf : reduced[vertex] + potential[index][vertex];
        for (int ci = 0; ci < 2; ++ci) {
            const int child = children[ci];
            std::array<std::int64_t, max_n> child_known{};
            child_known.fill(inf);
            for (int j = 0; j < pieces[child].boundary_count; ++j) {
                const int vertex = pieces[child].boundary[j];
                child_known[vertex] = raw[vertex];
            }
            expand(child, child_known.data(), result);
        }
    }
    static void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
        const auto bits = static_cast<std::uint64_t>(value);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
};
} // namespace

extern "C" std::int64_t fakcharoenphol_rao_planar_sssp(const std::int64_t* input,
                                                        std::size_t length,
                                                        std::uint8_t* output,
                                                        std::size_t capacity) {
    Context context{};
    if (!context.parse(input, length)) return -1;
    return context.run(output, capacity);
}
