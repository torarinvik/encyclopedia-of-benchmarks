#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 32, max_m = 128, max_input = 259, max_arcs = 2 * max_m;
}

extern "C" std::int64_t cactus_graph_recognition(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > max_n || m_value < 0 || m_value > max_m) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    if (length != 2 + 2 * m) return -1;

    std::array<std::array<bool, max_n>, max_n> edge_seen{};
    std::array<int, max_n> head{};
    std::array<int, max_arcs> arc_to{}, arc_edge{}, next_arc{};
    head.fill(-1);
    int arc_count = 0;
    for (std::size_t e = 0; e < m; ++e) {
        const auto u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        const auto u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        if (edge_seen[u][v]) return -1;
        edge_seen[u][v] = edge_seen[v][u] = true;
        arc_to[arc_count] = v; arc_edge[arc_count] = static_cast<int>(e);
        next_arc[arc_count] = head[u]; head[u] = arc_count++;
        arc_to[arc_count] = u; arc_edge[arc_count] = static_cast<int>(e);
        next_arc[arc_count] = head[v]; head[v] = arc_count++;
    }

    std::array<int, max_n> state{}, parent{}, parent_edge{}, depth{}, cursor{}, stack{}, cycle_vertices{};
    std::array<int, max_m> cycle_of{};
    std::array<bool, max_m> used{};
    parent.fill(-1); parent_edge.fill(-1); cursor.fill(-1); cycle_of.fill(-1);
    int cycles = 0;
    bool edge_cactus = true, vertex_cactus = true;
    for (std::size_t root = 0; root < n && edge_cactus; ++root) {
        if (state[root] != 0) continue;
        std::size_t top = 0;
        state[root] = 1; cursor[root] = head[root]; stack[top++] = static_cast<int>(root);
        while (top != 0 && edge_cactus) {
            const int u = stack[top - 1], arc = cursor[u];
            if (arc < 0) { state[u] = 2; --top; continue; }
            cursor[u] = next_arc[arc];
            const int e = arc_edge[arc];
            if (used[e]) continue;
            used[e] = true;
            const int v = arc_to[arc];
            if (state[v] == 0) {
                parent[v] = u; parent_edge[v] = e; depth[v] = depth[u] + 1;
                state[v] = 1; cursor[v] = head[v]; stack[top++] = v;
            } else if (state[v] == 1 && depth[v] < depth[u]) {
                int x = u;
                while (x != v) {
                    const int tree_edge = parent_edge[x];
                    if (tree_edge < 0 || cycle_of[tree_edge] != -1) { edge_cactus = false; break; }
                    x = parent[x];
                }
                if (!edge_cactus) break;
                x = u;
                if (++cycle_vertices[x] > 1) vertex_cactus = false;
                while (x != v) {
                    const int tree_edge = parent_edge[x];
                    cycle_of[tree_edge] = cycles;
                    x = parent[x];
                    if (++cycle_vertices[x] > 1) vertex_cactus = false;
                }
                cycle_of[e] = cycles;
                ++cycles;
            }
        }
    }
    if (!edge_cactus) return 0;
    return static_cast<std::int64_t>(4 * cycles + (vertex_cactus ? 2 : 0) + 1);
}
