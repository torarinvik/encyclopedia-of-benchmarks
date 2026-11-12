#include <stddef.h>
#include <stdint.h>

#define MDST_MAX_N 8
#define MDST_MAX_M 20
#define MDST_MAX_INPUT_VALUES (2 + 3 * MDST_MAX_M + 1)
#define MDST_INF INT64_C(1000000000000)

typedef struct {
    size_t u;
    size_t v;
    int64_t weight;
} mdst_edge;

static void mdst_shortest_tree(size_t n, size_t m, const mdst_edge edges[MDST_MAX_M],
    int center_kind, size_t center_root, int64_t center_x2, size_t center_edge,
    int64_t distance[MDST_MAX_N], int64_t parent_edge[MDST_MAX_N]) {
    uint8_t settled[MDST_MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        distance[vertex] = MDST_INF;
        parent_edge[vertex] = -1;
    }
    if (center_kind == 0) {
        distance[center_root] = 0;
    } else {
        size_t u = edges[center_edge].u;
        size_t v = edges[center_edge].v;
        if (u > v) { size_t temporary = u; u = v; v = temporary; }
        distance[u] = center_x2;
        distance[v] = 2 * edges[center_edge].weight - center_x2;
    }

    for (size_t step = 0; step < n; ++step) {
        size_t current = n;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (!settled[vertex] &&
                (current == n || distance[vertex] < distance[current])) current = vertex;
        }
        if (current == n || distance[current] == MDST_INF) return;
        settled[current] = 1;
        for (size_t edge_id = 0; edge_id < m; ++edge_id) {
            const size_t left = edges[edge_id].u;
            const size_t right = edges[edge_id].v;
            if (left == right) continue;
            size_t neighbor;
            if (current == left) neighbor = right;
            else if (current == right) neighbor = left;
            else continue;
            const int64_t candidate = distance[current] + 2 * edges[edge_id].weight;
            if (!settled[neighbor] && candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent_edge[neighbor] = (int64_t)edge_id;
            }
        }
    }
}

static int64_t mdst_tree_diameter(size_t n, size_t m, const mdst_edge edges[MDST_MAX_M],
    const size_t selected[MDST_MAX_N]) {
    uint8_t adjacent[MDST_MAX_N][MDST_MAX_N] = {{0}};
    int64_t weight[MDST_MAX_N][MDST_MAX_N] = {{0}};
    for (size_t index = 0; index + 1 < n; ++index) {
        const mdst_edge edge = edges[selected[index]];
        adjacent[edge.u][edge.v] = adjacent[edge.v][edge.u] = 1;
        weight[edge.u][edge.v] = weight[edge.v][edge.u] = edge.weight;
    }
    (void)m;
    int64_t diameter = 0;
    for (size_t source = 0; source < n; ++source) {
        int64_t distance[MDST_MAX_N];
        size_t parent[MDST_MAX_N], stack[MDST_MAX_N];
        for (size_t vertex = 0; vertex < n; ++vertex) {
            distance[vertex] = -1;
            parent[vertex] = n;
        }
        size_t top = 1;
        stack[0] = source;
        distance[source] = 0;
        while (top > 0) {
            const size_t current = stack[--top];
            if (distance[current] > diameter) diameter = distance[current];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[current][neighbor] && parent[current] != neighbor &&
                    distance[neighbor] < 0) {
                    parent[neighbor] = current;
                    distance[neighbor] = distance[current] + weight[current][neighbor];
                    stack[top++] = neighbor;
                }
            }
        }
    }
    return diameter;
}

