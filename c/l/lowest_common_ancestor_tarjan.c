#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 256
#define MAX_EDGE_COUNT (MAX_NODE_COUNT - 1)
#define MAX_QUERY_COUNT 1024
#define MAX_ADJACENCY_COUNT (2 * MAX_EDGE_COUNT)
#define MAX_QUERY_ADJACENCY_COUNT (2 * MAX_QUERY_COUNT)

static size_t dsu_find(size_t parent[MAX_NODE_COUNT], size_t node)
{
    size_t root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const size_t next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

static void dsu_union(size_t parent[MAX_NODE_COUNT], uint8_t rank[MAX_NODE_COUNT],
                      size_t left, size_t right)
{
    size_t left_root = dsu_find(parent, left);
    size_t right_root = dsu_find(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) parent[left_root] = right_root;
    else if (rank[left_root] > rank[right_root]) parent[right_root] = left_root;
    else { parent[right_root] = left_root; ++rank[left_root]; }
}

int64_t lowest_common_ancestor_tarjan(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 4 || input[0] < 1 || input[0] > MAX_NODE_COUNT)
        return -1;
    const size_t node_count = (size_t)input[0];
    if (input[1] < 0 || input[1] >= (int64_t)node_count ||
        input[2] < 0 || input[2] != (int64_t)(node_count - 1) ||
        input[3] < 0 || input[3] > MAX_QUERY_COUNT)
        return -1;
    const size_t root = (size_t)input[1];
    const size_t edge_count = (size_t)input[2];
    const size_t query_count = (size_t)input[3];
    if (length != 4 + 2 * edge_count + 2 * query_count) return -1;

    size_t validation_parent[MAX_NODE_COUNT], graph_parent[MAX_NODE_COUNT];
    size_t ancestor[MAX_NODE_COUNT];
    uint8_t validation_rank[MAX_NODE_COUNT] = {0}, graph_rank[MAX_NODE_COUNT] = {0};
    int64_t edge_head[MAX_NODE_COUNT], edge_to[MAX_ADJACENCY_COUNT], edge_next[MAX_ADJACENCY_COUNT];
    int64_t query_head[MAX_NODE_COUNT], query_to[MAX_QUERY_ADJACENCY_COUNT];
    int64_t query_next[MAX_QUERY_ADJACENCY_COUNT], query_id[MAX_QUERY_ADJACENCY_COUNT];
    int64_t answers[MAX_QUERY_COUNT];
    bool visited[MAX_NODE_COUNT] = {false}, finished[MAX_NODE_COUNT] = {false};
    int64_t tree_parent[MAX_NODE_COUNT], cursor[MAX_NODE_COUNT];
    size_t stack[MAX_NODE_COUNT];

    for (size_t node = 0; node < node_count; ++node) {
        validation_parent[node] = node;
        graph_parent[node] = node;
        ancestor[node] = node;
        edge_head[node] = -1;
        query_head[node] = -1;
        tree_parent[node] = -1;
    }
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_arg = input[4 + 2 * edge];
        const int64_t right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (int64_t)node_count ||
            right_arg >= (int64_t)node_count || left_arg == right_arg)
            return -1;
        const size_t left = (size_t)left_arg, right = (size_t)right_arg;
        if (dsu_find(validation_parent, left) == dsu_find(validation_parent, right)) return -1;
        dsu_union(validation_parent, validation_rank, left, right);
        const size_t forward = 2 * edge, reverse = forward + 1;
        edge_to[forward] = (int64_t)right;
        edge_next[forward] = edge_head[left];
        edge_head[left] = (int64_t)forward;
        edge_to[reverse] = (int64_t)left;
        edge_next[reverse] = edge_head[right];
        edge_head[right] = (int64_t)reverse;
    }
    for (size_t node = 0; node < node_count; ++node)
        if (dsu_find(validation_parent, node) != dsu_find(validation_parent, root)) return -1;

    for (size_t query = 0; query < query_count; ++query) {
        const int64_t left_arg = input[4 + 2 * edge_count + 2 * query];
        const int64_t right_arg = input[5 + 2 * edge_count + 2 * query];
        if (left_arg < 0 || right_arg < 0 || left_arg >= (int64_t)node_count ||
            right_arg >= (int64_t)node_count)
            return -1;
        const size_t left = (size_t)left_arg, right = (size_t)right_arg;
        const size_t first = 2 * query, second = first + 1;
        query_to[first] = (int64_t)right;
        query_id[first] = (int64_t)query;
        query_next[first] = query_head[left];
        query_head[left] = (int64_t)first;
        query_to[second] = (int64_t)left;
        query_id[second] = (int64_t)query;
        query_next[second] = query_head[right];
        query_head[right] = (int64_t)second;
    }
    if (query_count > output_capacity || (query_count != 0 && output == NULL)) return -2;

    size_t top = 0;
    stack[top++] = root;
    visited[root] = true;
    cursor[root] = edge_head[root];
    while (top != 0) {
        const size_t node = stack[top - 1];
        const int64_t edge = cursor[node];
        if (edge >= 0) {
            cursor[node] = edge_next[(size_t)edge];
            const size_t child = (size_t)edge_to[(size_t)edge];
            if ((int64_t)child == tree_parent[node]) continue;
            if (visited[child]) return -1;
            visited[child] = true;
            tree_parent[child] = (int64_t)node;
            cursor[child] = edge_head[child];
            stack[top++] = child;
            continue;
        }

        finished[node] = true;
        for (int64_t item = query_head[node]; item >= 0; item = query_next[(size_t)item]) {
            const size_t other = (size_t)query_to[(size_t)item];
            if (finished[other])
                answers[(size_t)query_id[(size_t)item]] =
                    (int64_t)ancestor[dsu_find(graph_parent, other)];
        }
        --top;
        if (tree_parent[node] >= 0) {
            const size_t parent = (size_t)tree_parent[node];
            dsu_union(graph_parent, graph_rank, parent, node);
            ancestor[dsu_find(graph_parent, parent)] = parent;
        }
    }
    for (size_t query = 0; query < query_count; ++query) output[query] = (uint8_t)answers[query];
    return (int64_t)query_count;
}
