/* Count target-sum downward paths, restarting at each node as in the source. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 63

static int64_t count_from(const int64_t *input, size_t node, int64_t sum, int64_t target)
{
    const size_t base = 2 + 3 * node;
    int64_t count = sum == target ? 1 : 0;
    const int64_t left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += count_from(input, (size_t)left, sum + input[2 + 3 * (size_t)left], target);
    if (right >= 0) count += count_from(input, (size_t)right, sum + input[2 + 3 * (size_t)right], target);
    return count;
}

static int64_t start_at_each_node(const int64_t *input, size_t node)
{
    const size_t base = 2 + 3 * node;
    int64_t count = count_from(input, node, input[base], input[0]);
    const int64_t left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += start_at_each_node(input, (size_t)left);
    if (right >= 0) count += start_at_each_node(input, (size_t)right);
    return count;
}

int64_t binary_tree_path_sum(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[1] < 0 || input[1] > MAX_NODES) return -1;
    const size_t count = (size_t)input[1];
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    size_t parents[MAX_NODES] = {0};
    for (size_t node = 0; node < count; ++node) {
        const size_t base = 2 + 3 * node;
        if (input[base] < INT32_MIN || input[base] > INT32_MAX) return -1;
        for (size_t side = 1; side <= 2; ++side) {
            const int64_t child = input[base + side];
            if (child < -1 || child >= (int64_t)count) return -1;
            if (child >= 0 && ++parents[(size_t)child] > 1) return -1;
        }
    }
    if (parents[0] != 0) return -1;
    for (size_t node = 1; node < count; ++node) if (parents[node] != 1) return -1;
    bool seen[MAX_NODES] = {false};
    size_t stack[MAX_NODES], top = 0, reached = 0;
    stack[top++] = 0;
    while (top > 0) {
        const size_t node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true; ++reached;
        const size_t base = 2 + 3 * node;
        if (input[base + 1] >= 0) stack[top++] = (size_t)input[base + 1];
        if (input[base + 2] >= 0) stack[top++] = (size_t)input[base + 2];
    }
    if (reached != count) return -1;
    return start_at_each_node(input, 0);
}
