#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 20
#define OUTPUT_BYTES 32

static int find_root(int parent[MAX_N], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t second_best_mst(const int64_t *input, size_t length,
                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 2 + 3 * MAX_M) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_N || m_value < n_value - 1 || m_value > MAX_M)
        return -1;
    const int n = (int)n_value, m = (int)m_value;
    if (length != (size_t)(2 + 3 * m)) return -1;

    int edge_u[MAX_M], edge_v[MAX_M], edge_weight[MAX_M], order[MAX_M];
    uint8_t seen[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u = input[2 + 3 * edge];
        const int64_t v = input[3 + 3 * edge];
        const int64_t weight = input[4 + 3 * edge];
        if (u < 0 || u >= v || v >= n || weight < 0 || weight > 1000000)
            return -1;
        if (seen[u][v]) return -1;
        seen[u][v] = 1;
        edge_u[edge] = (int)u;
        edge_v[edge] = (int)v;
        edge_weight[edge] = (int)weight;
        order[edge] = edge;
    }

    for (int i = 1; i < m; ++i) {
        const int edge = order[i];
        int j = i;
        while (j > 0 && (edge_weight[order[j - 1]] > edge_weight[edge]
                || (edge_weight[order[j - 1]] == edge_weight[edge] && order[j - 1] > edge))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = edge;
    }

    int dsu[MAX_N], size[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) { dsu[vertex] = vertex; size[vertex] = 1; }
    uint8_t in_mst[MAX_M] = {0};
    int tree_to[MAX_N][MAX_N], tree_edge[MAX_N][MAX_N], degree[MAX_N] = {0};
    int selected = 0;
    int64_t mst_weight = 0;
    for (int position = 0; position < m; ++position) {
        const int edge = order[position];
        int root_u = find_root(dsu, edge_u[edge]);
        int root_v = find_root(dsu, edge_v[edge]);
        if (root_u == root_v) continue;
        if (size[root_u] < size[root_v]) { const int temp = root_u; root_u = root_v; root_v = temp; }
        dsu[root_v] = root_u;
        size[root_u] += size[root_v];
        in_mst[edge] = 1;
        ++selected;
        mst_weight += edge_weight[edge];
        tree_to[edge_u[edge]][degree[edge_u[edge]]] = edge_v[edge];
        tree_edge[edge_u[edge]][degree[edge_u[edge]]++] = edge;
        tree_to[edge_v[edge]][degree[edge_v[edge]]] = edge_u[edge];
        tree_edge[edge_v[edge]][degree[edge_v[edge]]++] = edge;
    }
    if (selected != n - 1) return -1;

    int64_t second_weight = -1;
    int entering_edge = -1, leaving_edge = -1;
    for (int added = 0; added < m; ++added) {
        if (in_mst[added]) continue;
        int parent[MAX_N], parent_edge[MAX_N], queue[MAX_N];
        for (int vertex = 0; vertex < n; ++vertex) parent[vertex] = -1;
        int head = 0, tail = 0;
        const int start = edge_u[added], target = edge_v[added];
        parent[start] = start;
        queue[tail++] = start;
        while (head < tail && parent[target] == -1) {
            const int vertex = queue[head++];
            for (int i = 0; i < degree[vertex]; ++i) {
                const int next = tree_to[vertex][i];
                if (parent[next] != -1) continue;
                parent[next] = vertex;
                parent_edge[next] = tree_edge[vertex][i];
                queue[tail++] = next;
            }
        }
        int64_t first_weight = -1, second_path_weight = -1;
        int first_edge = -1, second_path_edge = -1;
        for (int vertex = target; vertex != start; vertex = parent[vertex]) {
            const int path_edge = parent_edge[vertex];
            const int64_t weight = edge_weight[path_edge];
            if (weight > first_weight) {
                second_path_weight = first_weight; second_path_edge = first_edge;
                first_weight = weight; first_edge = path_edge;
            } else if (weight == first_weight) {
                if (first_edge < 0 || path_edge < first_edge) first_edge = path_edge;
            } else if (weight > second_path_weight) {
                second_path_weight = weight; second_path_edge = path_edge;
            } else if (weight == second_path_weight
                    && (second_path_edge < 0 || path_edge < second_path_edge)) {
                second_path_edge = path_edge;
            }
        }
        int64_t removed_weight = -1;
        int removed_edge = -1;
        if (edge_weight[added] > first_weight) {
            removed_weight = first_weight; removed_edge = first_edge;
        } else if (edge_weight[added] == first_weight && second_path_weight >= 0) {
            removed_weight = second_path_weight; removed_edge = second_path_edge;
        }
        if (removed_edge < 0) continue;
        const int64_t candidate = mst_weight + edge_weight[added] - removed_weight;
        if (second_weight < 0 || candidate < second_weight
                || (candidate == second_weight && (added < entering_edge
                    || (added == entering_edge && removed_edge < leaving_edge)))) {
            second_weight = candidate;
            entering_edge = added;
            leaving_edge = removed_edge;
        }
    }

    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    store_i64_le(output, 0, mst_weight);
    store_i64_le(output, 8, second_weight);
    store_i64_le(output, 16, entering_edge);
    store_i64_le(output, 24, leaving_edge);
    return OUTPUT_BYTES;
}
