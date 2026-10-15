/* Check whether a root-to-leaf path has the requested sum. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 63

static bool path_has_sum(const int64_t *input, size_t node, int64_t sum, int64_t target)
{
    const size_t base = 2 + 3 * node;
    sum += input[base];
    const int64_t left = input[base + 1], right = input[base + 2];
    if (left == -1 && right == -1) return sum == target;
    return (left != -1 && path_has_sum(input, (size_t)left, sum, target)) ||
           (right != -1 && path_has_sum(input, (size_t)right, sum, target));
}

int64_t path_sum(const int64_t *input, size_t length)
{
    if (length < 2 || input[1] < 0 || input[1] > MAX_NODES) return -1;
    const size_t count = (size_t)input[1];
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    for (size_t index = 0; index < count; ++index) {
        const size_t base = 2 + 3 * index;
        if (input[base] < INT32_MIN || input[base] > INT32_MAX) return -1;
        for (size_t edge = 1; edge <= 2; ++edge)
            if (input[base + edge] < -1 || input[base + edge] >= (int64_t)count) return -1;
    }
    bool seen[MAX_NODES] = {false};
    size_t stack[MAX_NODES], top = 0, visited = 0;
    stack[top++] = 0;
    while (top > 0) {
        const size_t node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true;
        ++visited;
        const size_t base = 2 + 3 * node;
        const int64_t left = input[base + 1], right = input[base + 2];
        if (left != -1) stack[top++] = (size_t)left;
        if (right != -1) stack[top++] = (size_t)right;
    }
    if (visited != count) return -1;
    return path_has_sum(input, 0, 0, input[0]) ? 1 : 0;
}
