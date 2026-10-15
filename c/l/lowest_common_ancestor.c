#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 1023
#define VALUE_MIN INT64_C(-1000000000)
#define VALUE_MAX INT64_C(1000000000)
#define INVALID_RESULT INT64_C(-1)

int64_t lowest_common_ancestor(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || input[0] < 2 || input[0] > MAX_NODE_COUNT)
        return INVALID_RESULT;
    const size_t count = (size_t)input[0];
    if (length != 4 + 3 * count) return INVALID_RESULT;
    const int64_t root_arg = input[1], p_arg = input[2], q_arg = input[3];
    if (root_arg < 0 || (uint64_t)root_arg >= count || p_arg < 0 || (uint64_t)p_arg >= count ||
        q_arg < 0 || (uint64_t)q_arg >= count || p_arg == q_arg) return INVALID_RESULT;
    const size_t root = (size_t)root_arg, p = (size_t)p_arg, q = (size_t)q_arg;

    int64_t parent[MAX_NODE_COUNT];
    size_t stack[MAX_NODE_COUNT], path_p[MAX_NODE_COUNT], path_q[MAX_NODE_COUNT];
    uint8_t seen[MAX_NODE_COUNT] = {0};
    for (size_t index = 0; index < count; ++index) parent[index] = -1;
    for (size_t node = 0; node < count; ++node) {
        const size_t offset = 4 + 3 * node;
        if (input[offset] < VALUE_MIN || input[offset] > VALUE_MAX) return INVALID_RESULT;
        for (size_t edge = 1; edge <= 2; ++edge) {
            const int64_t child = input[offset + edge];
            if (child < -1 || (child >= 0 && (uint64_t)child >= count)) return INVALID_RESULT;
            if (child >= 0) {
                const size_t child_index = (size_t)child;
                if (parent[child_index] != -1) return INVALID_RESULT;
                parent[child_index] = (int64_t)node;
            }
        }
    }
    if (parent[root] != -1) return INVALID_RESULT;
    for (size_t node = 0; node < count; ++node)
        if (node != root && parent[node] == -1) return INVALID_RESULT;

    size_t top = 0, reached = 0;
    stack[top++] = root;
    while (top != 0) {
        const size_t node = stack[--top];
        if (seen[node]) return INVALID_RESULT;
        seen[node] = 1;
        ++reached;
        const size_t offset = 4 + 3 * node;
        for (size_t edge = 1; edge <= 2; ++edge) {
            const int64_t child = input[offset + edge];
            if (child >= 0) stack[top++] = (size_t)child;
        }
    }
    if (reached != count) return INVALID_RESULT;

    size_t depth_p = 0, depth_q = 0;
    size_t current = p;
    while (1) {
        path_p[depth_p++] = current;
        if (current == root) break;
        current = (size_t)parent[current];
    }
    current = q;
    while (1) {
        path_q[depth_q++] = current;
        if (current == root) break;
        current = (size_t)parent[current];
    }
    int64_t ancestor = INVALID_RESULT;
    while (depth_p != 0 && depth_q != 0 && path_p[depth_p - 1] == path_q[depth_q - 1]) {
        ancestor = (int64_t)path_p[depth_p - 1];
        --depth_p;
        --depth_q;
    }
    return ancestor;
}
