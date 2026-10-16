#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_DIRECTED_EDGES (2 * (MAX_NODES - 1))
#define INVALID_PARENT (-2)

static int find_set(int parent[MAX_NODES], int node)
{
    while (parent[node] != node) node = parent[node];
    return node;
}

int64_t centroid_decomposition(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > 2 * MAX_NODES - 1) return -1;
    const int64_t node_count_value = input[0];
    if (node_count_value < 1 || node_count_value > MAX_NODES) return -1;
    const int node_count = (int)node_count_value;
    if (length != (size_t)(2 * node_count - 1)) return -1;

    int set_parent[MAX_NODES];
    int head[MAX_NODES];
    int edge_to[MAX_DIRECTED_EDGES];
    int edge_next[MAX_DIRECTED_EDGES];
    int edge_count = 0;
    for (int node = 0; node < node_count; ++node) {
        set_parent[node] = node;
        head[node] = -1;
    }

    for (size_t position = 1; position < length; position += 2) {
        const int64_t left_value = input[position];
        const int64_t right_value = input[position + 1];
        if (left_value < 0 || left_value >= node_count || right_value < 0
            || right_value >= node_count || left_value == right_value) return -1;
        const int left = (int)left_value;
        const int right = (int)right_value;
        const int left_root = find_set(set_parent, left);
        const int right_root = find_set(set_parent, right);
        if (left_root == right_root) return -1;
        set_parent[right_root] = left_root;

        edge_to[edge_count] = right;
        edge_next[edge_count] = head[left];
        head[left] = edge_count++;
        edge_to[edge_count] = left;
        edge_next[edge_count] = head[right];
        head[right] = edge_count++;
    }

    const size_t required_bytes = (size_t)node_count * 4;
    if (output_capacity < required_bytes || output == NULL) return -2;

    int removed[MAX_NODES] = {0};
    int traversal_parent[MAX_NODES];
    int subtree_size[MAX_NODES];
    int order[MAX_NODES];
    int stack[MAX_NODES];
    int task_node[MAX_NODES];
    int task_parent[MAX_NODES];
    int decomposition_parent[MAX_NODES];
    int task_count = 1;
    task_node[0] = 0;
    task_parent[0] = -1;

    while (task_count > 0) {
        --task_count;
        const int start = task_node[task_count];
        const int centroid_parent = task_parent[task_count];
        for (int node = 0; node < node_count; ++node) traversal_parent[node] = INVALID_PARENT;

        int stack_count = 1;
        int order_count = 0;
        stack[0] = start;
        traversal_parent[start] = -1;
        while (stack_count > 0) {
            const int node = stack[--stack_count];
            order[order_count++] = node;
            subtree_size[node] = 1;
            for (int edge = head[node]; edge >= 0; edge = edge_next[edge]) {
                const int neighbor = edge_to[edge];
                if (neighbor == traversal_parent[node] || removed[neighbor]
                    || traversal_parent[neighbor] != INVALID_PARENT) continue;
                traversal_parent[neighbor] = node;
                stack[stack_count++] = neighbor;
            }
        }

        for (int index = order_count - 1; index >= 0; --index) {
            const int node = order[index];
            const int parent = traversal_parent[node];
            if (parent >= 0) subtree_size[parent] += subtree_size[node];
        }

        int centroid = -1;
        int smallest_largest_branch = node_count + 1;
        for (int index = 0; index < order_count; ++index) {
            const int node = order[index];
            int largest_branch = order_count - subtree_size[node];
            for (int edge = head[node]; edge >= 0; edge = edge_next[edge]) {
                const int neighbor = edge_to[edge];
                if (traversal_parent[neighbor] == node
                    && subtree_size[neighbor] > largest_branch) {
                    largest_branch = subtree_size[neighbor];
                }
            }
            if (largest_branch < smallest_largest_branch
                || (largest_branch == smallest_largest_branch && node < centroid)) {
                centroid = node;
                smallest_largest_branch = largest_branch;
            }
        }

        decomposition_parent[centroid] = centroid_parent;
        removed[centroid] = 1;
        for (int edge = head[centroid]; edge >= 0; edge = edge_next[edge]) {
            const int neighbor = edge_to[edge];
            if (!removed[neighbor]) {
                task_node[task_count] = neighbor;
                task_parent[task_count] = centroid;
                ++task_count;
            }
        }
    }

    for (int node = 0; node < node_count; ++node) {
        const uint32_t bits = (uint32_t)decomposition_parent[node];
        output[4 * node] = (uint8_t)bits;
        output[4 * node + 1] = (uint8_t)(bits >> 8);
        output[4 * node + 2] = (uint8_t)(bits >> 16);
        output[4 * node + 3] = (uint8_t)(bits >> 24);
    }
    return node_count;
}
