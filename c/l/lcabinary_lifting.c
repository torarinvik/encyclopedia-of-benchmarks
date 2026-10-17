#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 128u
#define MAX_EDGES (MAX_NODES - 1u)
#define MAX_DIRECTED_EDGES (2u * MAX_EDGES)
#define MAX_QUERIES 256u
#define MAX_LEVELS 7u
#define MAX_PARSEABLE_INPUT_VALUES 771u

static int dsu_find(int *parent, int node)
{
    int root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const int next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

static int lca_query(int left, int right, const int *depth, const int *up, size_t levels)
{
    if (depth[left] < depth[right]) {
        const int temporary = left;
        left = right;
        right = temporary;
    }

    const unsigned difference = (unsigned)(depth[left] - depth[right]);
    for (size_t level = 0u; level < levels; ++level) {
        if ((difference & (1u << level)) != 0u)
            left = up[(size_t)left * MAX_LEVELS + level];
    }
    if (left == right) return left;

    for (size_t level = levels; level > 0u; --level) {
        const size_t column = level - 1u;
        const int left_ancestor = up[(size_t)left * MAX_LEVELS + column];
        const int right_ancestor = up[(size_t)right * MAX_LEVELS + column];
        if (left_ancestor != right_ancestor) {
            left = left_ancestor;
            right = right_ancestor;
        }
    }
    return up[(size_t)left * MAX_LEVELS];
}

int64_t lca_binary_lifting_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 2 || input[0] > (int64_t)MAX_NODES) return -1;
    const size_t node_count = (size_t)input[0];
    if (input[1] < 0 || input[1] >= (int64_t)node_count) return -1;
    const int root = (int)input[1];
    if (input[2] != (int64_t)(node_count - 1u)) return -1;
    const size_t edge_count = node_count - 1u;
    size_t cursor = 3u;
    if (cursor + 2u * edge_count + 1u > length) return -1;

    int parent[MAX_NODES];
    int ranks[MAX_NODES] = {0};
    int head[MAX_NODES];
    for (size_t node = 0u; node < node_count; ++node) {
        parent[node] = (int)node;
        head[node] = -1;
    }
    int to[MAX_DIRECTED_EDGES];
    int next[MAX_DIRECTED_EDGES];
    size_t directed_edge_count = 0u;
    for (size_t edge = 0u; edge < edge_count; ++edge) {
        const int64_t left_value = input[cursor++];
        const int64_t right_value = input[cursor++];
        if (left_value < 0 || left_value >= (int64_t)node_count ||
            right_value < 0 || right_value >= (int64_t)node_count || left_value == right_value)
            return -1;
        const int left = (int)left_value;
        const int right = (int)right_value;
        int left_root = dsu_find(parent, left);
        int right_root = dsu_find(parent, right);
        if (left_root == right_root) return -1;
        if (ranks[left_root] < ranks[right_root]) parent[left_root] = right_root;
        else if (ranks[left_root] > ranks[right_root]) parent[right_root] = left_root;
        else { parent[right_root] = left_root; ++ranks[left_root]; }

        to[directed_edge_count] = right;
        next[directed_edge_count] = head[left];
        head[left] = (int)directed_edge_count++;
        to[directed_edge_count] = left;
        next[directed_edge_count] = head[right];
        head[right] = (int)directed_edge_count++;
    }

    const int component = dsu_find(parent, 0);
    for (size_t node = 1u; node < node_count; ++node)
        if (dsu_find(parent, (int)node) != component) return -1;

    const int64_t query_count_value = input[cursor++];
    if (query_count_value < 0 || query_count_value > (int64_t)MAX_QUERIES) return -1;
    const size_t query_count = (size_t)query_count_value;
    if (cursor + 2u * query_count != length) return -1;

    int depth[MAX_NODES];
    int ancestors[MAX_NODES];
    int queue[MAX_NODES];
    for (size_t node = 0u; node < node_count; ++node) {
        depth[node] = -1;
        ancestors[node] = -1;
    }
    depth[root] = 0;
    ancestors[root] = root;
    size_t queue_head = 0u;
    size_t queue_tail = 0u;
    queue[queue_tail++] = root;
    while (queue_head < queue_tail) {
        const int node = queue[queue_head++];
        for (int edge = head[node]; edge >= 0; edge = next[edge]) {
            const int child = to[edge];
            if (child == ancestors[node]) continue;
            if (ancestors[child] >= 0) return -1;
            ancestors[child] = node;
            depth[child] = depth[node] + 1;
            queue[queue_tail++] = child;
        }
    }
    if (queue_tail != node_count) return -1;

    size_t levels = 0u;
    while ((1u << levels) < node_count) ++levels;
    int up[MAX_NODES * MAX_LEVELS] = {0};
    for (size_t node = 0u; node < node_count; ++node)
        up[node * MAX_LEVELS] = ancestors[node];
    for (size_t level = 1u; level < levels; ++level) {
        for (size_t node = 0u; node < node_count; ++node) {
            const int previous = up[node * MAX_LEVELS + level - 1u];
            up[node * MAX_LEVELS + level] = up[(size_t)previous * MAX_LEVELS + level - 1u];
        }
    }

    int64_t checksum = 0;
    for (size_t query = 0u; query < query_count; ++query) {
        const int64_t left_value = input[cursor++];
        const int64_t right_value = input[cursor++];
        if (left_value < 0 || left_value >= (int64_t)node_count ||
            right_value < 0 || right_value >= (int64_t)node_count) return -1;
        const int ancestor = lca_query((int)left_value, (int)right_value, depth, up, levels);
        checksum += (int64_t)(query + 1u) * ((int64_t)ancestor + 1);
    }
    return checksum;
}
