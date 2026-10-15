/* Count coin transfers in a valid indexed binary tree. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_NODE_COUNT 100

static int64_t absolute_i64(int64_t value)
{
    return value < 0 ? -value : value;
}

/* A null subtree has excess one; a node combines its two child excesses. */
static int64_t analyze(const int64_t *nodes, int64_t node, int64_t *moves)
{
    if (node == -1) return 1;
    const size_t index = (size_t)node;
    const int64_t left = nodes[3 * index + 1];
    const int64_t right = nodes[3 * index + 2];
    const int64_t left_excess = analyze(nodes, left, moves);
    const int64_t right_excess = analyze(nodes, right, moves);
    *moves += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess);
    return nodes[3 * index] + left_excess + right_excess - 2;
}

int64_t distribute_coins(const int64_t *nodes, size_t node_count, int64_t root_index)
{
    if (node_count > MAX_NODE_COUNT) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;

    int64_t parent[MAX_NODE_COUNT];
    size_t stack[MAX_NODE_COUNT];
    uint8_t seen[MAX_NODE_COUNT] = {0};
    for (size_t node = 0; node < node_count; ++node) parent[node] = -1;

    int64_t coin_total = 0;
    for (size_t node = 0; node < node_count; ++node) {
        const int64_t value = nodes[3 * node];
        if (value < 0 || value > 100) return -1;
        coin_total += value;
        for (size_t edge = 1; edge <= 2; ++edge) {
            const int64_t child = nodes[3 * node + edge];
            if (child < -1 || (child >= 0 && (uint64_t)child >= node_count)) return -1;
            if (child >= 0) {
                const size_t child_index = (size_t)child;
                if (parent[child_index] != -1) return -1;
                parent[child_index] = (int64_t)node;
            }
        }
    }
    if (coin_total != (int64_t)node_count) return -1;
    const size_t root = (size_t)root_index;
    if (parent[root] != -1) return -1;
    for (size_t node = 0; node < node_count; ++node)
        if (node != root && parent[node] == -1) return -1;

    size_t top = 0, reached = 0;
    stack[top++] = root;
    while (top > 0) {
        const size_t node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = 1;
        ++reached;
        for (size_t edge = 1; edge <= 2; ++edge) {
            const int64_t child = nodes[3 * node + edge];
            if (child >= 0) stack[top++] = (size_t)child;
        }
    }
    if (reached != node_count) return -1;

    int64_t moves = 0;
    (void)analyze(nodes, root_index, &moves);
    return moves;
}
