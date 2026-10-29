#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define ST_NUMBERING_MAX_VERTICES 8
#define ST_NUMBERING_MAX_EDGES 28
#define ST_NUMBERING_MAX_ARCS (2 * ST_NUMBERING_MAX_EDGES)
#define ST_NUMBERING_MAX_INPUT (4 + 2 * ST_NUMBERING_MAX_EDGES)

int64_t st_numbering(const int64_t *input, size_t input_length,
                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 4 || input_length > ST_NUMBERING_MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    const int64_t s_value = input[2], t_value = input[3];
    if (n_value < 2 || n_value > ST_NUMBERING_MAX_VERTICES ||
        m_value < 0 || m_value > ST_NUMBERING_MAX_EDGES ||
        s_value < 0 || s_value >= n_value || t_value < 0 || t_value >= n_value ||
        s_value == t_value || input_length != 4 + 2 * (size_t)m_value) return -1;
    const int n = (int)n_value, m = (int)m_value;
    const int s = (int)s_value, t = (int)t_value;

    int edge_u[ST_NUMBERING_MAX_EDGES], edge_v[ST_NUMBERING_MAX_EDGES];
    uint16_t adjacent[ST_NUMBERING_MAX_VERTICES] = {0};
    int st_edge = -1;
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u_value = input[4 + 2 * (size_t)edge];
        const int64_t v_value = input[5 + 2 * (size_t)edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value) return -1;
        const int u = (int)u_value, v = (int)v_value;
        if ((adjacent[u] & (uint16_t)(1u << v)) != 0) return -1;
        adjacent[u] |= (uint16_t)(1u << v);
        adjacent[v] |= (uint16_t)(1u << u);
        edge_u[edge] = u;
        edge_v[edge] = v;
        if ((u == s && v == t) || (u == t && v == s)) st_edge = edge;
    }
    if (st_edge < 0) return -1;

    int head[ST_NUMBERING_MAX_VERTICES];
    for (int vertex = 0; vertex < n; ++vertex) head[vertex] = -1;
    int arc_to[ST_NUMBERING_MAX_ARCS], arc_next[ST_NUMBERING_MAX_ARCS];
    int arc_count = 0;
    for (int edge = 0; edge < m; ++edge) {
        if (edge == st_edge) continue;
        const int u = edge_u[edge], v = edge_v[edge];
        arc_to[arc_count] = v; arc_next[arc_count] = head[u]; head[u] = arc_count++;
        arc_to[arc_count] = u; arc_next[arc_count] = head[v]; head[v] = arc_count++;
    }
    arc_to[arc_count] = t; arc_next[arc_count] = head[s]; head[s] = arc_count++;
    arc_to[arc_count] = s; arc_next[arc_count] = head[t]; head[t] = arc_count++;

    int parent[ST_NUMBERING_MAX_VERTICES], discovery[ST_NUMBERING_MAX_VERTICES];
    int low_vertex[ST_NUMBERING_MAX_VERTICES], children[ST_NUMBERING_MAX_VERTICES];
    int next_arc[ST_NUMBERING_MAX_VERTICES], preorder[ST_NUMBERING_MAX_VERTICES];
    for (int vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = -1; discovery[vertex] = 0; low_vertex[vertex] = vertex;
        children[vertex] = 0; next_arc[vertex] = -1;
    }
    int stack[ST_NUMBERING_MAX_VERTICES], top = 0, clock = 1, preorder_count = 1;
    discovery[s] = clock; preorder[0] = s; next_arc[s] = head[s]; stack[top++] = s;
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

    int previous[ST_NUMBERING_MAX_VERTICES], following[ST_NUMBERING_MAX_VERTICES];
    int sign[ST_NUMBERING_MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < n; ++vertex) previous[vertex] = following[vertex] = -1;
    sign[s] = -1; following[s] = t; previous[t] = s;
    int list_head = s;
    for (int order = 2; order < n; ++order) {
        const int vertex = preorder[order];
        const int ancestor = parent[vertex];
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

    int rank[ST_NUMBERING_MAX_VERTICES] = {0};
    uint8_t staged[ST_NUMBERING_MAX_VERTICES] = {0};
    int rank_value = 1, vertex = list_head;
    while (vertex >= 0 && rank_value <= n) {
        rank[vertex] = rank_value;
        staged[vertex] = (uint8_t)rank_value++;
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
    if (output == NULL || output_capacity < (size_t)n) return -2;
    for (int v = 0; v < n; ++v) output[v] = staged[v];
    return n;
}
