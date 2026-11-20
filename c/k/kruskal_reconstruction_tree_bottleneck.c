#include <stddef.h>
#include <stdint.h>

enum { KRT_MAX_N = 8, KRT_MAX_M = 16, KRT_MAX_Q = 8, KRT_MAX_TREE = 15,
       KRT_LEVELS = 4, KRT_MAX_INPUT = 67 };

static size_t krt_find(size_t parent[KRT_MAX_N], size_t vertex)
{
    size_t root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        const size_t next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

static size_t krt_lca(size_t source, size_t destination,
                      const size_t depth[KRT_MAX_TREE],
                      const size_t ancestor[KRT_LEVELS][KRT_MAX_TREE])
{
    if (depth[source] < depth[destination]) {
        const size_t temporary = source;
        source = destination;
        destination = temporary;
    }
    size_t difference = depth[source] - depth[destination];
    size_t bit = 0;
    while (difference != 0) {
        if (difference & 1) source = ancestor[bit][source];
        difference >>= 1;
        ++bit;
    }
    if (source == destination) return source;
    for (size_t level = KRT_LEVELS; level > 0; --level) {
        const size_t index = level - 1;
        if (ancestor[index][source] != ancestor[index][destination]) {
            source = ancestor[index][source];
            destination = ancestor[index][destination];
        }
    }
    return ancestor[0][source];
}

int64_t kruskal_reconstruction_tree_bottleneck(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > KRT_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t m_value = input[1];
    const int64_t q_value = input[2];
    if (n_value < 1 || n_value > KRT_MAX_N || m_value < 0 || m_value > KRT_MAX_M
        || q_value < 1 || q_value > KRT_MAX_Q) return -1;
    const size_t n = (size_t)n_value;
    const size_t m = (size_t)m_value;
    const size_t q = (size_t)q_value;
    if (length != 3 + 3 * m + 2 * q) return -1;

    size_t edge_u[KRT_MAX_M] = {0};
    size_t edge_v[KRT_MAX_M] = {0};
    int64_t edge_weight[KRT_MAX_M] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = input[3 + 3 * edge];
        const int64_t v = input[4 + 3 * edge];
        const int64_t weight = input[5 + 3 * edge];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value
            || weight < 0 || weight > INT64_C(1000000)) return -1;
        edge_u[edge] = (size_t)u;
        edge_v[edge] = (size_t)v;
        edge_weight[edge] = weight;
    }
    const size_t query_start = 3 + 3 * m;
    for (size_t query = 0; query < q; ++query) {
        const int64_t source = input[query_start + 2 * query];
        const int64_t destination = input[query_start + 2 * query + 1];
        if (source < 0 || source >= n_value || destination < 0 || destination >= n_value)
            return -1;
    }

    for (size_t i = 1; i < m; ++i) {
        const size_t u = edge_u[i], v = edge_v[i];
        const int64_t weight = edge_weight[i];
        size_t position = i;
        while (position > 0 && edge_weight[position - 1] > weight) {
            edge_u[position] = edge_u[position - 1];
            edge_v[position] = edge_v[position - 1];
            edge_weight[position] = edge_weight[position - 1];
            --position;
        }
        edge_u[position] = u;
        edge_v[position] = v;
        edge_weight[position] = weight;
    }

    size_t dsu_parent[KRT_MAX_N] = {0};
    size_t dsu_size[KRT_MAX_N] = {0};
    int component_tree[KRT_MAX_N] = {0};
    int tree_parent[KRT_MAX_TREE];
    int tree_left[KRT_MAX_TREE];
    int tree_right[KRT_MAX_TREE];
    int64_t tree_weight[KRT_MAX_TREE] = {0};
    for (size_t node = 0; node < KRT_MAX_TREE; ++node) {
        tree_parent[node] = -1;
        tree_left[node] = -1;
        tree_right[node] = -1;
    }
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
        component_tree[vertex] = (int)vertex;
    }

    size_t next_tree_node = n;
    for (size_t edge = 0; edge < m; ++edge) {
        size_t root_u = krt_find(dsu_parent, edge_u[edge]);
        size_t root_v = krt_find(dsu_parent, edge_v[edge]);
        if (root_u == root_v) continue;

        const int left = component_tree[root_u];
        const int right = component_tree[root_v];
        const size_t merge_node = next_tree_node++;
        tree_left[merge_node] = left;
        tree_right[merge_node] = right;
        tree_weight[merge_node] = edge_weight[edge];
        tree_parent[left] = (int)merge_node;
        tree_parent[right] = (int)merge_node;

        if (dsu_size[root_u] < dsu_size[root_v]) {
            const size_t temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        component_tree[root_u] = (int)merge_node;
    }

    size_t depth[KRT_MAX_TREE] = {0};
    size_t ancestor[KRT_LEVELS][KRT_MAX_TREE] = {{0}};
    for (size_t node = next_tree_node; node > 0; --node) {
        const size_t current = node - 1;
        if (tree_parent[current] < 0) {
            ancestor[0][current] = current;
        } else {
            const size_t parent = (size_t)tree_parent[current];
            ancestor[0][current] = parent;
            depth[current] = depth[parent] + 1;
        }
    }
    for (size_t level = 1; level < KRT_LEVELS; ++level)
        for (size_t node = 0; node < next_tree_node; ++node)
            ancestor[level][node] = ancestor[level - 1][ancestor[level - 1][node]];

    int64_t checksum = 0;
    for (size_t query = 0; query < q; ++query) {
        const size_t source = (size_t)input[query_start + 2 * query];
        const size_t destination = (size_t)input[query_start + 2 * query + 1];
        int64_t answer;
        if (source == destination) {
            answer = 0;
        } else if (krt_find(dsu_parent, source) != krt_find(dsu_parent, destination)) {
            answer = -1;
        } else {
            const size_t lca_node = krt_lca(source, destination, depth, ancestor);
            answer = tree_weight[lca_node];
        }
        checksum += (int64_t)(query + 1) * (answer + 2);
    }
    return checksum;
}