static void mdst_store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_diameter_spanning_tree(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MDST_MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MDST_MAX_N || m_value < 0 || m_value > MDST_MAX_M) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 3 * m) return -1;

    mdst_edge edges[MDST_MAX_M];
    int64_t graph_distance[MDST_MAX_N][MDST_MAX_N];
    for (size_t left = 0; left < n; ++left) {
        for (size_t right = 0; right < n; ++right)
            graph_distance[left][right] = left == right ? 0 : MDST_INF;
    }
    for (size_t edge_id = 0; edge_id < m; ++edge_id) {
        const size_t offset = 2 + 3 * edge_id;
        const int64_t u_value = input[offset], v_value = input[offset + 1];
        const int64_t edge_weight = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            edge_weight < 0 || edge_weight > 9) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        edges[edge_id] = (mdst_edge){u, v, edge_weight};
        if (u != v && edge_weight < graph_distance[u][v])
            graph_distance[u][v] = graph_distance[v][u] = edge_weight;
    }
    for (size_t middle = 0; middle < n; ++middle) {
        for (size_t left = 0; left < n; ++left) {
            for (size_t right = 0; right < n; ++right) {
                const int64_t candidate = graph_distance[left][middle] + graph_distance[middle][right];
                if (candidate < graph_distance[left][right]) graph_distance[left][right] = candidate;
            }
        }
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (graph_distance[0][vertex] == MDST_INF) return -1;

    int64_t best_radius2 = MDST_INF;
    int best_kind = 0;
    size_t best_root = 0, best_edge = 0;
    int64_t best_x2 = 0;
    for (size_t root = 0; root < n; ++root) {
        int64_t eccentricity = 0;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (graph_distance[root][vertex] > eccentricity)
                eccentricity = graph_distance[root][vertex];
        const int64_t radius2 = 2 * eccentricity;
        if (radius2 < best_radius2) {
            best_radius2 = radius2;
            best_kind = 0;
            best_root = root;
        }
    }
    for (size_t edge_id = 0; edge_id < m; ++edge_id) {
        size_t u = edges[edge_id].u, v = edges[edge_id].v;
        const int64_t edge_weight = edges[edge_id].weight;
        if (u == v) continue;
        if (u > v) { size_t temporary = u; u = v; v = temporary; }
        for (int64_t x2 = 0; x2 <= 2 * edge_weight; ++x2) {
            int64_t radius2 = 0;
            for (size_t vertex = 0; vertex < n; ++vertex) {
                const int64_t from_u = 2 * graph_distance[u][vertex] + x2;
                const int64_t from_v = 2 * graph_distance[v][vertex] + 2 * edge_weight - x2;
                const int64_t value = from_u < from_v ? from_u : from_v;
                if (value > radius2) radius2 = value;
            }
            if (radius2 < best_radius2) {
                best_radius2 = radius2;
                best_kind = 1;
                best_root = u;
                best_x2 = x2;
                best_edge = edge_id;
            }
        }
    }

    int64_t center_distance[MDST_MAX_N], parent_edge[MDST_MAX_N];
    mdst_shortest_tree(n, m, edges, best_kind, best_root, best_x2, best_edge,
        center_distance, parent_edge);
    size_t selected[MDST_MAX_N];
    size_t selected_count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (parent_edge[vertex] >= 0) selected[selected_count++] = (size_t)parent_edge[vertex];
    if (selected_count + 2 == n && best_kind == 1) {
        size_t u = edges[best_edge].u, v = edges[best_edge].v;
        if (parent_edge[u] == -1 && parent_edge[v] == -1) selected[selected_count++] = best_edge;
    }
    if (selected_count != n - 1) return -1;
    for (size_t i = 0; i < selected_count; ++i) {
        for (size_t j = i + 1; j < selected_count; ++j) {
            if (selected[j] < selected[i]) {
                const size_t temporary = selected[i];
                selected[i] = selected[j];
                selected[j] = temporary;
            }
        }
    }

    int64_t staged[MDST_MAX_N];
    staged[0] = mdst_tree_diameter(n, m, edges, selected);
    for (size_t index = 0; index < selected_count; ++index)
        staged[index + 1] = (int64_t)selected[index];
    const size_t required = 8 * n;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < n; ++index)
        mdst_store_i64_le(output, 8 * index, staged[index]);
    return (int64_t)required;
}
