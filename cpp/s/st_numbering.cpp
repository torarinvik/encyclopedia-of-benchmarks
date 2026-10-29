#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 8;
constexpr int max_edges = 28;
constexpr int max_arcs = 2 * max_edges;
constexpr std::size_t max_input = 4 + 2 * max_edges;
}

extern "C" std::int64_t st_numbering(const std::int64_t *input, std::size_t input_length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 4 || input_length > max_input) return -1;
    const auto n_value = input[0], m_value = input[1];
    const auto s_value = input[2], t_value = input[3];
    if (n_value < 2 || n_value > max_vertices || m_value < 0 || m_value > max_edges ||
        s_value < 0 || s_value >= n_value || t_value < 0 || t_value >= n_value ||
        s_value == t_value || input_length != 4 + 2 * static_cast<std::size_t>(m_value)) return -1;
    const int n = static_cast<int>(n_value), m = static_cast<int>(m_value);
    const int s = static_cast<int>(s_value), t = static_cast<int>(t_value);

    std::array<int, max_edges> edge_u{}, edge_v{};
    std::array<std::uint16_t, max_vertices> adjacent{};
    int st_edge = -1;
    for (int edge = 0; edge < m; ++edge) {
        const auto u_value = input[4 + 2 * static_cast<std::size_t>(edge)];
        const auto v_value = input[5 + 2 * static_cast<std::size_t>(edge)];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        const auto u_bit = static_cast<std::uint16_t>(1u << v);
        const auto v_bit = static_cast<std::uint16_t>(1u << u);
        if ((adjacent[u] & u_bit) != 0) return -1;
        adjacent[u] |= u_bit;
        adjacent[v] |= v_bit;
        edge_u[edge] = u; edge_v[edge] = v;
        if ((u == s && v == t) || (u == t && v == s)) st_edge = edge;
    }
    if (st_edge < 0) return -1;

    std::array<int, max_vertices> head{};
    head.fill(-1);
    std::array<int, max_arcs> arc_to{}, arc_next{};
    int arc_count = 0;
    for (int edge = 0; edge < m; ++edge) {
        if (edge == st_edge) continue;
        const int u = edge_u[edge], v = edge_v[edge];
        arc_to[arc_count] = v; arc_next[arc_count] = head[u]; head[u] = arc_count++;
        arc_to[arc_count] = u; arc_next[arc_count] = head[v]; head[v] = arc_count++;
    }
    arc_to[arc_count] = t; arc_next[arc_count] = head[s]; head[s] = arc_count++;
    arc_to[arc_count] = s; arc_next[arc_count] = head[t]; head[t] = arc_count++;

    std::array<int, max_vertices> parent{}, discovery{}, low_vertex{}, children{}, next_arc{}, preorder{};
    parent.fill(-1); next_arc.fill(-1);
    int top = 0, clock = 1, preorder_count = 1;
    std::array<int, max_vertices> stack{};
    discovery[s] = clock; preorder[0] = s; low_vertex[s] = s; next_arc[s] = head[s]; stack[top++] = s;
    while (top > 0) {
        const int vertex = stack[top - 1];
        const int arc = next_arc[vertex];
        if (arc < 0) {
            --top;
            const int ancestor = parent[vertex];
            if (ancestor >= 0 && discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]])
                low_vertex[ancestor] = low_vertex[vertex];
            continue;
        }
        next_arc[vertex] = arc_next[arc];
        const int neighbor = arc_to[arc];
        if (neighbor == parent[vertex]) continue;
        if (discovery[neighbor] == 0) {
            parent[neighbor] = vertex;
            ++children[vertex];
            discovery[neighbor] = ++clock;
            low_vertex[neighbor] = neighbor;
            preorder[preorder_count++] = neighbor;
            next_arc[neighbor] = head[neighbor];
            stack[top++] = neighbor;
        } else if (discovery[neighbor] < discovery[vertex] &&
                   discovery[neighbor] < discovery[low_vertex[vertex]]) {
            low_vertex[vertex] = neighbor;
        }
    }
    if (preorder_count != n || children[s] != 1) return -1;
    for (int vertex = 0; vertex < n; ++vertex) {
        if (vertex == s) continue;
        for (int child = 0; child < n; ++child) {
            if (parent[child] == vertex && discovery[low_vertex[child]] >= discovery[vertex]) return -1;
        }
    }

    std::array<int, max_vertices> previous{}, following{}, sign{};
    previous.fill(-1); following.fill(-1);
    sign[s] = -1; following[s] = t; previous[t] = s;
    int list_head = s;
    for (int order = 2; order < n; ++order) {
        const int vertex = preorder[order], ancestor = parent[vertex];
        if (sign[low_vertex[vertex]] == -1) {
            const int left = previous[ancestor];
            previous[vertex] = left; following[vertex] = ancestor; previous[ancestor] = vertex;
            if (left >= 0) following[left] = vertex;
            else list_head = vertex;
            sign[ancestor] = 1;
        } else {
            const int right = following[ancestor];
            previous[vertex] = ancestor; following[vertex] = right; following[ancestor] = vertex;
            if (right >= 0) previous[right] = vertex;
            sign[ancestor] = -1;
        }
    }

    std::array<int, max_vertices> rank{};
    std::array<std::uint8_t, max_vertices> staged{};
    int rank_value = 1, vertex = list_head;
    while (vertex >= 0 && rank_value <= n) {
        rank[vertex] = rank_value;
        staged[vertex] = static_cast<std::uint8_t>(rank_value++);
        vertex = following[vertex];
    }
    if (rank_value != n + 1 || rank[s] != 1 || rank[t] != n) return -1;
    for (int v = 0; v < n; ++v) {
        if (v == s || v == t) continue;
        bool lower = false, higher = false;
        for (int arc = head[v]; arc >= 0; arc = arc_next[arc]) {
            const int neighbor = arc_to[arc];
            lower = lower || rank[neighbor] < rank[v];
            higher = higher || rank[neighbor] > rank[v];
        }
        if (!lower || !higher) return -1;
    }
    if (output == nullptr || output_capacity < static_cast<std::size_t>(n)) return -2;
    for (int v = 0; v < n; ++v) output[v] = staged[v];
    return n;
}
